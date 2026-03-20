extends Node

@export var player: Player
var player_res : PlayerResource

var static_hit_list : Array[Area2D] = []
var _last_bohrer_state := false

func _ready() -> void:
	await(get_tree().create_timer(0.1).timeout)
	for pla_res : PlayerResource in GlobalGame.Players:
		if pla_res.player == player:
			player_res = pla_res

func _physics_process(delta: float) -> void:
	if player.current_state == player.states.Default:
		set_bohrer_state()

func set_bohrer_state() -> void:
	use_bohrer_anim()
	bohrer_damage_on_static_hit()
	if player.check_for_destroyable_ground.is_colliding():
		destroy_ground()

	var dir = get_parent().get_node("Movement").get_input_direction()
	var is_moving_in_gravity_dir := false

	if player.gravity_dir == Vector2.LEFT and dir.x < -player.deadzone:
		is_moving_in_gravity_dir = true
	elif player.gravity_dir == Vector2.RIGHT and dir.x > player.deadzone:
		is_moving_in_gravity_dir = true
	elif player.gravity_dir == Vector2.UP and dir.y < -player.deadzone:
		is_moving_in_gravity_dir = true
	elif player.gravity_dir == Vector2.DOWN and dir.y > player.deadzone:
		is_moving_in_gravity_dir = true

	if is_moving_in_gravity_dir:
		player.is_bohrer_active = true
	else:
		player.is_bohrer_active = false
		player.bohrer_sound.stop()

##Muss geändert werden: ERROR
func destroy_ground() -> void:
	if !player.is_bohrer_active:
		player.bohrer_sound.stop()
		return
	
	if player.bohrer_holder.modulate.a >= 0.99:
		if !player.bohrer_sound.playing:
			player.bohrer_sound.play_sound()
		
		var bohrer_damage := player.stats.bohrer_damage + player.stats.added_bohrer_damage
		GSignals.ENV_check_detection_tile.emit(player_res, bohrer_damage)
	else:
		player.bohrer_sound.stop()

func use_bohrer_anim() -> void:
	if player.is_bohrer_active == _last_bohrer_state:
		return
	_last_bohrer_state = player.is_bohrer_active
	
	var tween = create_tween()
	if !player.is_bohrer_active:
		tween.tween_property(player.bohrer_holder, "modulate", Color("#ffffff00"), 0.05)
		player.bohrer_hit_coll.set_disabled(true)
	else:
		tween.tween_property(player.bohrer_holder, "modulate", Color("#ffffff"), 0.05)
		player.bohrer_hit_coll.set_disabled(false)
		if player.anim.current_animation != "use_item":
			player.anim.stop()
			player.anim.play("use_item")

func _on_bohrer_hit_box_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			var attack: AttackResource = AttackResource.new()
			attack.damage = player.stats.bohrer_damage + player.stats.added_bohrer_damage
			attack.knockback = player.stats.bohrer_knockback + player.stats.added_bohrer_knockback
			attack.crit_chance = player.stats.crit_chance + player.stats.added_crit_chance
			
			area.get_hit(attack, player)
			
			var dir : Vector2 = (area.global_position - player.global_position).normalized()
			area.entity.get_knockback(dir, attack.knockback)
	
	if area is StaticHitbox:
		static_hit_list.append(area)
		

func _on_bohrer_hit_box_area_exited(area: Area2D) -> void:
	if !is_instance_valid(area):
		return
	if area is StaticHitbox:
		if static_hit_list.has(area):
			static_hit_list.erase(area)

func bohrer_damage_on_static_hit() -> void:
	if static_hit_list.is_empty():
		return
	
	var attack: AttackResource = AttackResource.new()
	attack.damage = player.stats.bohrer_damage + player.stats.added_bohrer_damage
	for area in static_hit_list:
		if is_instance_valid(area.entity):
			await area.get_hit(attack, player)
