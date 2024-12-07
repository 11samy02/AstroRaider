extends Sprite2D


func _ready() -> void:
	var tween = create_tween()
	await get_tree().create_timer(0.2).timeout
	tween.tween_property(self, "modulate", "#ffffff00",0.3)
	queue_free()
