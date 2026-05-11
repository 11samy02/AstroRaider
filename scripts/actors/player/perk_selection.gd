extends Node
class_name PerkSelection

enum SelectorType {
	Standard,
	ActivationOnly,
	UltOnly,
}

@export var manager: PerkManager

var perks_list: Array[PerkBuild] = []
var last_selected_perks: Array[PerkBuild] = []
var perks_to_choose_from: Array[PerkBuild] = []

var max_last_selections := 5
var max_choices := 3

var _cached_unlocked_keys := {}
var _cached_tag_counts := {}
var _cached_excluded_keys: Array[PerkData.Keys] = []


## Initializes the selection system and collects all perk nodes.
func init(mgr: Node) -> void:
	manager = mgr
	_init_perks_from_children()


## Collects all valid PerkBuild children from the manager.
func _init_perks_from_children() -> void:
	perks_list.clear()
	for child in manager.perks_node.get_children():
		if child is PerkBuild:
			var max_level := 3 if child.is_ult() else 6
			if child.Level < max_level and not perks_list.has(child):
				perks_list.append(child)


## Builds a perk offer for the given selector type and emits the UI signal.
func build_offer(selector_type: SelectorType = SelectorType.Standard) -> void:
	perks_to_choose_from.clear()
	_refresh_selection_cache()

	var available: Array[PerkBuild] = _get_available_perks(selector_type)
	var total_remaining := _count_total_remaining()
	var target = min(max_choices, total_remaining)

	if selector_type == SelectorType.ActivationOnly or selector_type == SelectorType.UltOnly:
		target = max_choices

	if available.size() < target:
		_top_up_available_from_cooldown(available, target, selector_type)

	if available.size() < target and selector_type != SelectorType.Standard:
		var fallback_available: Array[PerkBuild] = _get_available_perks(SelectorType.Standard)
		for perk in fallback_available:
			if available.size() >= target:
				break
			if not available.has(perk):
				available.append(perk)

	if available.is_empty():
		emergency_release_from_cooldown()
		_refresh_selection_cache()
		available = _get_available_perks(selector_type)

	if available.is_empty() and selector_type != SelectorType.Standard:
		available = _get_available_perks(SelectorType.Standard)
		
	var count = min(target, available.size())
	
	if count <= 0:
		manager.is_selecting = false
		manager.in_perk_session = false
		manager.get_tree().paused = false
		return

	for i in count:
		if available.is_empty():
			break

		var perk: PerkBuild = _pick_weighted_perk(available)
		if perk == null:
			break

		if not perks_to_choose_from.has(perk):
			perks_to_choose_from.append(perk)

		available.erase(perk)

	if perks_to_choose_from.is_empty():
		manager.is_selecting = false
		manager.in_perk_session = false
		manager.get_tree().paused = false
		return

	manager.show_perk_selection_ui.emit(perks_to_choose_from)


## Builds a standard perk offer.
func build_standard_offer() -> void:
	build_offer(SelectorType.Standard)


## Builds an offer that prioritizes activation perks and falls back to normal perks if needed.
func build_activation_offer() -> void:
	build_offer(SelectorType.ActivationOnly)


## Builds an offer that prioritizes ult perks and falls back to normal perks if needed.
func build_ult_offer() -> void:
	build_offer(SelectorType.UltOnly)


## Refreshes cached data used during perk selection.
func _refresh_selection_cache() -> void:
	_cached_unlocked_keys.clear()
	_cached_tag_counts.clear()
	_cached_excluded_keys.clear()

	for child in manager.perks_node.get_children():
		if not (child is PerkBuild):
			continue

		if not child.selected_in_run :
			continue

		_cached_unlocked_keys[child.Key] = true

		if is_instance_valid(child.perk_res):
			for tag in child.perk_res.tags:
				if not _cached_tag_counts.has(tag):
					_cached_tag_counts[tag] = 0
				_cached_tag_counts[tag] += 1

			for excluded_key in child.perk_res.excluded_perks:
				if not _cached_excluded_keys.has(excluded_key):
					_cached_excluded_keys.append(excluded_key)


