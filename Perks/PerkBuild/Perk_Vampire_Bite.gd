extends PerkBuild


func _enter_tree() -> void:
	GSignals.ENE_killed_by.connect(heal_player)


func heal_player(player: Player) -> void:
	if player == Player_Res.player:
		GSignals.HIT_take_heal.emit(Player_Res.player, get_value())

func _exit_tree() -> void:
	pass
