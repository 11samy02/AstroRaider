extends Node

@export var player: Player

func _physics_process(delta: float) -> void:
	if Input.is_action_just_released("aktivate_building_mode"):
		if player.current_state == player.states.Default:
			player.current_state = player.states.Build
		else:
			player.current_state = player.states.Default
