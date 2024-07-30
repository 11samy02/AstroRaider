extends EnemyBaseTemplate
class_name Bat

const DIE_PARTICLE = preload("res://Particles/Enemys/small/bat_die_particle.tscn")


@onready var sprite: Sprite2D = $sprite
@onready var wander_time: Timer = $Timer/wander_time
@onready var follow_time: Timer = $Timer/follow_time

var shader_value: float = 0.0

static var kill_count: int = 0

func _ready() -> void:
	super()
	sprite.set_texture(sprite_variation.pick_random())


func _physics_process(delta: float) -> void:
	check_health()
	shader_effects()
	controll_state_mashine()


func controll_state_mashine():
	if knockback_time.is_stopped():
		if global_position.distance_to(get_closest_target()) >= 200:
			state = state_mashine.Follow
			if follow_time.is_stopped():
				follow_time.start()
		if global_position.distance_to(get_closest_target()) >= 50:
			if randi_range(0,1) == 0 and wander_time.is_stopped():
				state = state_mashine.Follow
				if follow_time.is_stopped():
					follow_time.start()
			elif follow_time.is_stopped():
				state = state_mashine.Wander
				if wander_time.is_stopped():
					wander_time.start()
		elif global_position.distance_to(get_closest_target()) < 50 and state != state_mashine.Wander:
			state = state_mashine.Attack
	else:
		move_and_slide()



func _on_wander_time_timeout() -> void:
	state = state_mashine.Follow


func shader_effects() -> void:
	sprite.material.set_shader_parameter("mix_color", shader_value)

func get_hit_anim() -> void:
	var tween = create_tween()
	shader_value = 1
	sprite.scale = Vector2(1.25,1.25)
	
	tween.tween_property(self, "shader_value", 0, 0.2)
	tween.parallel()
	tween.tween_property(sprite, "scale", Vector2(1,1), 0.2)

func applay_damage(entity: CharacterBody2D, damage: int = 1) -> void:
	super(entity,damage)
	
	if entity == self:
		get_hit_anim()
		
	

func death() -> void:
	var particle = DIE_PARTICLE.instantiate()
	particle.global_position = global_position
	particle.sprite_id = sprite_variation.find(sprite.texture)
	get_parent().add_child(particle)
	kill_count += 1
	super()
