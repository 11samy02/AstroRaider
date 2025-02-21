extends Node2D

@export var player: Player
@export var detector : PackedScene

var grid_size := 16
@export var detector_count := 3

var can_destroy := true

func _enter_tree() -> void:
	GSignals.ENV_check_detection_tile.connect(check_for_tile_points)
	GSignals.Perk_add_vision_behind_wall.connect(reset_detector)

func _ready() -> void:
	for i in detector_count * detector_count:
		var detector_instance = detector.instantiate()
		add_child(detector_instance)

func _process(delta: float) -> void:
	var index = 0
	for i in get_children():
		var start_x = index % detector_count - detector_count/2
		var start_y = index / detector_count - detector_count/2
		var offset = Vector2(grid_size * start_x, grid_size * start_y)
		i.global_position = (player.global_position + offset).snapped(Vector2(grid_size/2, grid_size/2))
		index += 1
	

func check_for_tile_points(pla: PlayerResource, damage: int = 1):
	if is_instance_valid(pla):
		if pla.player == player:
			var all_collision_pos :Array[Vector2]= []
			
			for i:SingleDetector in get_children():
				if i.has_detected:
					all_collision_pos.append(i.global_position)
			
			if can_destroy:
				GSignals.ENV_destroy_tile.emit(all_collision_pos, damage)
			
			if pla.has_perk_anti_mine_det:
				GSignals.PERK_show_items_behind_wall.emit(all_collision_pos)

func reset_detector(pla_res : PlayerResource, value: int) -> void:
	if !can_destroy:
		if pla_res.player == player:
			detector_count = value
			for i in get_children():
				i.queue_free()
			for i in detector_count * detector_count:
				var detector_instance = detector.instantiate()
				add_child(detector_instance)
