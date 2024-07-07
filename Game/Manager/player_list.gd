extends Node2D


func _ready() -> void:
	for player in get_children():
		if player.is_in_group("Player"):
			GlobalGame.Players.append(player)
