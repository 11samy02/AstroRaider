extends Node

@export var player: Player

func _physics_process(delta: float) -> void:
	if player.current_state == player.states.Default:
		set_bohrer_state()

func set_bohrer_state() -> void:
	use_bohrer_anim()
	bohrer_damage_on_static_hit()
	if player.check_for_destroyable_ground.is_colliding():
		destroy_ground()
		
	if player.controller_id == 0 and Input.get_connected_joypads().size() == 0 and player.player_id == 0:
		if player.gravity_dir == Vector2.LEFT and Input.is_action_pressed("ui_left"):
			player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.RIGHT and Input.is_action_pressed("ui_right"):
			player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.UP and Input.is_action_pressed("ui_up"):
			player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.DOWN and Input.is_action_pressed("ui_down"):
			player.is_bohrer_active = true
			
		else:
			player.is_bohrer_active = false
			player.bohrer_sound.stop()
	else:
		if player.gravity_dir == Vector2.LEFT and (Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X) < -player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_LEFT)) :
				player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.RIGHT and (Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X) > player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_RIGHT)) :
				player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.UP and (Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y) < -player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_UP)):
				player.is_bohrer_active = true
			
		elif player.gravity_dir == Vector2.DOWN and (Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y) > player.deadzone or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_DPAD_DOWN)):
				player.is_bohrer_active = true
			
		else:
			player.bohrer_sound.stop()
			player.is_bohrer_active = false
			

##Muss geändert werden: ERROR
func destroy_ground() -> void:
	if !player.is_bohrer_active:
		player.bohrer_sound.stop()
		return
	
	if player.bohrer_holder.modulate.a >= 0.99:
		if !player.bohrer_sound.playing:
			player.bohrer_sound.play_sound()
		GSignals.ENV_check_detection_tile.emit(player, player.stats.bohrer_damage)
	else:
		player.bohrer_sound.stop()

func use_bohrer_anim() -> void:
	var tween = create_tween()
	
	if !player.is_bohrer_active:
		tween.tween_property(player.bohrer_holder, "modulate", Color("#ffffff00"), 0.05)
		player.bohrer_hit_coll.set_disabled(true)
		return
		
	else:
		tween.tween_property(player.bohrer_holder, "modulate", Color("#ffffff"), 0.05)
		player.bohrer_hit_coll.set_disabled(false)
		if player.anim.current_animation != "use_item":
			player.anim.stop()
			player.anim.play("use_item")

var static_hit_list : Array[StaticHitbox] = []

func _on_bohrer_hit_box_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			var attack: AttackResource = AttackResource.new()
			attack.damage = player.stats.bohrer_damage
			attack.knockback = player.stats.bohrer_knockback
			attack.crit_chance = player.stats.crit_chance
			
			area.get_hit(attack, player)
			
			var dir : Vector2 = (area.global_position - player.global_position).normalized()
			area.entity.get_knockback(dir, attack.knockback)
	
	if area is StaticHitbox:
		static_hit_list.append(area)
		

func _on_bohrer_hit_box_area_exited(area: Area2D) -> void:
	if static_hit_list.has(area):
		static_hit_list.erase(area)

func bohrer_damage_on_static_hit() -> void:
	if static_hit_list.is_empty():
		return
	
	var attack: AttackResource = AttackResource.new()
	attack.damage = player.stats.bohrer_damage
	for area in static_hit_list:
		if is_instance_valid(area.entity):
			await area.get_hit(attack, player)
