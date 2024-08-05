extends PerkBuild


func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(heal_self)


func heal_self(entity: EnemyBaseTemplate) -> void:
	var res: Perk = PerkData.load_perk_res(Key)
	GSignals.HIT_take_heal.emit(Player_Res.player, res.value[Level])

func _exit_tree() -> void:
	pass

