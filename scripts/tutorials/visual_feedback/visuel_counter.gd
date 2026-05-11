extends Node2D

@export var text := ""
@export var color : Color = Color.WHITE
@export var outline_color : Color = Color.BLACK
@export var duration := 0.5
@export var distance := 20
@onready var label: Label = $Label

func _ready() -> void:
	pass

## Sets text, color, duration and distance then starts the animation
func setup(p_text: String, p_color: Color, p_duration: float = 0.5, p_distance: int = 20) -> void:
	text = p_text
	color = p_color
	duration = p_duration
	distance = p_distance
	label.set_text(text)
	label.modulate = color
	label.label_settings.outline_color = outline_color
	animate_label()

## Animates label upward and fades out before freeing
func animate_label() -> void:
	var end_position = global_position + (global_position + Vector2(randf_range(-1,1),randf_range(-1,1))).normalized() * distance
	var tween = create_tween()
	tween.tween_property(self, "global_position", end_position, duration)
	tween.parallel().tween_property(self, "modulate:a", 0, duration)
	tween.parallel().tween_property(self, "scale", Vector2(0.5,0.5), duration)
	await(tween.finished)
	queue_free()
