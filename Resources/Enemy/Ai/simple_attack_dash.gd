extends Entity_Ai

@onready var dash_time: Timer = $dash_time
var has_attacked: bool = false

@export var dash_speed_mul: float = 2.0
@export var retreat_speed_mul: float = 0.75
@export var accel: float = 900.0
@export var engage_dist: float = 5.0

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	attack(delta)
	parent.move_and_slide()

func attack(delta: float) -> void:
	var tgt := parent.get_closest_target()
	var to_tgt := tgt - parent.global_position
	var dir = to_tgt.length() > 0.001 if to_tgt.normalized() else Vector2.ZERO
	dir = to_tgt.normalized() if to_tgt.length() > 0.001 else Vector2.ZERO

	if to_tgt.length() < engage_dist:
		has_attacked = true

	var desired_v: Vector2 = (-dir * parent.stats.speed * retreat_speed_mul) if has_attacked else (dir * parent.stats.speed * dash_speed_mul)

	parent.velocity = parent.velocity.move_toward(desired_v, accel * delta)

	if dash_time.is_stopped():
		dash_time.start()

func _on_dash_time_timeout() -> void:
	has_attacked = !has_attacked
