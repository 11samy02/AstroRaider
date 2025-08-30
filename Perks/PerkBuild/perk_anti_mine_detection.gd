extends PerkBuild

var previous_value := 0

func activate_perk() -> void:
	super()
	if previous_value != get_value():
		GSignals.Perk_add_vision_behind_wall.emit(player, get_value())
		previous_value = get_value()
	

func level_up_perk() -> void:
	for ply_res : PlayerResource in GlobalGame.Players:
		if ply_res.player == player:
			if !ply_res.has_perk_anti_mine_det:
				ply_res.has_perk_anti_mine_det = true
	super()
