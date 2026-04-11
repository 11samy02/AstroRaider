extends Entity_Ai

@onready var dash_time: Timer = $dash_time

@export var dash_speed_mul: float = 2.0
@export var retreat_speed_mul: float = 0.75
@export var accel: float = 900.0
@export var engage_dist: float = 5.0

var _has_attacked: bool = false


func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_attack(delta)
	parent.move_and_slide()


## Dashes toward target then retreats, cycling on timer
func _attack(delta: float) -> void:
	var to_tgt := parent.get_closest_target() - parent.global_position
	var dir := to_tgt.normalized() if to_tgt.length() > 0.001 else Vector2.ZERO

	if to_tgt.length() < engage_dist:
		_has_attacked = true

	var desired_v := -dir * parent.stats.get_effective_speed() * retreat_speed_mul if _has_attacked else dir * parent.stats.get_effective_speed() * dash_speed_mul
	parent.velocity = parent.velocity.move_toward(desired_v, accel * delta)

	if dash_time.is_stopped():
		dash_time.start()


## Toggles between dash and retreat phase
func _on_dash_time_timeout() -> void:
	_has_attacked = !_has_attacked
