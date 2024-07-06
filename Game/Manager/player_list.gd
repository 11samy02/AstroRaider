extends Node2D


func _ready() -> void:
	for player in get_children():
		if player.is_in_group("Player"):
			GCamera.add_player_to_list(player)
			
	GCamera.add_camera()
