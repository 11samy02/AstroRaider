extends Node
class_name EnemyShaderEffects

@export var enemy: EnemyBaseTemplate


## Updates the sprite shader mix_color parameter each frame
func run() -> void:
	enemy.sprite.material.set_shader_parameter("blink_strength", enemy.shader_value)
