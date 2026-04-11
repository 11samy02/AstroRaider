extends Entity_Ai

@export var zigzag_strength: float = 80.0
@export var zigzag_frequency: float = 3.0
@export var accel: float = 700.0

var _time: float = 0.0

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_move(delta)
	parent.move_and_slide()


## Follows target while oscillating perpendicular to the approach direction
func _move(delta: float) -> void:
	var effective_delta := delta * EnemyStats.time_warp_multiplier
	_time += effective_delta
	var to_tgt := parent.get_closest_target() - parent.global_position
	var forward := to_tgt.normalized()
	var perp := Vector2(-forward.y, forward.x)
	var zigzag_offset := perp * sin(_time * zigzag_frequency) * zigzag_strength
	var desired_v := (forward * parent.stats.get_effective_speed()) + zigzag_offset
	parent.velocity = parent.velocity.move_toward(desired_v, accel * effective_delta)
