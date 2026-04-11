extends PerkBuild

var _duration_timer: Timer = null
var _is_active := false

## Initializes duration timer
func _ready() -> void:
	super()
	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_on_time_warp_finished)
	add_child(_duration_timer)

## Activates Time Warp — slows all enemies
func activate_perk() -> void:
	if !has_unlocked or _is_active or is_on_cooldown():
		return
	_is_active = true
	EnemyStats.time_warp_multiplier = _get_slow_multiplier()
	_duration_timer.start(get_duration())
	if is_instance_valid(ability_slot_ref):
		ability_slot_ref.show_active(get_cooldown())
	ScreenEffects.play_time_warp_in()

## Ends Time Warp and restores enemy speed
func _on_time_warp_finished() -> void:
	_is_active = false
	EnemyStats.time_warp_multiplier = 1.0
	cooldown_started.emit(get_cooldown())
	ScreenEffects.play_time_warp_out()

## Resets time warp state
func _reset_stats() -> void:
	_is_active = false
	EnemyStats.time_warp_multiplier = 1.0

## Returns true if active or on cooldown
func is_on_cooldown() -> bool:
	if _is_active:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false

## Returns slow multiplier based on level — level 1 = 30% speed, level 3 = 10%
func _get_slow_multiplier() -> float:
	var slow_values := [0.30, 0.20, 0.10]
	var idx := clampi(Level - 1, 0, slow_values.size() - 1)
	return slow_values[idx]
