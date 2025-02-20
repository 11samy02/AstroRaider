extends Camera2D
class_name MainCam

@export var zoom_factor: float = 900
@export var shakeFade: float = 10

var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0

@export var min_zoom: float = 3.0  # Maximum zoom in (objects appear larger)
@export var max_zoom: float = 0.5  # Maximum zoom out (objects appear smaller)

func _enter_tree() -> void:
	GlobalGame.camera = self
	GSignals.CAM_shake_effect.connect(apply_shake)

func _process(delta: float) -> void:
	update_camera(delta)
	shake_effect_process(delta)

func update_camera(delta: float) -> void:
	if GlobalGame.Players.is_empty():
		return

	var min_pos = GlobalGame.Players[0].player.global_position
	var max_pos = min_pos
	for player_res: PlayerResource in GlobalGame.Players:
		var pos = player_res.player.global_position
		min_pos = min_pos.min(pos)
		max_pos = max_pos.max(pos)
		
	for player_res: PlayerResource in GlobalGame.Players:
		var pos = player_res.player_hand.global_position
		min_pos = min_pos.min(pos)
		max_pos = max_pos.max(pos)

	var center_pos = (min_pos + max_pos) / 2.0
	global_position = center_pos

	var players_size = max_pos - min_pos
	var padding = Vector2(200, 200)
	players_size += padding

	var viewport_size = get_viewport_rect().size

	var required_zoom_x = viewport_size.x / players_size.x
	var required_zoom_y = viewport_size.y / players_size.y
	var required_zoom = min(required_zoom_x, required_zoom_y, min_zoom)

	var z = clamp(required_zoom, max_zoom, min_zoom)
	zoom = Vector2(z, z)

	limit_players_within_camera()

func limit_players_within_camera() -> void:
	var viewport_size = get_viewport_rect().size
	var half_viewport_size = (viewport_size / zoom) / 2.0
	var camera_bounds = Rect2(global_position - half_viewport_size, viewport_size / zoom)

	var min_bounds = camera_bounds.position
	var max_bounds = camera_bounds.position + camera_bounds.size

	for player_res: PlayerResource in GlobalGame.Players:
		var player = player_res.player
		var player_pos = player.global_position

		var clamped_pos = Vector2(
			clamp(player_pos.x, min_bounds.x, max_bounds.x),
			clamp(player_pos.y, min_bounds.y, max_bounds.y)
		)

		if player_pos != clamped_pos:
			player.global_position = clamped_pos

func get_pos_out_of_cam() -> Vector2:
	var pos_list = $pos_list.get_children()
	var positions: Array[Vector2] = []
	for marker: Marker2D in pos_list:
		positions.append(marker.global_position)
	return positions.pick_random()

func apply_shake(randomStrength: float = rng.randf_range(2.0, 4.0), shake_duration: float = 10) -> void:
	shakeFade = shake_duration
	shake_strength = randomStrength

func randomOffset() -> Vector2:
	return Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)

func shake_effect_process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakeFade * delta)
		
		offset = randomOffset()
