extends Entity_Ai

@export var accel: float = 600.0
var _angle: float = 0.0
var _clockwise: bool = true

## Sets random start angle and orbit direction on ready
func _ready() -> void:
	_angle = randf() * TAU
	_clockwise = randi_range(0, 1) == 0

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_orbit(delta)
	parent.move_and_slide()

## Orbits around the closest target at a fixed radius
func _orbit(delta: float) -> void:
	var tgt := parent.get_closest_target()
	var dir_sign := -1.0 if _clockwise else 1.0
	_angle += parent.stats.orbit_speed * delta * dir_sign
	
	var desired_pos := tgt + Vector2(cos(_angle), sin(_angle)) * parent.stats.orbit_radius
	var to_desired := desired_pos - parent.global_position
	var dist := to_desired.length()
	
	var tangent := Vector2(-sin(_angle), cos(_angle)) * dir_sign * parent.stats.speed
	var correction = to_desired.normalized() * min(dist, parent.stats.speed)
	
	var desired_v = tangent + correction
	parent.velocity = parent.velocity.move_toward(desired_v, accel * delta)
