extends Node

@export var drone: SentinelDrone

@export var idle_acceleration: float = 700.0
@export var intercept_acceleration: float = 1500.0
@export var idle_speed: float = 95.0
@export var intercept_speed: float = 180.0
@export var drift_speed: float = 22.0

@export var guard_min_distance: float = 110.0
@export var guard_max_distance: float = 180.0
@export var wander_change_min: float = 0.65
@export var wander_change_max: float = 1.25
@export var guard_return_distance: float = 320.0

@export var intercept_offset_from_enemy: float = 70.0
@export var min_enemy_distance: float = 58.0
@export var max_enemy_distance: float = 185.0
@export var intercept_side_offset: float = 6.0

var _generator: CrystalGenerator = null
var _wander_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _noise_seed: float = 0.0

func _ready() -> void:
	randomize()
	_noise_seed = randf() * 1000.0

func tick(delta: float) -> void:
	if not is_instance_valid(drone):
		return
	if not is_instance_valid(drone.player):
		return

	_find_generator()

	if is_instance_valid(drone.target):
		_tick_intercept(delta)
	else:
		_tick_guard_hover(delta)

func _tick_guard_hover(delta: float) -> void:
	_wander_timer -= delta

	var guard_target := _get_priority_protect_target()
	var center := guard_target.global_position

	if _wander_timer <= 0.0 or _wander_target == Vector2.ZERO:
		_pick_new_wander_target(center)

	var to_center := center - drone.global_position
	var dist_to_center := to_center.length()

	if dist_to_center > guard_return_distance:
		var desired_back := center + _random_guard_offset()
		var to_back := desired_back - drone.global_position
		if to_back.length() > 0.001:
			var return_velocity := to_back.normalized() * idle_speed * 1.35
			drone.velocity = drone.velocity.move_toward(return_velocity, idle_acceleration * 1.25 * delta)
		return

	var to_wander := _wander_target - drone.global_position
	var desired_velocity := Vector2.ZERO

	if to_wander.length() > 0.001:
		desired_velocity = to_wander.normalized() * idle_speed

	var drift := Vector2(
		sin(Time.get_ticks_msec() * 0.0019 + _noise_seed),
		cos(Time.get_ticks_msec() * 0.0013 + _noise_seed * 1.37)
	) * drift_speed

	desired_velocity += drift

	var future_pos := drone.global_position + desired_velocity.normalized() * 18.0 if desired_velocity.length() > 0.001 else drone.global_position
	var future_dist_to_center := future_pos.distance_to(center)

	if future_dist_to_center > guard_max_distance:
		var pull_back := (center - drone.global_position).normalized() * idle_speed
		desired_velocity = desired_velocity.lerp(pull_back, 0.7)
	elif future_dist_to_center < guard_min_distance:
		var push_out := (drone.global_position - center).normalized()
		if push_out == Vector2.ZERO:
			push_out = Vector2.RIGHT
		desired_velocity = desired_velocity.lerp(push_out * idle_speed, 0.65)

	drone.velocity = drone.velocity.move_toward(desired_velocity, idle_acceleration * delta)

	if drone.global_position.distance_to(_wander_target) < 12.0:
		_pick_new_wander_target(center)

func _tick_intercept(delta: float) -> void:
	if not is_instance_valid(drone.target):
		_tick_guard_hover(delta)
		return

	var protect_target := _get_priority_protect_target()
	var protect_pos := protect_target.global_position
	var enemy_pos := drone.target.global_position
	var enemy_velocity := drone.target.velocity

	var incoming_dir := protect_pos - enemy_pos
	if incoming_dir.length() <= 0.001:
		incoming_dir = (protect_pos - drone.global_position)
	if incoming_dir.length() <= 0.001:
		incoming_dir = Vector2.RIGHT
	incoming_dir = incoming_dir.normalized()

	var predicted_enemy_pos := enemy_pos + enemy_velocity * 0.35

	var intercept_pos := predicted_enemy_pos + incoming_dir * intercept_offset_from_enemy

	var enemy_to_protect_dist := enemy_pos.distance_to(protect_pos)
	if enemy_to_protect_dist < 120.0:
		intercept_pos = protect_pos - incoming_dir * guard_min_distance

	var to_intercept := intercept_pos - drone.global_position
	var dist_to_protect := drone.global_position.distance_to(protect_pos)

	var desired_velocity := Vector2.ZERO

	if to_intercept.length() > 0.001:
		desired_velocity = to_intercept.normalized() * intercept_speed

	if dist_to_protect > guard_return_distance:
		var emergency_return := (protect_pos - drone.global_position).normalized() * (intercept_speed * 1.15)
		desired_velocity = desired_velocity.lerp(emergency_return, 0.65)

	drone.velocity = drone.velocity.move_toward(desired_velocity, intercept_acceleration * delta)

func _pick_new_wander_target(center: Vector2) -> void:
	var forward_bias := Vector2.ZERO

	if is_instance_valid(drone.target):
		var protect_target := _get_priority_protect_target()
		var danger_dir := protect_target.global_position - drone.target.global_position
		if danger_dir.length() > 0.001:
			forward_bias = danger_dir.normalized() * guard_min_distance * 0.7

	_wander_target = center + _random_guard_offset() - forward_bias
	_wander_timer = randf_range(wander_change_min, wander_change_max)

func _random_guard_offset() -> Vector2:
	var angle := randf() * TAU
	var radius := randf_range(guard_min_distance, guard_max_distance)
	var offset := Vector2.RIGHT.rotated(angle) * radius

	var extra_jitter := Vector2(
		randf_range(-10.0, 10.0),
		randf_range(-10.0, 10.0)
	)

	return offset + extra_jitter

func _find_generator() -> void:
	if is_instance_valid(_generator):
		return

	for building: Building in GlobalGame.Buildings:
		if building is CrystalGenerator:
			_generator = building
			return

func _should_prioritize_generator() -> bool:
	if not is_instance_valid(_generator):
		return false
	if not _generator.has_health:
		return false
	return _generator.current_health <= int(_generator.max_health / 2)

func _get_priority_protect_target() -> Node2D:
	if _should_prioritize_generator():
		return _generator
	return drone.player
