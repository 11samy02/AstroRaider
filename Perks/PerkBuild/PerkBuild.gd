extends Node
class_name PerkBuild

signal cooldown_started(duration: float)

@export var Key: PerkData.Keys
@export var player: Player
@export_range(1, 6) var Level := 1
@export var selected_in_run  := false

var ability_slot_ref: ability_slot = null

var stats: Stats
var perk_res: Perk
var assigned_slot: String = "" # "Q", "E", "C" or "X" for Ult

var _player_res: PlayerResource
var _cooldown_timer: Timer = null


## Initializes the perk by loading its resource and caching player stats
func _ready() -> void:
	if !is_instance_valid(player):
		printerr("Player Must be selected: ", self.name)
		return
	stats = player.stats
	perk_res = PerkData.load_perk_res(Key)


## Handles always-active perks and resets stats if not unlocked
func _process(delta: float) -> void:
	if !is_instance_valid(perk_res):
		return
	if !selected_in_run :
		_reset_stats()
		return
	if perk_res.active_type == Perk.Active_type_keys.Always:
		activate_perk()


## Called to activate the perk (override in subclasses)
func activate_perk() -> void:
	if !selected_in_run :
		_reset_stats()


## Resets all stat modifications applied by this perk (override in subclasses)
func _reset_stats() -> void:
	pass


## Returns the main value of the perk for the current level
func get_value() -> int:
	if !is_instance_valid(perk_res):
		return 0
	return perk_res.get_value(Level)


## Returns the cooldown duration for the current level
func get_cooldown() -> float:
	if !is_instance_valid(perk_res):
		return 0.0
	return perk_res.get_cooldown(Level)


## Returns the duration of the perk effect for the current level
func get_duration() -> float:
	if !is_instance_valid(perk_res):
		return 0.0
	return perk_res.get_duration(Level)


## Returns true if this perk is an ultimate ability
func is_ult() -> bool:
	return is_instance_valid(perk_res) and perk_res.active_type == Perk.Active_type_keys.Ult


## Returns true if this perk is an activation-type ability
func is_activation() -> bool:
	return is_instance_valid(perk_res) and perk_res.active_type == Perk.Active_type_keys.Activation


## Returns a list of perk keys that cannot be selected together with this perk
func get_excluded_keys() -> Array[PerkData.Keys]:
	if !is_instance_valid(perk_res):
		return []
	return perk_res.excluded_perks


## Resolves and returns the PlayerResource associated with this player
func get_player_res() -> PlayerResource:
	if !is_instance_valid(_player_res):
		for ply_res: PlayerResource in GlobalGame.Players:
			if ply_res.player == player:
				_player_res = ply_res
				break
	return _player_res


## Unlocks or increases the perk level up to max level
func level_up_perk() -> void:
	if !selected_in_run :
		print(self.name, " unlocked at Level: ", Level)
		selected_in_run  = true
		return
	var max_level := 3 if is_ult() else 6
	if Level >= max_level:
		printerr("Perk is already on Max Level: ", self.name)
		return
	Level += 1
	print(self.name, " leveled up to: ", Level)


## Returns true if the perk is currently on cooldown via ability slot
func is_on_cooldown() -> bool:
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false
