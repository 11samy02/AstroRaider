extends Line2D
class_name Trail

@export var target: Node2D
@export var max_length: int = 100  

func _process(delta: float) -> void:
	if target:
		add_point(target.global_position)
		
		while get_point_count() > max_length:
			remove_point(0)
