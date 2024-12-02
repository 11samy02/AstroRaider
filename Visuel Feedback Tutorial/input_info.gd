extends Node2D

@export var distance : int = 100

func _process(delta: float) -> void:
	var found_player := false
	for player_res in GlobalGame.Players:
		if player_res.player.global_position.distance_to(get_parent().global_position) < distance:
			found_player = true
			break
	
	if found_player:
		visible = true
	else:
		visible = false
