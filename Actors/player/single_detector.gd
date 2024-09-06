extends Area2D
class_name SingleDetector

var has_detected = false
var player_inside = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = true
	else:
		has_detected = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = false
	else:
		has_detected = false

func _process(delta: float) -> void:
	if has_detected:
		modulate = Color.GREEN
	else:
		modulate = Color.RED
