extends PerkBuild

func _enter_tree() -> void:
	GSignals.PLA_is_shooting.connect(activate_auto_aim)

func activate_auto_aim(ply: Player) -> void:
	if ply == player:
		GSignals.PERK_Aim_bot_activate.emit(player, get_value())
