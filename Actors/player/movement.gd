extends Node

@export var player: Player

func _physics_process(delta: float) -> void:
	apply_gravity(delta)

func _input(event: InputEvent) -> void:
	if player.current_state == player.states.Default:
		input_movement(event)

func apply_gravity(delta: float) -> void:
	if !player.check_for_ground.is_colliding():
		
		if player.anim.current_animation == "idle":
			player.anim.stop()
			player.anim.play("fling")
		player.velocity += player.gravity_dir * player.stats.gravity_strength * delta
	else:
		if !player.anim.current_animation in player.landing_anim_name and !player.is_bohrer_active:
			player.anim.stop()
			player.sprite.frame = 4
			player.anim.play("idle")
		elif player.is_bohrer_active:
			player.anim.play("use_item")
		
		else:
			player.anim.play("idle")
		
		player.velocity = Vector2.ZERO
	player.velocity = player.velocity.clamp(Vector2(-player.stats.max_speed, -player.stats.max_speed), Vector2(player.stats.max_speed, player.stats.max_speed))



func input_movement(event: InputEvent) ->void:
	if player.controller_id == 0 and Input.get_connected_joypads().size() == 0 and player.player_id == 0:
		if Input.is_action_pressed("ui_left"):
			player.sprite.flip_h = true
			player.bohrer_holder.get_child(0).flip_h = true
			change_gravity(Vector2.LEFT)
		elif Input.is_action_pressed("ui_right"):
			player.sprite.flip_h = false
			player.bohrer_holder.get_child(0).flip_h = false
			change_gravity(Vector2.RIGHT)
		elif Input.is_action_pressed("ui_up"):
			change_gravity(Vector2.UP)
		elif Input.is_action_pressed("ui_down"):
			change_gravity(Vector2.DOWN)
	else:
		if Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X) < -player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_LEFT):
			player.sprite.flip_h = true
			player.bohrer_holder.get_child(0).flip_h = true
			change_gravity(Vector2.LEFT)
		elif Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X) > player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_RIGHT):
			player.sprite.flip_h = false
			player.bohrer_holder.get_child(0).flip_h = false
			change_gravity(Vector2.RIGHT)
		elif Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y) < -player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_UP):
			change_gravity(Vector2.UP)
		elif Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y) > player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_DOWN):
			change_gravity(Vector2.DOWN)


func change_gravity(new_dir: Vector2) -> void:
	if player.gravity_dir != new_dir:
		var new_rotation = get_target_rotation(new_dir)
		var tween = create_tween()
		player.gravity_dir = new_dir
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(player, "rotation_degrees", new_rotation, 0.2)

func get_target_rotation(new_dir: Vector2) -> float:
	var target_angle = 0.0
	if new_dir == Vector2.LEFT:
		target_angle = 90.0
	elif new_dir == Vector2.RIGHT:
		target_angle = -90.0
	elif new_dir == Vector2.UP:
		target_angle = 180.0
	elif new_dir == Vector2.DOWN:
		target_angle = 0.0
	
	var current_angle = player.rotation_degrees
	var angle_difference = wrap_angle(target_angle - current_angle)
	
	if angle_difference > 180.0:
		angle_difference -= 360.0
	elif angle_difference < -180.0:
		angle_difference += 360.0
	
	return current_angle + angle_difference

func wrap_angle(angle: float) -> float:
	while angle >= 360.0:
		angle -= 360.0
	while angle < 0.0:
		angle += 360.0
	return angle
