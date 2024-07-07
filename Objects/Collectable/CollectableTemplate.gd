extends Area2D
class_name  CollectableTemplate

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var collectable_name := ""


func collect(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if animation_player.has_animation("Collect"):
			animation_player.play("Collect")
		else:
			queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	queue_free()
