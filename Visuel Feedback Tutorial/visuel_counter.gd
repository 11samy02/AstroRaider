extends Node2D

@export var text := ""
@export var color : Color = Color.WHITE
@export var outline_color : Color = Color.BLACK
@export var duration := 0.5
@export var distance := 20
@onready var label: Label = $Label

func _ready() -> void:
	label.set_text(text)
	label.modulate = color
	label.label_settings.outline_color = outline_color
	animate_label()

func animate_label() -> void:
	var end_position = global_position + (global_position + Vector2(randf_range(-1,1),randf_range(-1,1))).normalized() * distance
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_position, duration)
	tween.parallel().tween_property(self, "modulate:a", 0, duration)
	tween.parallel().tween_property(self, "scale", Vector2(0.5,0.5), duration)
	await(tween.finished)
	queue_free()
