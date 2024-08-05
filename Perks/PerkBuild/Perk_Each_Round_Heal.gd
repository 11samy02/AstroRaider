extends PerkBuild


func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(heal_self)


func heal_self() -> void:
	var res: Perk = PerkData.load_perk_res(Key)
	GSignals.HIT_take_heal.emit(Player_Res.player, Player_Res.max_health / 100 * res.value[Level - 1])

func _exit_tree() -> void:
	pass

