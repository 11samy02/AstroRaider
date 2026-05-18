extends PerkBuild
class_name EnergyOverload

@export var max_speed_bonus_percent: Array[float] = [15.0, 20.0, 25.0, 30.0, 35.0, 45.0]
@export var attack_speed_reduction_percent: Array[float] = [20.0, 25.0, 30.0, 35.0, 40.0, 50.0]

var _duration_timer: Timer = null
var _is_active := false


## Initializes timers for duration and cooldown handling.
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


## Activates Energy Overload and applies temporary stat modifiers.
func activate_perk() -> void:
	if not selected_in_run:
		return

	if _is_active:
		return

	if is_on_cooldown():
		return

	if not has_valid_runtime_refs():
		return

	_is_active = true

	stats.set_modifier(stats.bohrer_damage_modifiers, get_perk_modifier_id(), get_bohrer_damage_bonus())
	stats.set_modifier(stats.max_speed_modifiers, get_perk_modifier_id(), get_max_speed_bonus())
	stats.set_modifier(stats.attack_speed_modifiers, get_perk_modifier_id(), get_attack_speed_modifier())

	_duration_timer.start(get_duration())
	_apply_boost()


## Removes all stat modifiers applied by Energy Overload.
func _reset_stats() -> void:
	if not is_instance_valid(stats):
		return

	if not _is_active:
		return

	stats.remove_modifier(stats.bohrer_damage_modifiers, get_perk_modifier_id())
	stats.remove_modifier(stats.max_speed_modifiers, get_perk_modifier_id())
	stats.remove_modifier(stats.attack_speed_modifiers, get_perk_modifier_id())

	_is_active = false


## Returns the drill damage bonus based on suit-scaled bohrer damage.
## Uses hybrid scaling so low damage values still feel good.
func get_bohrer_damage_bonus() -> float:
	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return float(Level)

	var suit_scaled_bohrer_damage := stats.get_suit_scaled_bohrer_damage(suit_modifier_id)

	var minimum_bonus := float(Level)
	var percent_bonus = round(suit_scaled_bohrer_damage * get_value_percent())

	return maxf(minimum_bonus, percent_bonus)


## Returns the movement speed bonus based on suit-scaled max speed.
func get_max_speed_bonus() -> float:
	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return 0.0

	var suit_scaled_max_speed := stats.get_suit_scaled_max_speed(suit_modifier_id)
	return suit_scaled_max_speed * (get_max_speed_bonus_percent() / 100.0)


## Returns the attack speed modifier as a negative cooldown reduction.
func get_attack_speed_modifier() -> float:
	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return 0.0

	var suit_scaled_attack_speed := stats.get_suit_scaled_attack_speed(suit_modifier_id)
	return -(suit_scaled_attack_speed * get_attack_speed_reduction_percent() / 100.0)


## Returns the movement speed bonus percent for the current level.
func get_max_speed_bonus_percent() -> float:
	if max_speed_bonus_percent.size() >= Level:
		return max_speed_bonus_percent[Level - 1]

	return 0.0


## Returns the attack speed reduction percent for the current level.
func get_attack_speed_reduction_percent() -> float:
	if attack_speed_reduction_percent.size() >= Level:
		return attack_speed_reduction_percent[Level - 1]

	return 0.0


## Ends overload, removes modifiers, and starts cooldown.
func _on_overload_finished() -> void:
	_reset_stats()

	_cooldown_timer.start(get_cooldown())
	cooldown_started.emit(get_cooldown())

	_remove_boost()


## Called when cooldown timer finishes.
func _on_cooldown_finished() -> void:
	pass


## Returns true if overload is active or cooldown is running.
func is_on_cooldown() -> bool:
	if _is_active:
		return true

	if is_instance_valid(_cooldown_timer) and _cooldown_timer.time_left > 0.0:
		return true

	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0

	return false


## Plays activation feedback effects.
func _apply_boost() -> void:
	player.shader_effects.play_overload_activation()
	ScreenEffects.play_overload_vignette_in()


## Plays deactivation feedback effects.
func _remove_boost() -> void:
	player.shader_effects.play_overload_deactivation()
	ScreenEffects.play_overload_vignette_out()
