extends Node2D

@export var player: Player
@export var detector: PackedScene

@export var grid_size := 16
@export var detector_count := 9
@export var radius_in_tiles := 1

var can_destroy := true
var _snap := Vector2.ZERO


func _enter_tree() -> void:
	GSignals.ENV_check_detection_tile.connect(check_for_tile_points)
	GSignals.PERK_add_vision_behind_wall.connect(reset_detector)


func _ready() -> void:
	_snap = Vector2(grid_size / 2.0, grid_size / 2.0)
	_create_detectors()
	_update_detector_layout()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	_update_detector_layout()


## Creates the fixed detector grid once.
func _create_detectors() -> void:
	for child in get_children():
		child.queue_free()
	
	for i in detector_count * detector_count:
		var detector_instance: SingleDetector = detector.instantiate()
		add_child(detector_instance)


## Updates detector positions and activates only those inside the current radius.
func _update_detector_layout() -> void:
	var index := 0
	var radius_pixels := float(radius_in_tiles * grid_size)
	var half := int(detector_count / 2)
	
	for child in get_children():
		var detector_instance := child as SingleDetector
		if detector_instance == null:
			index += 1
			continue
		
		var x := index % detector_count - half
		var y := int(index / detector_count) - half
		var offset := Vector2(x, y) * grid_size
		var inside_radius := offset.length() <= radius_pixels
		
		detector_instance.monitoring = inside_radius
		detector_instance.monitorable = inside_radius
		detector_instance.visible = inside_radius
		detector_instance.set_process(inside_radius)
		
		if inside_radius:
			detector_instance.global_position = (player.global_position + offset).snapped(_snap)
		else:
			detector_instance.has_detected = false
		
		index += 1


## Collects all detected positions and emits the corresponding signals.
func check_for_tile_points(pla: PlayerResource, damage: int = 1) -> void:
	if not is_instance_valid(pla):
		return
	
	if pla.player != player:
		return
	
	var all_collision_pos: Array[Vector2] = []
	
	for child in get_children():
		var detector_instance := child as SingleDetector
		if detector_instance == null:
			continue
		
		if detector_instance.visible and detector_instance.has_detected:
			all_collision_pos.append(detector_instance.global_position)
	
	if all_collision_pos.is_empty():
		return
	
	if can_destroy:
		GSignals.ENV_destroy_tile.emit(all_collision_pos, damage)
	
	if pla.has_perk_anti_mine_det:
		GSignals.PERK_show_items_behind_wall.emit(all_collision_pos)


## Updates the radius when the perk changes.
func reset_detector(ply: Player, value: int) -> void:
	if can_destroy:
		return
	
	if ply != player:
		return
	
	radius_in_tiles = max(1, value)
	_update_detector_layout()
