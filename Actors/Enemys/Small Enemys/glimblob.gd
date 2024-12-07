extends EnemyBaseTemplate
class_name Glimblob


@onready var wander_time: Timer = $Timer/wander_time
@onready var follow_time: Timer = $Timer/follow_time

static var kill_count: int = 0

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



func applay_damage(entity: CharacterBody2D, damage: int = 1, crit_chance: float = 0.00) -> void:
	super(entity,damage,crit_chance)
	
	if entity == self:
		get_hit_anim()


func death() -> void:
	kill_count += 1
	super()
