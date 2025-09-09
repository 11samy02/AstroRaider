extends PerkBuild

func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(heal_self)

func heal_self() -> void:
	GSignals.HIT_take_heal.emit(player, (player.stats.max_hp + player.stats.added_max_hp) / 100 * get_value())
