extends PerkBuild

func activate_perk() -> void:
	GSignals.Perk_add_vision_behind_wall.emit(Player_Res, get_value())

func _exit_tree() -> void:
	pass
