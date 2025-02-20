extends Control
class_name Mission

@export var id := 0
@export var titel := ""
@export var is_completted := false

@onready var anim: AnimationPlayer = $anim

func _enter_tree() -> void:
	GSignals.UI_mission_finished.connect(mission_cleared)

func mission_cleared(mission_id: int = -1) -> void:
	if mission_id == id and !is_completted:
		is_completted
		anim.play("mission cleared")
