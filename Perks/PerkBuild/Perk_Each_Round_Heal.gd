extends PerkBuild

## Passive: heals player at the end of each wave
func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(_on_wave_ended)

func _on_wave_ended() -> void:
	if has_unlocked:
		var max_hp := player.stats.max_hp + player.stats.added_max_hp
		GSignals.HIT_take_heal.emit(player, max_hp / 100.0 * get_value())
