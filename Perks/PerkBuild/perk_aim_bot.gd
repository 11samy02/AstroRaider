extends PerkBuild


func _enter_tree() -> void:
	GSignals.PLA_is_shooting.connect(activate_auto_aim)


func activate_auto_aim(player: Player) -> void:
	if player == Player_Res.player:
		GSignals.PERK_Aim_bot_activate.emit(Player_Res.player, get_value())

func _exit_tree() -> void:
	pass