## Returns all currently valid perks for the given selector type.
func _get_available_perks(selector_type: SelectorType = SelectorType.Standard) -> Array[PerkBuild]:
	var cleaned: Array[PerkBuild] = []
	
	for p in perks_list:
		if _is_valid_offer_perk(p, selector_type) and not cleaned.has(p):
			cleaned.append(p)
	
	return cleaned

## Returns all excluded perk keys from the current cache.
func _get_all_excluded_keys() -> Array[PerkData.Keys]:
	return _cached_excluded_keys


## Returns true if all required perks for a perk are already unlocked.
func _has_required_perks(perk: PerkBuild) -> bool:
	if not is_instance_valid(perk) or not is_instance_valid(perk.perk_res):
		return false

	var required: Array[PerkData.Keys] = perk.perk_res.required_perks

	if required.is_empty():
		return true

	for key in required:
		if not _has_perk_unlocked(key):
			return false

	return true


## Returns true if the given perk key is already unlocked.
func _has_perk_unlocked(key: PerkData.Keys) -> bool:
	return _cached_unlocked_keys.has(key)


## Returns the cached tag counts of all unlocked perks.
func _get_owned_tag_counts() -> Dictionary:
	return _cached_tag_counts


## Calculates the rarity multiplier based on matching owned tags.
func _get_tag_multiplier(perk: PerkBuild, tag_counts: Dictionary) -> float:
	var multiplier := 1.0

	if not is_instance_valid(perk) or not is_instance_valid(perk.perk_res):
		return multiplier

	for tag in perk.perk_res.tags:
		if tag_counts.has(tag):
			multiplier += tag_counts[tag] * 0.25

	return min(multiplier, 2.0)


## Selects a perk using weighted randomness with tag-based rarity bonuses.
func _pick_weighted_perk(perks: Array[PerkBuild]) -> PerkBuild:
	if perks.is_empty():
		return null

	var valid_perks: Array[PerkBuild] = []
	for p in perks:
		if is_instance_valid(p) and is_instance_valid(p.perk_res):
			valid_perks.append(p)

	if valid_perks.is_empty():
		return null

	var tag_counts := _get_owned_tag_counts()
	var weighted_entries: Array[Dictionary] = []
	var total_rarity := 0.0

	for p in valid_perks:
		var base := p.perk_res.get_rarity(p.Level)
		var mult := _get_tag_multiplier(p, tag_counts)
		var weight = max(0.01, base * mult)

		weighted_entries.append({
			"perk": p,
			"weight": weight
		})
		total_rarity += weight

	if total_rarity <= 0.0:
		return valid_perks.pick_random()

	var random_value := randf() * total_rarity
	var current_sum := 0.0

	for entry in weighted_entries:
		current_sum += entry.weight
		if random_value <= current_sum:
			return entry.perk

	return weighted_entries.back().perk


## Remove perks that reached max level from the list
func prune_maxed() -> void:
	var to_remove: Array[PerkBuild] = []
	for p in perks_list:
		var max_level := 3 if p.is_ult() else 6
		if p.Level >= max_level:
			to_remove.append(p)
	for p in to_remove:
		perks_list.erase(p)


## Pushes a perk into the cooldown history and rotates old entries back in.
func _cooldown_push(perk: PerkBuild) -> void:
	if perks_list.has(perk):
		perks_list.erase(perk)

	last_selected_perks.push_back(perk)

	if last_selected_perks.size() > max_last_selections:
		var back: PerkBuild = last_selected_perks[0]
		last_selected_perks.remove_at(0)

		var max_level := 3 if back.is_ult() else 6
		if is_instance_valid(back) and back.Level < max_level and not perks_list.has(back):
			perks_list.append(back)


## Finalizes the selected perk and updates the cooldown rotation.
func finalize(perk: PerkBuild) -> void:
	perks_to_choose_from.clear()
	var max_level := 3 if perk.is_ult() else 6
	if perk.Level >= max_level:
		if perks_list.has(perk):
			perks_list.erase(perk)
	else:
		_cooldown_push(perk)


