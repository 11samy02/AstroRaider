extends Node
class_name PerkSelection

@export var manager: PerkManager

var perks_list: Array[PerkBuild] = []
var last_selected_perks: Array[PerkBuild] = []
var perks_to_choose_from: Array[PerkBuild] = []

var max_last_selections := 5
var max_choices := 3


## Called by PerkManager on ready
func init(mgr: Node) -> void:
	manager = mgr
	_init_perks_from_children()


## Collect all PerkBuild children from Perks node
func _init_perks_from_children() -> void:
	perks_list.clear()
	for child in manager.perks_node.get_children():
		if child is PerkBuild and child.Level < 6 and not perks_list.has(child):
			perks_list.append(child)


## Build the perk offer and emit show signal
func build_offer() -> void:
	perks_to_choose_from.clear()
	var available: Array[PerkBuild] = _get_available_perks()
	var total_remaining := _count_total_remaining()
	var target = min(max_choices, total_remaining)
	if available.size() < target:
		_top_up_available_from_cooldown(available, target)
	var count = min(target, available.size())
	if count <= 0:
		manager.is_selecting = false
		manager.in_perk_session = false
		manager.get_tree().paused = false
		return
	for i in count:
		var perk: PerkBuild = available.pick_random()
		perks_to_choose_from.append(perk)
		available.erase(perk)
	manager.show_perk_selection_ui.emit(perks_to_choose_from)


## Get available perks filtered by exclusions, ult limit and slot limit
func _get_available_perks() -> Array:
	var excluded_keys: Array[PerkData.Keys] = _get_all_excluded_keys()
	var cleaned: Array[PerkBuild] = []
	for p in perks_list:
		if p.Level >= 6:
			continue
		if excluded_keys.has(p.Key):
			continue
		if p.is_ult() and manager.slots.has_ult:
			continue
		if p.is_activation() and manager.slots.all_slots_filled() and !p.has_unlocked:
			continue
		if not cleaned.has(p):
			cleaned.append(p)
	return cleaned


## Collect all excluded keys from currently unlocked perks
func _get_all_excluded_keys() -> Array[PerkData.Keys]:
	var keys: Array[PerkData.Keys] = []
	for child in manager.perks_node.get_children():
		if child is PerkBuild and child.has_unlocked:
			for k in child.get_excluded_keys():
				if not keys.has(k):
					keys.append(k)
	return keys


## Remove perks that reached max level from the list
func prune_maxed() -> void:
	var to_remove: Array[PerkBuild] = []
	for p in perks_list:
		if p.Level >= 6:
			to_remove.append(p)
	for p in to_remove:
		perks_list.erase(p)


## Push perk into cooldown list
func _cooldown_push(perk: PerkBuild) -> void:
	if perks_list.has(perk):
		perks_list.erase(perk)
	last_selected_perks.push_back(perk)
	if last_selected_perks.size() >= max_last_selections:
		var back: PerkBuild = last_selected_perks[0]
		last_selected_perks.remove_at(0)
		if back.Level < 6 and not perks_list.has(back):
			perks_list.append(back)


## Finalize perk selection — push to cooldown or remove if maxed
func finalize(perk: PerkBuild) -> void:
	perks_to_choose_from.clear()
	if perk.Level >= 6:
		if perks_list.has(perk):
			perks_list.erase(perk)
	else:
		_cooldown_push(perk)


## Emergency release perks from cooldown when perks_list is empty
func emergency_release_from_cooldown() -> void:
	if last_selected_perks.is_empty():
		return
	var released := 0
	while released < max_choices and not last_selected_perks.is_empty():
		var perk: PerkBuild = last_selected_perks[0]
		last_selected_perks.remove_at(0)
		if perk.Level < 6 and not perks_list.has(perk):
			perks_list.append(perk)
			released += 1


## Count all remaining non-maxed perks across active and cooldown lists
func _count_total_remaining() -> int:
	var count := 0
	for p in perks_list:
		if p.Level < 6:
			count += 1
	for p in last_selected_perks:
		if p.Level < 6 and not perks_list.has(p):
			count += 1
	return count


## Top up available list from cooldown if not enough choices
func _top_up_available_from_cooldown(available: Array, target: int) -> void:
	if available.size() >= target:
		return
	var i := 0
	while available.size() < target and i < last_selected_perks.size():
		var perk: PerkBuild = last_selected_perks[i]
		if perk.Level < 6 and not available.has(perk) and not perks_list.has(perk):
			perks_list.append(perk)
			available.append(perk)
			last_selected_perks.remove_at(i)
		else:
			i += 1
