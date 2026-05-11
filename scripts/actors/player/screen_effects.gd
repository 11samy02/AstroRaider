extends CanvasLayer

@export var overload_vignette: ColorRect
@export var time_warp_vignette: ColorRect

## Shows overload vignette with fade in
func play_overload_vignette_in() -> void:
	overload_vignette.visible = true
	var tween := create_tween()
	tween.tween_method(_set_overload_vignette, 0.0, 1.0, 0.4)

## Hides overload vignette with fade out
func play_overload_vignette_out() -> void:
	var tween := create_tween()
	tween.tween_method(_set_overload_vignette, 1.0, 0.0, 0.3)
	await tween.finished
	overload_vignette.visible = false

## Sets overload vignette shader intensity
func _set_overload_vignette(value: float) -> void:
	overload_vignette.material.set_shader_parameter("intensity", value)



## Shows time warp vignette with sync blink then holds
func play_time_warp_in() -> void:
	time_warp_vignette.visible = true
	var tween := create_tween()
	tween.tween_method(_set_time_warp, 0.0, 1.0, 0.5)

## Fades out time warp vignette
func play_time_warp_out() -> void:
	var tween := create_tween()
	tween.tween_method(_set_time_warp, 1.0, 0.0, 0.5)
	await tween.finished
	time_warp_vignette.visible = false

## Sets time warp shader intensity
func _set_time_warp(value: float) -> void:
	time_warp_vignette.material.set_shader_parameter("intensity", value)
