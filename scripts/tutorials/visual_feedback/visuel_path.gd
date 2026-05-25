extends Line2D
class_name VisualPath

var from_player : Player
var to_obj : Node2D
var distance := 25

func _ready() -> void:
	z_as_relative = false


func _exit_tree() -> void:
	_set_player_path_state(false)


func _process(_delta: float) -> void:
	if not is_instance_valid(from_player) or not is_instance_valid(to_obj):
		queue_free()
		return
	
	clear_points()
	add_point(from_player.global_position)
	add_point(to_obj.global_position)
	
	if from_player.global_position.distance_to(to_obj.global_position) < distance:
		queue_free()


func _set_player_path_state(value: bool) -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.player == from_player:
			player_res.has_a_path = value
			return
