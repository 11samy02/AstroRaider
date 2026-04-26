extends PerkBuild

## Connects to the wave end signal
func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(_on_wave_ended)


## Disconnects the wave end signal
func _exit_tree() -> void:
	if GSignals.WAV_wave_endet.is_connected(_on_wave_ended):
		GSignals.WAV_wave_endet.disconnect(_on_wave_ended)


## Heals the player at the end of each wave
func _on_wave_ended() -> void:
	if selected_in_run :
		var max_hp := player.stats.get_max_hp_total()
		GSignals.HIT_take_heal.emit(player, max_hp / 100.0 * get_value())
