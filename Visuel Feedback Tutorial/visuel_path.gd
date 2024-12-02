extends Line2D

var from_player : Player
var to_obj : Node2D
var distance := 25

func _process(delta: float) -> void:
	clear_points()
	add_point(from_player.global_position)
	add_point(to_obj.global_position)
	
	if from_player.global_position.distance_to(to_obj.global_position) < distance:
		queue_free()
