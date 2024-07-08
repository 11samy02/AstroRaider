extends Node2D


func _ready() -> void:
	for player in get_children():
		if player.is_in_group("Player"):
			GlobalGame.Players.append(player)
			
	spawn_healtbars_to_players()


func spawn_healtbars_to_players():
	for player in GlobalGame.Players:
		var healthbar = preload("res://Actors/player/Healthbar.tscn").instantiate()
		healthbar.parent_entity = player
		healthbar.global_position = player.global_position
		add_child(healthbar)

