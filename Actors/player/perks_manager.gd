extends Node

signal show_perk_selection_ui(perks: Array[PerkBuild])

@export var player: Player
@onready var perk_selector: Control = %PerkSelector


var perks_list: Array[PerkBuild] = []
var last_selected_perks: Array[PerkBuild] = []
var perks_to_choose_from: Array[PerkBuild] = []
var max_last_selections := 5
var max_choices := 3
var player_res: PlayerResource

var needed_coins := 10
var current_player_level := 1
var is_selecting := false

## Initialize perks from children
func _ready() -> void:
	_init_perks_from_children()

## Main loop, checks player_res and selection
func _process(_delta: float) -> void:
	if not is_instance_valid(player_res):
		_resolve_player_res()
	if _can_start_selection():
		_start_selection()

## Collect perks from children nodes
func _init_perks_from_children() -> void:
	perks_list.clear()
	for child in get_children():
		if child is PerkBuild and child.Level < 6 and not perks_list.has(child):
			perks_list.append(child)

## Resolve player resource from global players
func _resolve_player_res() -> void:
	for ply_res: PlayerResource in GlobalGame.Players:
		if ply_res.player == player:
			player_res = ply_res
			break

## Check if a new selection can start
func _can_start_selection() -> bool:
	if not is_instance_valid(player_res):
		return false
	if is_selecting:
		return false
	_prune_maxed()
	if perks_list.is_empty():
		_emergency_release_from_cooldown()
	if perks_list.is_empty():
		return false
	return player_res.crystal_count >= needed_coins

## Start selection phase
func _start_selection() -> void:
	is_selecting = true
	player_res.crystal_count -= needed_coins
	_build_offer()

## Build perk offer list, topping up from cooldown unless truly endgame
func _build_offer() -> void:
	perks_to_choose_from.clear()
	var available: Array[PerkBuild] = _get_available_perks()
	var total_remaining := _count_total_remaining()
	var target = min(max_choices, total_remaining)
	if available.size() < target:
		_top_up_available_from_cooldown(available, target)
	var count = min(target, available.size())
	if count <= 0:
		is_selecting = false
		return
	for i in count:
		var perk: PerkBuild = available.pick_random()
		perks_to_choose_from.append(perk)
		available.erase(perk)
	print("--- Neue Auswahl ---")
	for i in perks_to_choose_from.size():
		print(str(i + 1) + ": " + str(perks_to_choose_from[i].name))
	show_perk_selection_ui.emit(perks_to_choose_from)

## Get available perks (not maxed)
func _get_available_perks() -> Array:
	var cleaned: Array[PerkBuild] = []
	for p in perks_list:
		if p.Level < 6 and not cleaned.has(p):
			cleaned.append(p)
	return cleaned

## Remove perks that reached max level
func _prune_maxed() -> void:
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

## Finalize after leveling a perk
func _finalize_after_level_up(perk: PerkBuild) -> void:
	perks_to_choose_from.clear()
	if perk.Level >= 6:
		if perks_list.has(perk):
			perks_list.erase(perk)
	else:
		_cooldown_push(perk)
	current_player_level += 1
	needed_coins = exp_to_next()
	is_selecting = false

## Select a perk by index
func _select_by_index(idx: int) -> void:
	if idx < 0 or idx >= perks_to_choose_from.size():
		return
	var perk: PerkBuild = perks_to_choose_from[idx]
	print("Ausgewählt: " + str(perk.name))
	await perk.level_up_perk()
	_finalize_after_level_up(perk)

## Emergency release a few perks from cooldown if perks_list is empty
func _emergency_release_from_cooldown() -> void:
	if last_selected_perks.is_empty():
		return
	var released := 0
	while released < max_choices and not last_selected_perks.is_empty():
		var perk: PerkBuild = last_selected_perks[0]
		last_selected_perks.remove_at(0)
		if perk.Level < 6 and not perks_list.has(perk):
			perks_list.append(perk)
			released += 1

## Count all remaining non-maxed perks across lists
func _count_total_remaining() -> int:
	var count := 0
	for p in perks_list:
		if p.Level < 6:
			count += 1
	for p in last_selected_perks:
		if p.Level < 6 and not perks_list.has(p):
			count += 1
	return count

## Top up the available list from cooldown unless true endgame
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

## Calculate coins needed for next level
func exp_to_next() -> int:
	return ceil(25 + 12 * (current_player_level - 1) * 0.8)
