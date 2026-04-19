extends Node

@export var drone: SentinelDrone

@export var protection_range: float = 420.0
@export var emergency_range: float = 170.0
@export var generator_threat_weight: float = 3.0
@export var player_threat_weight: float = 1.8
@export var approach_weight: float = 260.0
@export var distance_weight: float = 0.45
@export var stick_bonus: float = 2.0
@export var projectile_speed: float = 950.0

var _shot_timer: float = 0.0
var _generator: CrystalGenerator = null

func _physics_process(delta: float) -> void:
	if not is_instance_valid(drone):
		return
	if drone.is_dead:
		return

	_shot_timer -= delta
	_find_generator()

	drone.target = get_best_target()

	if is_instance_valid(drone.target):
		_try_shoot(drone.target)

func get_best_target() -> EnemyBaseTemplate:
	if not is_instance_valid(drone):
		return null
	if not is_instance_valid(drone.player):
		return null

	var protect_target := _get_priority_protect_target()
	var protect_pos := protect_target.global_position

	var best_enemy: EnemyBaseTemplate = null
	var best_score := -999999.0

	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		if not is_instance_valid(enemy):
			continue

		var dist_to_protect := enemy.global_position.distance_to(protect_pos)
		if dist_to_protect > protection_range:
			continue

		var score := 0.0

		score -= dist_to_protect * distance_weight

		if dist_to_protect <= emergency_range:
			score += 220.0

		var to_protect := protect_pos - enemy.global_position
		if to_protect.length() > 0.001 and enemy.velocity.length() > 0.1:
			score += enemy.velocity.normalized().dot(to_protect.normalized()) * approach_weight

		if protect_target is CrystalGenerator:
			score *= generator_threat_weight
		else:
			score *= player_threat_weight

		var dist_to_drone := enemy.global_position.distance_to(drone.global_position)
		score -= dist_to_drone * 0.25

		if enemy == drone.target:
			score += stick_bonus

		if score > best_score:
			best_score = score
			best_enemy = enemy

	return best_enemy

func _try_shoot(target: EnemyBaseTemplate) -> void:
	if _shot_timer > 0.0:
		return
	if not is_instance_valid(drone.projectile_scene):
		return

	var projectile := drone.projectile_scene.instantiate() as PlayerProjectile
	if not is_instance_valid(projectile):
		return

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = drone.global_position

	var shoot_dir := _get_intercept_direction(
		drone.global_position,
		target.global_position,
		target.velocity,
		projectile_speed
	)

	projectile.dir = shoot_dir
	projectile.speed = projectile_speed
	projectile.player = null

	if is_instance_valid(projectile.atk_resource):
		projectile.atk_resource = projectile.atk_resource.duplicate()
		projectile.atk_resource.damage = drone.damage
		projectile.atk_resource.crit_chance = 0.0
		projectile.atk_resource.has_stun = false

	_shot_timer = drone.fire_rate

func _get_intercept_direction(from_pos: Vector2, target_pos: Vector2, target_velocity: Vector2, shot_speed: float) -> Vector2:
	var to_target := target_pos - from_pos
	var a := target_velocity.length_squared() - shot_speed * shot_speed
	var b := 2.0 * to_target.dot(target_velocity)
	var c := to_target.length_squared()

	var t := -1.0

	if abs(a) < 0.0001:
		if abs(b) > 0.0001:
			t = -c / b
	else:
		var discriminant := b * b - 4.0 * a * c
		if discriminant >= 0.0:
			var sqrt_disc := sqrt(discriminant)
			var t1 := (-b - sqrt_disc) / (2.0 * a)
			var t2 := (-b + sqrt_disc) / (2.0 * a)

			if t1 > 0.0 and t2 > 0.0:
				t = min(t1, t2)
			elif t1 > 0.0:
				t = t1
			elif t2 > 0.0:
				t = t2

	var aim_pos := target_pos
	if t > 0.0:
		aim_pos = target_pos + target_velocity * t

	var dir := aim_pos - from_pos
	if dir.length() <= 0.001:
		return Vector2.RIGHT
	return dir.normalized()

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
	return _generator.current_health <= int(_generator.max_health / 5)

func _get_priority_protect_target() -> Node2D:
	if _should_prioritize_generator():
		return _generator
	return drone.player
