extends CharacterBody2D
class_name Player

@onready var check_for_ground: RayCast2D = %check_for_ground
@onready var check_for_destroyable_ground: RayCast2D = %check_for_destroyable_ground
@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: Sprite2D = $Sprite

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_anim: AnimationPlayer = $Sprite/sprite_anim
@onready var bohrer_holder: Node2D = $bohrer_holder
@onready var bohrer_hit_coll: CollisionShape2D = $BohrerHitBox/bohrer_hit_coll


@onready var bohrer_delay: Timer = %Bohrer_delay
@onready var bohr_damage_time: Timer = %bohr_damage_time

var can_use_bohrer := false

@export var landing_anim_name : Array[String]

var gravity_dir := Vector2.DOWN

@export var player_id := 0
@export var character_build_id := 0

var is_bohrer_active := false

var stats: Stats = Stats.new()


func _ready() -> void:
	if character_build_id < PlayerDataBuilds.player_saved_res.saved_builds.size():
		stats = PlayerDataBuilds.player_saved_res.saved_builds[character_build_id].stats
	else:
		print("No Player Build was found with the ID ", character_build_id)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()
	set_bohrer_state()
	shader_effects()

func apply_gravity(delta: float) -> void:
	if !check_for_ground.is_colliding():
		if anim.current_animation == "idle":
			anim.stop()
			anim.play("fling")
		velocity += gravity_dir * stats.gravity_strength * delta
	else:
		if !anim.current_animation in landing_anim_name and !is_bohrer_active:
			anim.stop()
			sprite.frame = 4
			anim.play("idle")
		elif is_bohrer_active:
			anim.play("use_item")
		
		else:
			anim.play("idle")
		
		velocity = Vector2.ZERO
	velocity = velocity.clamp(Vector2(-stats.max_speed, -stats.max_speed), Vector2(stats.max_speed, stats.max_speed))


func _input(event: InputEvent) -> void:
	input_movement(event)

func input_movement(event: InputEvent) ->void:
	if player_id == 0:
		if Input.is_action_just_pressed("ui_left"):
			sprite.flip_h = true
			bohrer_holder.get_child(0).flip_h = true
			change_gravity(Vector2.LEFT)
		elif Input.is_action_just_pressed("ui_right"):
			sprite.flip_h = false
			bohrer_holder.get_child(0).flip_h = false
			change_gravity(Vector2.RIGHT)
		elif Input.is_action_just_pressed("ui_up"):
			change_gravity(Vector2.UP)
		elif Input.is_action_just_pressed("ui_down"):
			change_gravity(Vector2.DOWN)


func change_gravity(new_dir: Vector2) -> void:
	if new_dir != gravity_dir:
		var new_rotation = get_target_rotation(new_dir)
		var tween = create_tween()
		gravity_dir = new_dir
		velocity /= stats.gravity_break
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "rotation_degrees", new_rotation, 0.2)
		can_use_bohrer = false
		bohrer_delay.start()

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
	
	var current_angle = rotation_degrees
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




func _on_bohrer_delay_timeout() -> void:
	can_use_bohrer = true


#region Bohrer Logik

func set_bohrer_state() -> void:
	use_bohrer_anim()
	if check_for_destroyable_ground.is_colliding():
		destroy_ground()
		
	if player_id == 0:
		if gravity_dir == Vector2.LEFT and Input.is_action_pressed("ui_left"):
			is_bohrer_active = true
			
		elif gravity_dir == Vector2.RIGHT and Input.is_action_pressed("ui_right"):
			is_bohrer_active = true
			
		elif gravity_dir == Vector2.UP and Input.is_action_pressed("ui_up"):
			is_bohrer_active = true
			
		elif gravity_dir == Vector2.DOWN and Input.is_action_pressed("ui_down"):
			is_bohrer_active = true
			
		else:
			is_bohrer_active = false
		
	else:
		is_bohrer_active = false

func destroy_ground() -> void:
	if !is_bohrer_active:
		return
	
	var ground_pos = check_for_destroyable_ground.get_collision_point()
	
	
	if gravity_dir == Vector2.UP:
		ground_pos.y -= 8
	elif gravity_dir == Vector2.LEFT:
		ground_pos.x -= 8
	
	if bohr_damage_time.is_stopped() and snappedf(bohrer_holder.modulate.a, 0.01) >= 1:
		bohr_damage_time.start()
		await (bohr_damage_time.timeout)
		GSignals.ENV_destroy_tile.emit(ground_pos,stats.bohrer_damage)
	

func use_bohrer_anim() -> void:
	var tween = create_tween()
	
	if !is_bohrer_active or !can_use_bohrer:
		tween.tween_property(bohrer_holder, "modulate", Color("#ffffff00"), 0.05)
		bohrer_hit_coll.set_disabled(true)
		return
		
	else:
		tween.tween_property(bohrer_holder, "modulate", Color("#ffffff"), 0.05)
		bohrer_hit_coll.set_disabled(false)
		if anim.current_animation != "use_item":
			anim.stop()
			anim.play("use_item")



var shader_value = 0

func get_hit_anim() -> void:
	var tween = create_tween()
	shader_value = 1
	sprite.scale = Vector2(1.25,1.25)
	
	tween.tween_property(self, "shader_value", 0, 0.2)
	tween.parallel()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.2)
	
	sprite_anim.play("damaged", -1, stats.invincibility_frame)


func _on_bohrer_hit_box_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is EnemyBaseTemplate:
			var attack: AttackResource = AttackResource.new()
			attack.damage = stats.bohrer_damage
			attack.knockback = stats.bohrer_knockback
			
			area.get_hit(attack, self)
			
			var dir : Vector2 = (area.global_position - global_position).normalized()
			area.entity.get_knockback(dir, attack.knockback)

#endregion

func shader_effects() -> void:
	sprite.material.set_shader_parameter("mix_color", shader_value)

