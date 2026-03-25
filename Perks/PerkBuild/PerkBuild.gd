extends Node
class_name PerkBuild

signal cooldown_started(duration: float)

@export var Key: PerkData.Keys
@export var player: Player
@export_range(1, 6) var Level := 1
@export var has_unlocked := false

var ability_slot_ref: ability_slot = null

var stats: Stats
var perk_res: Perk
var assigned_slot: String = ""  # "Q", "E", "C" oder "X" fuer Ult

var _player_res: PlayerResource

var _cooldown_timer: Timer = null
@export var cooldowns: Array[float] = [50.0, 44.0, 38.0, 32.0, 26.0, 20.0]

func _ready() -> void:
	if !is_instance_valid(player):
		printerr("Player Must be selected: ", self.name)
		return
	stats = player.stats
	perk_res = PerkData.load_perk_res(Key)


func _process(delta: float) -> void:
	if !is_instance_valid(perk_res):
		return
	if !has_unlocked:
		_reset_stats()
		return
	if perk_res.active_type == Perk.Active_type_keys.Always:
		activate_perk()

## Override in subclasses to implement perk effect
func activate_perk() -> void:
	if !has_unlocked:
		_reset_stats()


## Override in subclasses to reset stats when perk is not active
func _reset_stats() -> void:
	pass


## Returns the current value for this perk's level
func get_value() -> int:
	return perk_res.value[Level - 1]


## Returns true if this perk is an ult type
func is_ult() -> bool:
	return is_instance_valid(perk_res) and perk_res.active_type == Perk.Active_type_keys.Ult


## Returns true if this perk is an Activation type
func is_activation() -> bool:
	return is_instance_valid(perk_res) and perk_res.active_type == Perk.Active_type_keys.Activation


## Returns the list of perk keys excluded by this perk
func get_excluded_keys() -> Array[PerkData.Keys]:
	if !is_instance_valid(perk_res):
		return []
	return perk_res.excluded_perks


## Returns or lazily resolves the PlayerResource for this perk's player
func get_player_res() -> PlayerResource:
	if !is_instance_valid(_player_res):
		for ply_res: PlayerResource in GlobalGame.Players:
			if ply_res.player == player:
				_player_res = ply_res
				break
	return _player_res


## Levels up the perk or unlocks it on first call
func level_up_perk() -> void:
	if !has_unlocked:
		print(self.name, " unlocked at Level: ", Level)
		has_unlocked = true
		return
	if Level >= 6:
		printerr("Perk is already on Max Level: ", self.name)
		return
	Level += 1
	print(self.name, " leveled up to: ", Level)

## Override in subclasses to return cooldown duration
func get_cooldown() -> float:
	if cooldowns.size() >= Level:
		return cooldowns[Level - 1]
	return 0.0

## Returns true if the ability slot cooldown is still running
func is_on_cooldown() -> bool:
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false
