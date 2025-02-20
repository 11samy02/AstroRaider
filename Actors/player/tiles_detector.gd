extends Node2D

var grid_size := 16
@export var detector_count := 7
@export var detector : PackedScene

func _ready() -> void:
	for i in detector_count * detector_count:
		var detector_instance = detector.instantiate()
		add_child(detector_instance)

func _process(delta: float) -> void:
	var index = 0
	var radius = ceil(detector_count / 2) * grid_size
	for i in get_children():
		var start_x = index % detector_count - detector_count / 2
		var start_y = index / detector_count - detector_count / 2
		var offset = Vector2(grid_size * start_x, grid_size * start_y)
		
		if offset.length() <= radius:
			i.global_position = (self.global_position + offset).snapped(Vector2(grid_size / 2, grid_size / 2))
		
		index += 1
