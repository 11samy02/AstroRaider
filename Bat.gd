extends EnemyBaseTemplate

@export var sprite_variation: Array[Texture2D]


@onready var sprite: Sprite2D = $sprite
@onready var wander_time: Timer = $Timer/wander_time
@onready var follow_time: Timer = $Timer/follow_time


func _ready() -> void:
	super()
	sprite.set_texture(sprite_variation.pick_random())


func _physics_process(delta: float) -> void:
	controll_state_mashine()


func controll_state_mashine():
	if global_position.distance_to(get_closest_target()) >= 300:
		state = state_mashine.Follow
		if follow_time.is_stopped():
			follow_time.start(3)
	if global_position.distance_to(get_closest_target()) >= 50:
		if randi_range(0,1) == 0 and wander_time.is_stopped():
			state = state_mashine.Follow
			if follow_time.is_stopped():
				follow_time.start(2)
		elif follow_time.is_stopped():
			state = state_mashine.Wander
			if wander_time.is_stopped():
				wander_time.start(2)
	elif global_position.distance_to(get_closest_target()) < 50:
		state = state_mashine.Attack



func _on_wander_time_timeout() -> void:
	state = state_mashine.Follow



