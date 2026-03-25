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


## Initialize perks and resolve player resource
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	selection.init(self)
	slots.init(self)
	_resolve_player_res()
	show_perk_selection_ui.connect(_on_show_perk_selection_ui)
	perk_selector.select_perk_by_index.connect(select_by_index)


## Show perk selector UI when signal fires
func _on_show_perk_selection_ui(perks: Array[PerkBuild]) -> void:
	perk_selector.set_perk_details(perks)


## Main loop
func _process(_delta: float) -> void:
	if not is_instance_valid(player_res):
		_resolve_player_res()
	_check_generator_interact()


## Check if player is near generator and presses interact
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


## Called when player presses F near generator
func try_open_selector() -> void:
	if not is_instance_valid(player_res):
		return
	if player_res.crystal_count < needed_coins:
		return
	# Alle möglichen Selections auf einmal berechnen und queuen
	while player_res.crystal_count >= needed_coins:
		player_res.crystal_count -= needed_coins
		_queued_selections += 1
		current_player_level += 1
		needed_coins = exp_to_next()
	if _queued_selections > 0:
		_process_next_selection()


## Process the next queued selection
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
	selection.build_offer()


## Called after a perk is selected and leveled up
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


## Called by PerkSelector signal when player selects a perk
func select_by_index(idx: int) -> void:
	var perks = selection.perks_to_choose_from
	if idx < 0 or idx >= perks.size():
		return
	var perk: PerkBuild = perks[idx]
	perk.level_up_perk()
	finalize_after_level_up(perk)


## Resolve player resource from global players
func _resolve_player_res() -> void:
	for ply_res: PlayerResource in GlobalGame.Players:
		if ply_res.player == player:
			player_res = ply_res
			break


## Calculate coins needed for next level
func exp_to_next() -> int:
	return ceil(25 + 12 * (current_player_level - 1) * 0.8)
