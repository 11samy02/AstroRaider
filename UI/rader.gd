extends TextureRect

@onready var curser: TextureRect = $curser
var rader_index = 0
var radar_radius = 70
var radar_center = custom_minimum_size / 2
var radar_scale_factor = 0.25

func _process(delta: float) -> void:
	set_rader_scale()
	update_map_positions()

func set_rader_scale():
	var cam = GlobalGame.camera
	var zoom_diff = (cam.min_zoom - cam.max_zoom) / 5
	rader_index = int((cam.min_zoom - cam.zoom.x) / zoom_diff)
	rader_index = clamp(rader_index, 0, 4)
	
	if texture is AtlasTexture:
		texture.region.position.x = 78 * rader_index
		if rader_index != 0:
			radar_scale_factor = 0.25 / (2 * rader_index)
		else:
			radar_scale_factor = 0.25

func update_map_positions():
	var cam = GlobalGame.camera
	var cam_center = cam.global_position
	
	var radar_zoom = cam.zoom.x * radar_scale_factor
	
	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		var enemy_pos = enemy.global_position
		var relative_pos = (enemy_pos - cam_center) * radar_zoom  
		
		if relative_pos.length() > radar_radius:
			relative_pos = relative_pos.normalized() * radar_radius
		
		var radar_position = radar_center + relative_pos
		update_radar_icon_position(enemy.radar_icon, radar_position)
	
	for building: Building in GlobalGame.Buildings:
		var building_pos = building.global_position
		var relative_pos = (building_pos - cam_center) * radar_zoom  
		
		if relative_pos.length() > radar_radius:
			relative_pos = relative_pos.normalized() * radar_radius
		
		var radar_position = radar_center + relative_pos
		update_radar_icon_position(building.radar_icon, radar_position)
	
	for player_res: PlayerResource in GlobalGame.Players:
		var player = player_res.player
		var pos = player.global_position
		var relative_pos = (pos - cam_center) * radar_zoom 
		
		if relative_pos.length() > radar_radius:
			relative_pos = relative_pos.normalized() * radar_radius
		
		var radar_position = radar_center + relative_pos
		update_radar_icon_position(player.radar_icon, radar_position)

func update_radar_icon_position(icon_tex: Texture2D, radar_position: Vector2):
	var icon = TextureRect.new()
	icon.texture = icon_tex
	add_child(icon)
	icon.position = radar_position
	await get_tree().physics_frame
	icon.queue_free()
