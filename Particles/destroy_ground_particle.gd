extends CPUParticles2D


func _ready() -> void:
	amount = randi_range(8,12)
	emitting = true



func _on_finished() -> void:
	queue_free()
