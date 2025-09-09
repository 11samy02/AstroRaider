extends PerkBuild

var previous_value := 0

var player_res : PlayerResource

func activate_perk() -> void:
	super()
	if previous_value != get_value():
		GSignals.Perk_add_vision_behind_wall.emit(player, get_value())
		previous_value = get_value()
	if !is_instance_valid(player_res) and has_unlocked:
		for ply_res : PlayerResource in GlobalGame.Players:
			if ply_res.player == player:
				player_res = ply_res
				ply_res.has_perk_anti_mine_det = true


func level_up_perk() -> void:
	for ply_res : PlayerResource in GlobalGame.Players:
		if ply_res.player == player:
			if !ply_res.has_perk_anti_mine_det:
				ply_res.has_perk_anti_mine_det = true
	super()
