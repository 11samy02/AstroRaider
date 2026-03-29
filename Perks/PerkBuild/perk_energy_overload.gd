extends PerkBuild
class_name EnergyOverload

@export var max_speed_bonus: Array[float] = [40.0, 55.0, 70.0, 85.0, 100.0, 120.0]
@export var attack_speed_reduction_percent: Array[float] = [20.0, 25.0, 30.0, 35.0, 40.0, 50.0]

var _duration_timer: Timer = null
var _is_active := false


## Initializes timers for duration and cooldown handling
func _ready() -> void:
	super()

	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_on_overload_finished)
	add_child(_duration_timer)

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)


## Activates Energy Overload and applies temporary stat modifiers
func activate_perk() -> void:
	if !has_unlocked:
		return
	if _is_active:
		return
	if is_on_cooldown():
		return
	if !is_instance_valid(stats):
		return
	
	_is_active = true
	stats.set_modifier(stats.bohrer_damage_modifiers, Key, get_bohrer_damage_bonus())
	stats.set_modifier(stats.max_speed_modifiers, Key, get_max_speed_bonus())
	stats.set_modifier(stats.attack_speed_modifiers, Key, get_attack_speed_modifier())
	_duration_timer.start(get_duration())
	_apply_boost()


## Removes all stat modifiers applied by Energy Overload
func _reset_stats() -> void:
	if !is_instance_valid(stats):
		return
	if !_is_active:
		return

	stats.remove_modifier(stats.bohrer_damage_modifiers, Key)
	stats.remove_modifier(stats.max_speed_modifiers, Key)
	stats.remove_modifier(stats.attack_speed_modifiers, Key)
	_is_active = false


## Returns the drill damage bonus based on perk value
func get_bohrer_damage_bonus() -> float:
	return float(get_value())


## Returns the movement speed bonus for the current level
func get_max_speed_bonus() -> float:
	if max_speed_bonus.size() >= Level:
		return max_speed_bonus[Level - 1]
	return 0.0


## Returns the attack speed modifier as a negative cooldown reduction
func get_attack_speed_modifier() -> float:
	return -(stats.attack_speed * get_attack_speed_reduction_percent() / 100.0)


## Returns the attack speed reduction percent for the current level
func get_attack_speed_reduction_percent() -> float:
	if attack_speed_reduction_percent.size() >= Level:
		return attack_speed_reduction_percent[Level - 1]
	return 0.0


## Ends overload, removes modifiers, and starts cooldown
func _on_overload_finished() -> void:
	_reset_stats()
	_cooldown_timer.start(get_cooldown())
	cooldown_started.emit(get_cooldown())
	_remove_boost()


## Called when cooldown timer finishes
func _on_cooldown_finished() -> void:
	pass


## Returns true if overload is active or cooldown is running
func is_on_cooldown() -> bool:
	if _is_active:
		return true
	if is_instance_valid(_cooldown_timer) and _cooldown_timer.time_left > 0.0:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false


## Plays activation feedback effects
func _apply_boost() -> void:
	player.shader_effects.play_overload_activation()
	ScreenEffects.play_overload_vignette_in()


## Plays deactivation feedback effects
func _remove_boost() -> void:
	player.shader_effects.play_overload_deactivation()
	ScreenEffects.play_overload_vignette_out()
