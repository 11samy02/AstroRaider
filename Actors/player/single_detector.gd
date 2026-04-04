extends Area2D
class_name SingleDetector

var has_detected := false
var player_inside := false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
	else:
		has_detected = true
		_update_debug_color()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
	else:
		has_detected = false
		_update_debug_color()


func _update_debug_color() -> void:
	if has_detected:
		modulate = Color.GREEN
	else:
		modulate = Color.RED
