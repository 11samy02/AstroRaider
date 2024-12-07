extends GPUParticles2D

@export var sprite_variation : Array[Texture2D]

var sprite_id = 0

func _ready() -> void:
	if sprite_variation.is_empty():
		queue_free()
		return
	set_texture(sprite_variation[sprite_id])
	amount = randi_range(8,12)
	emitting = true



func _on_finished() -> void:
	queue_free()
