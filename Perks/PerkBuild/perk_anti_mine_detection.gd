extends PerkBuild

func activate_perk() -> void:
	Player_Res.has_perk_anti_mine_det = true
	GSignals.Perk_add_vision_behind_wall.emit(Player_Res, get_value())

func _exit_tree() -> void:
	pass
