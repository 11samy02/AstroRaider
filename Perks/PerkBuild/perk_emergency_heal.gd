extends PerkBuild

var _rounds_to_wait := 0


## Connects to the wave end signal
func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(_on_wave_ended)


## Disconnects the wave end signal
func _exit_tree() -> void:
	if GSignals.WAV_wave_endet.is_connected(_on_wave_ended):
		GSignals.WAV_wave_endet.disconnect(_on_wave_ended)


## Automatically heals when HP drops below 25%
func _process(delta: float) -> void:
	if !has_unlocked:
		return

	var res := get_player_res()
	if !is_instance_valid(res):
		return

	var max_hp := player.stats.get_max_hp_total()

	if _rounds_to_wait <= 0 and res.current_health <= max_hp / 4.0:
		GSignals.HIT_take_heal.emit(player, max_hp / 100.0 * get_value())
		_rounds_to_wait = 5


## Reduces cooldown rounds after each wave
func _on_wave_ended() -> void:
	if _rounds_to_wait > 0:
		_rounds_to_wait -= 1
