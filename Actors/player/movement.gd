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
	var max_speed : Vector2 = Vector2(player.stats.max_speed + player.stats.added_max_speed, player.stats.max_speed + player.stats.added_max_speed)
	player.velocity = player.velocity.clamp(-max_speed, max_speed)



func input_movement(event: InputEvent) -> void:
	var dir = get_input_direction()
	if dir.length() < player.deadzone:
		return

	if abs(dir.x) > abs(dir.y):
		if dir.x < 0:
			player.sprite.flip_h = true
			player.bohrer_holder.get_child(0).flip_h = true
			change_gravity(Vector2.LEFT)
		else:
			player.sprite.flip_h = false
			player.bohrer_holder.get_child(0).flip_h = false
			change_gravity(Vector2.RIGHT)
	else:
		if dir.y < 0:
			change_gravity(Vector2.UP)
		else:
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

func get_input_direction() -> Vector2:
	if player.controller_id == 0 and Input.get_connected_joypads().size() == 0 and player.player_id == 0:
		return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	else:
		var joy_x = Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X)
		var joy_y = Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y)
		if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_LEFT): joy_x = -1.0
		elif Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_RIGHT): joy_x = 1.0
		if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_UP): joy_y = -1.0
		elif Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_DOWN): joy_y = 1.0
		return Vector2(joy_x, joy_y)
