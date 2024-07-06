extends Node

var player_list: Array[CharacterBody2D] = []

var current_cam : Camera2D

func add_player_to_list(player: CharacterBody2D) -> void:
	if player in player_list:
		player_list.append(player)


func add_camera():
	return
	var cam : Camera2D = Camera2D.new()
	cam.zoom = Vector2(4,4)
	add_child(cam)
	current_cam = cam

func _process(delta: float) -> void:
	return
	current_cam.global_position = get_center_of_players()

func get_center_of_players() -> Vector2:
	var all_pos : Array[Vector2] = []
	
	
	for player: CharacterBody2D in player_list:
		all_pos.append(player.global_position)
	
	if all_pos.is_empty():
		return Vector2.ZERO
	
	var center_vec : Vector2 = Vector2.ZERO
	
	for pos: Vector2 in all_pos:
		center_vec += pos
	
	center_vec /= all_pos.size()
	
	print(all_pos, " ", center_vec)
	
	return center_vec

