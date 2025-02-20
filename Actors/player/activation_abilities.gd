extends Node

@export var player : Player

var has_pressed := false

func _process(delta: float) -> void:
	if player.current_state == player.states.Default:
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == player:
				for perk: Perk in player_res.player.stats.Perks:
					if perk.active_type == perk.Active_type_keys.Activation:
						player_res.add_activation_skill(perk)
		
		input_controll()


func input_controll() -> void:
	if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) and !has_pressed or Input.is_action_just_pressed("aktivat_perk"):
		has_pressed = true
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == player:
				if player_res.activation_skills.is_empty():
					return
				var perk_build : PerkBuild = player_res.activation_skills[player_res.activation_id]
				if is_instance_valid(perk_build):
					perk_build.activate_perk()
	if !Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) or Input.is_action_just_released("aktivat_perk"):
		has_pressed = false