## Releases perks from the cooldown list if the active pool runs dry.
func emergency_release_from_cooldown() -> void:
	if last_selected_perks.is_empty():
		return

	var released := 0
	var i := 0
	var safety := 0
	var max_iterations := 50

	while released < max_choices and i < last_selected_perks.size():
		safety += 1
		if safety > max_iterations:
			print("SAFETY BREAK: emergency loop stopped")
			break

		var perk: PerkBuild = last_selected_perks[i]

		if not is_instance_valid(perk) or not is_instance_valid(perk.perk_res):
			last_selected_perks.remove_at(i)
			continue
		
		var max_level := 3 if perk.is_ult() else 6
		if perk.Level < max_level and not perks_list.has(perk):
			perks_list.append(perk)
			last_selected_perks.remove_at(i)
			released += 1
		else:
			i += 1


## Counts all remaining non-maxed perks across active and cooldown pools.
func _count_total_remaining() -> int:
	var count := 0

	for p in perks_list:
		var max_level := 3 if p.is_ult() else 6
		if is_instance_valid(p) and p.Level < max_level:
			count += 1
	for p in last_selected_perks:
		var max_level := 3 if p.is_ult() else 6
		if is_instance_valid(p) and p.Level < max_level and not perks_list.has(p):
			count += 1

	return count


## Tops up the available list from cooldown if there are not enough valid perks.
func _top_up_available_from_cooldown(available: Array[PerkBuild], target: int, selector_type: SelectorType = SelectorType.Standard) -> void:
	if available.size() >= target:
		return

	var i := 0
	var safety := 0
	var max_iterations := 50

	while available.size() < target and i < last_selected_perks.size():
		safety += 1
		if safety > max_iterations:
			print("SAFETY BREAK: top_up loop stopped")
			break

		var perk: PerkBuild = last_selected_perks[i]

		if not is_instance_valid(perk) or not is_instance_valid(perk.perk_res):
			last_selected_perks.remove_at(i)
			continue

		var valid_for_selector := true

		match selector_type:
			SelectorType.ActivationOnly:
				valid_for_selector = perk.is_activation()
			SelectorType.UltOnly:
				valid_for_selector = perk.is_ult()
			SelectorType.Standard:
				valid_for_selector = true

		var max_level := 3 if perk.is_ult() else 6
		if perk.Level < max_level and not available.has(perk) and not perks_list.has(perk):
			if _is_valid_offer_perk(perk, selector_type) and not available.has(perk) and not perks_list.has(perk):
				perks_list.append(perk)
				available.append(perk)
				last_selected_perks.remove_at(i)
			else:
				i += 1
		else:
			i += 1


func _is_valid_offer_perk(perk: PerkBuild, selector_type: SelectorType = SelectorType.Standard) -> bool:
	if not is_instance_valid(perk) or not is_instance_valid(perk.perk_res):
		return false
	
	var max_level := 3 if perk.is_ult() else 6
	if perk.Level >= max_level:
		return false
	
	if _cached_excluded_keys.has(perk.Key):
		return false
	
	if not _has_required_perks(perk):
		return false
	
	match selector_type:
		SelectorType.ActivationOnly:
			if not perk.is_activation():
				return false
		SelectorType.UltOnly:
			if not perk.is_ult():
				return false
		SelectorType.Standard:
			pass
	
	if perk.is_ult() and manager.slots.has_ult:
		return false
	
	if perk.is_activation() and manager.slots.all_slots_filled() and not perk.selected_in_run :
		return false
	
	return true

func has_any_selectable_perks() -> bool:
	_refresh_selection_cache()

	for p in perks_list:
		if _is_valid_offer_perk(p, SelectorType.Standard):
			return true

	for p in last_selected_perks:
		if _is_valid_offer_perk(p, SelectorType.Standard):
			return true

	return false
