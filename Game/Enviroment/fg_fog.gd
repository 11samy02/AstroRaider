extends CanvasLayer
class_name EnviromentFgFog

@onready var sprite_2d: Sprite2D = $Sprite2D

func set_shader_color(color_ramp: GradientTexture2D) -> void:
	sprite_2d.material.set_shader_parameter("color_ramp", color_ramp)
