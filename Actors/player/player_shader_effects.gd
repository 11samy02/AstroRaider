extends Node
class_name PlayerShaderEffects

@export var sprite: Sprite2D

var _shader_value := 0.0
var _overload_intensity := 0.0

## Updates all shader parameters each frame
func run() -> void:
	sprite.material.set_shader_parameter("mix_color", _shader_value)
	sprite.material.set_shader_parameter("overload_intensity", _overload_intensity)

## Plays hit flash animation
func play_hit_flash(tween_ref: Tween) -> void:
	_shader_value = 1.0
	tween_ref.tween_property(self, "_shader_value", 0.0, 0.2)

## Sets overload intensity directly
func set_overload(intensity: float) -> void:
	_overload_intensity = intensity
	sprite.material.set_shader_parameter("overload_intensity", intensity)

## Plays power up flash then holds overload state
func play_overload_activation() -> void:
	var tween := create_tween()
	for i in range(4):
		tween.tween_method(set_overload, 0.0, 1.0, 0.1)
		tween.tween_method(set_overload, 1.0, 0.0, 0.1)
	tween.tween_method(set_overload, 0.0, 1.0, 0.4)

## Plays power down animation
func play_overload_deactivation() -> void:
	var tween := create_tween()
	tween.tween_method(set_overload, 1.0, 0.0, 0.3)
