extends Camera2D

@export var zoom_factor: float = 800

var min_zoom := 4.0

func _process(delta: float) -> void:
	move()
	zooming()

func move() -> void:
	var ave: Vector2
	
	for player:CharacterBody2D in GlobalGame.Players:
		ave += player.global_position
	
	ave /= GlobalGame.Players.size()
	global_position = ave

func zooming() -> void:
	var longest_dist:float = 100
	
	for player_1:CharacterBody2D in GlobalGame.Players:
		for player_2:CharacterBody2D in GlobalGame.Players:
			if player_1 == player_2:
				continue
			
			var dist:float = (player_1.global_position-player_2.global_position).length_squared()
			longest_dist = max(longest_dist, dist)
			
	var z = min(min_zoom, zoom_factor/sqrt(longest_dist))
	zoom = Vector2(z,z)
