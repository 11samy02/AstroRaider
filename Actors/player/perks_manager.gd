extends Node
class_name PerkManager

signal show_perk_selection_ui(perks: Array[PerkBuild])

@export var player: Player
@export var perk_selector: Control
@export var selection: PerkSelection
@export var slots: PerkSlots
@export var perks_node: Node
@export var abilities_ui: Node

var player_res: PlayerResource
var is_selecting := false
var in_perk_session := false
var needed_coins := 10
var current_player_level := 1
var _queued_selections := 0

var _activation_miss_streak := 0
var _ult_miss_streak := 0
var _standard_miss_streak := 0

var _last_offer_type := PerkSelection.SelectorType.Standard
var _same_type_streak := 0
var _max_same_type := 1


## Initializes perks, slots, signals, and resolves the player resource.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	selection.init(self)
	slots.init(self)
	_resolve_player_res()
	show_perk_selection_ui.connect(_on_show_perk_selection_ui)
	perk_selector.select_perk_by_index.connect(select_by_index)


## Updates the perk selector UI with the current offer.
func _on_show_perk_selection_ui(perks: Array[PerkBuild]) -> void:
	perk_selector.set_perk_details(perks)


## Main loop.
func _process(_delta: float) -> void:
	if not is_instance_valid(player_res):
		_resolve_player_res()
	_check_generator_interact()


## Checks whether the player can interact with a generator and open the selector.
func _check_generator_interact() -> void:
	if is_selecting or in_perk_session:
		return
	
	if is_instance_valid(abilities_ui) and abilities_ui._selecting:
		return
	
	for building in GlobalGame.Buildings:
		if building is CrystalGenerator:
			if building.player_list.has(player):
				if player_res.crystal_count >= needed_coins:
					building.interactionn_icon.show()
				else:
					building.interactionn_icon.hide()
	
	if not Input.is_action_just_pressed("interact"):
		return
	
	for building in GlobalGame.Buildings:
		if building is CrystalGenerator:
			if building.player_list.has(player):
				try_open_selector()
				return


## Consumes all available crystal thresholds and queues perk selections.
func try_open_selector() -> void:
	if not is_instance_valid(player_res):
		return
	
	if player_res.crystal_count < needed_coins:
		return
	
	while player_res.crystal_count >= needed_coins:
		player_res.crystal_count -= needed_coins
		_queued_selections += 1
		current_player_level += 1
		needed_coins = exp_to_next()
	
	if _queued_selections > 0:
		_process_next_selection()


## Processes the next queued perk selection.
func _process_next_selection() -> void:
	if _queued_selections <= 0:
		is_selecting = false
		in_perk_session = false
		get_tree().paused = false
		return
	
	selection.prune_maxed()
	
	if selection.perks_list.is_empty():
		selection.emergency_release_from_cooldown()
	
	if selection.perks_list.is_empty():
		_queued_selections = 0
		is_selecting = false
		in_perk_session = false
		get_tree().paused = false
		return
	
	_queued_selections -= 1
	is_selecting = true
	in_perk_session = true
	get_tree().paused = true
	
	_build_auto_offer()


