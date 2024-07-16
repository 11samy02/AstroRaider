extends Camera2D
class_name MainCam

@export var zoom_factor: float = 900

@export var shakeFade: float = 10


var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0

var min_zoom := 5.0

func _enter_tree() -> void:
	GlobalGame.camera = self
	GSignals.CAM_shake_effect.connect(apply_shake)

func _process(delta: float) -> void:
	move()
	zooming()
	shake_effect_process(delta)

func move() -> void:
	var ave: Vector2
	
	for player_res:PlayerResource in GlobalGame.Players:
		ave += player_res.player.global_position
	
	ave /= GlobalGame.Players.size()
	global_position = ave

func zooming() -> void:
	var longest_dist:float = 100
	
	for player_1:PlayerResource in GlobalGame.Players:
		for player_2:PlayerResource in GlobalGame.Players:
			if player_1 == player_2:
				continue
			
			var dist:float = (player_1.player.global_position-player_2.player.global_position).length_squared()
			longest_dist = max(longest_dist, dist)
			
	var z = min(min_zoom, zoom_factor/sqrt(longest_dist))
	zoom = Vector2(z,z)

func get_pos_out_of_cam() -> Vector2:
	var pos_list : Array[Vector2] = []
	for i: Marker2D in $pos_list.get_children():
		pos_list.append(i.global_position)
	
	return pos_list.pick_random()


func apply_shake(randomStrength: float = rng.randf_range(2.0,4.0), shake_duration: float = 10) -> void:
	shakeFade = shake_duration
	shake_strength = randomStrength

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))

func shake_effect_process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		
		offset = randomOffset()
