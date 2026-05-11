extends TextureRect

@onready var curser: TextureRect = $cursor

var radar_index := 0
var radar_radius := 70.0
var radar_center := Vector2.ZERO
var radar_scale_factor := 0.25

func _ready() -> void:
	radar_center = size / 2

func _process(delta: float) -> void:
	radar_center = size / 2
	set_rader_scale()
	queue_redraw()

func set_rader_scale() -> void:
	if GlobalGame.Players.size() > 1:
		var cam = GlobalGame.camera
		var zoom_diff = (cam.min_zoom - cam.max_zoom) / 5.0
		radar_index = int((cam.min_zoom - cam.zoom.x) / zoom_diff)
		radar_index = clamp(radar_index, 0, 4)
	elif Input.is_action_just_pressed("MapZoom"):
		if radar_index < 4:
			radar_index += 1
		else:
			radar_index = 0

	if texture is AtlasTexture:
		texture.region.position.x = 78 * radar_index

	if radar_index != 0:
		radar_scale_factor = 0.1 / (2.0 * radar_index)
	else:
		radar_scale_factor = 0.1

func _draw() -> void:
	update_map_positions()

func update_map_positions() -> void:
	var cam = GlobalGame.camera
	if cam == null:
		return

	var cam_center = cam.global_position
	var radar_zoom = cam.zoom.x * radar_scale_factor

	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		var radar_position = get_radar_position(enemy.global_position, cam_center, radar_zoom)
		update_radar_icon_position(enemy.radar_icon, radar_position)
	
	for boss: BossEntity in GlobalGame.Bosses:
		if not is_instance_valid(boss):
			continue
		var radar_position = get_radar_position(boss.global_position, cam_center, radar_zoom)
		update_radar_icon_position(boss.get_radar_icon(), radar_position)

	for building: Building in GlobalGame.Buildings:
		var radar_position = get_radar_position(building.global_position, cam_center, radar_zoom)
		update_radar_icon_position(building.radar_icon, radar_position)

	if GlobalGame.Players.size() > 1:
		for player_res: PlayerResource in GlobalGame.Players:
			var player = player_res.player
			var radar_position = get_radar_position(player.global_position, cam_center, radar_zoom)
			update_radar_icon_position(player.radar_icon, radar_position)

func get_radar_position(world_position: Vector2, cam_center: Vector2, radar_zoom: float) -> Vector2:
	var relative_pos = (world_position - cam_center) * radar_zoom

	if relative_pos.length() > radar_radius:
		relative_pos = relative_pos.normalized() * radar_radius

	return radar_center + relative_pos

func update_radar_icon_position(icon_tex: Texture2D, radar_position: Vector2) -> void:
	if icon_tex == null:
		return

	var draw_pos = radar_position - icon_tex.get_size() / 2
	draw_texture(icon_tex, draw_pos)