## Builds an offer automatically based on available perk categories and soft RNG rules.
func _build_auto_offer() -> void:
	var has_standard_offer := _has_available_offer(PerkSelection.SelectorType.Standard)
	var has_activation_offer := _has_available_offer(PerkSelection.SelectorType.ActivationOnly)
	var has_ult_offer := _has_available_offer(PerkSelection.SelectorType.UltOnly)
	
	var need_activation := not slots.all_slots_filled()
	var need_ult := not slots.has_ult
	
	var weights: Array[Dictionary] = []
	var total_weight := 0.0
	
	if has_standard_offer:
		var standard_weight := 1.2 + float(_standard_miss_streak) * 0.15
		weights.append({
			"type": PerkSelection.SelectorType.Standard,
			"weight": standard_weight
		})
		total_weight += standard_weight
	
	if need_activation and has_activation_offer:
		var activation_weight := 0.65 + float(_activation_miss_streak) * 0.20
		weights.append({
			"type": PerkSelection.SelectorType.ActivationOnly,
			"weight": activation_weight
		})
		total_weight += activation_weight
	
	if need_ult and has_ult_offer:
		var ult_weight := 0.35 + float(_ult_miss_streak) * 0.15
		weights.append({
			"type": PerkSelection.SelectorType.UltOnly,
			"weight": ult_weight
		})
		total_weight += ult_weight
	
	if weights.is_empty():
		selection.build_standard_offer()
		_on_offer_built(PerkSelection.SelectorType.Standard)
		return
	
	var allowed_weights: Array[Dictionary] = []
	for entry in weights:
		if _same_type_streak >= _max_same_type and entry.type == _last_offer_type:
			continue
		allowed_weights.append(entry)
	
	if allowed_weights.is_empty():
		allowed_weights = weights.duplicate()
	
	var chosen_type := _roll_offer_type(allowed_weights)
	
	match chosen_type:
		PerkSelection.SelectorType.ActivationOnly:
			selection.build_activation_offer()
		PerkSelection.SelectorType.UltOnly:
			selection.build_ult_offer()
		PerkSelection.SelectorType.Standard:
			selection.build_standard_offer()
	
	_on_offer_built(chosen_type)


## Rolls one offer type from a weighted list.
func _roll_offer_type(weight_entries: Array[Dictionary]) -> PerkSelection.SelectorType:
	if weight_entries.is_empty():
		return PerkSelection.SelectorType.Standard
	
	var total_weight := 0.0
	for entry in weight_entries:
		total_weight += float(entry.weight)
	
	if total_weight <= 0.0:
		return weight_entries[0].type
	
	var roll := randf() * total_weight
	var current_sum := 0.0
	
	for entry in weight_entries:
		current_sum += float(entry.weight)
		if roll <= current_sum:
			return entry.type
	
	return weight_entries.back().type


## Updates streaks and pity counters after an offer type has been chosen.
func _on_offer_built(chosen_type: PerkSelection.SelectorType) -> void:
	if chosen_type == _last_offer_type:
		_same_type_streak += 1
	else:
		_same_type_streak = 0
	
	_last_offer_type = chosen_type
	
	match chosen_type:
		PerkSelection.SelectorType.Standard:
			_standard_miss_streak = 0
			_activation_miss_streak += 1
			_ult_miss_streak += 1
		
		PerkSelection.SelectorType.ActivationOnly:
			_activation_miss_streak = 0
			_standard_miss_streak += 1
			_ult_miss_streak += 1
		
		PerkSelection.SelectorType.UltOnly:
			_ult_miss_streak = 0
			_standard_miss_streak += 1
			_activation_miss_streak += 1


## Returns true if a selector type currently has at least one valid perk available.
func _has_available_offer(selector_type: PerkSelection.SelectorType) -> bool:
	var perks: Array[PerkBuild] = selection._get_available_perks(selector_type)
	return not perks.is_empty()


## Finalizes the selected perk and continues the queued perk session.
func finalize_after_level_up(perk: PerkBuild) -> void:
	if perk.is_ult():
		slots.register_ult(perk)
		abilities_ui.assign_ult(perk)
		selection.finalize(perk)
		is_selecting = false
		_process_next_selection()
	elif perk.is_activation():
		selection.finalize(perk)
		is_selecting = false
		
		if perk.assigned_slot == "":
			abilities_ui.begin_slot_selection(perk)
			await abilities_ui.slot_assigned
		
		_process_next_selection()
	else:
		selection.finalize(perk)
		is_selecting = false
		_process_next_selection()


## Applies the selected perk by index and finalizes it.
func select_by_index(idx: int) -> void:
	var perks = selection.perks_to_choose_from
	
	if idx < 0 or idx >= perks.size():
		return
	
	var perk: PerkBuild = perks[idx]
	perk.level_up_perk()
	finalize_after_level_up(perk)


## Resolves the player resource from the global player list.
func _resolve_player_res() -> void:
	for ply_res: PlayerResource in GlobalGame.Players:
		if ply_res.player == player:
			player_res = ply_res
			break


## Calculates the crystal cost for the next player level.
func exp_to_next() -> int:
	return ceil(25 + 12 * (current_player_level - 1) * 0.8)
