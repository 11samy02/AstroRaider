extends PerkBuild


func _enter_tree() -> void:
	GSignals.ENE_killed_by.connect(heal_self)


func heal_self(entity: EnemyBaseTemplate) -> void:
	if entity.killed_by == Player_Res.player:
		GSignals.HIT_take_heal.emit(Player_Res.player, get_value())

func _exit_tree() -> void:
	pass
