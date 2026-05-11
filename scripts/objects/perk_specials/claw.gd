extends Node2D

signal despawn_finished(claw: Node2D)

const STRIKE_COOLDOWN := 0.55
const RETRACT_DURATION := 0.055
const LUNGE_DURATION := 0.08
const RETURN_DURATION := 0.17

const DESPAWN_RETRACT_DURATION := 0.22
const DESPAWN_MIN_DISTANCE := 2.0
const DESPAWN_SPIRAL_TURNS := 0.55
const DESPAWN_SPIRAL_WOBBLE := 0.14

const DETECT_RADIUS := 96.0
const CURVE_POINTS := 10
const TIP_HIT_RADIUS := 14.0
const LINE_START_OFFSET := 6.0

const ENV_QUERY_MASK := 4294967295
const ENV_KILL_DAMAGE := 999999

const SPAWN_GROW_DURATION := 0.22
const SPAWN_LOCK_DURATION := 0.18

## 45 degrees each side
const SWAY_RANGE := PI / 4.0
const SWAY_SPEED := 2.2
const TIP_FOLLOW_SPEED := 12.0

## Enemy gets priority if it is anywhere inside the claw sweep sector
const ATTACK_CONE := deg_to_rad(34.0)
const ENEMY_SWEEP_EXTRA := deg_to_rad(12.0)

const ENV_FAN_RAY_COUNT := 5
const ENV_FAN_SPREAD := deg_to_rad(12.0)

## Idle shorter, stab longer
const IDLE_REACH_FACTOR := 0.78
const LUNGE_EXTENSION_BONUS := 18.0
const PULLBACK_CENTER_DISTANCE := 3.0

## Real S / reverse-S movement
const BODY_FLIP_SPEED := 3.2
const BODY_RIPPLE_SPEED := 6.5
const IDLE_CURVE_STRENGTH := 0.17
const LUNGE_CURVE_STRENGTH := 0.03

## Multiple tiles destroyed in one straight stab line
const TILE_LINE_STEP := 10.0
const TILE_LINE_BACK_OFFSET := 2.0

@onready var _line: Line2D = $Line2D
@onready var _tip: Sprite2D = $TipSprite
@onready var _area: Area2D = $Area2D

var _player: Player = null
var _angle_offset := 0.0
var _reach := 55.0
var _lunge_reach := 40.0
var _damage := 8
var _noise_offset := 0.0

var _time := 0.0
var _strike_timer := 0.0
var _spawn_lock_timer := 0.0
var _spawn_scale := 0.0

var _is_lunging := false
var _hit_enabled := false
var _is_despawning := false

var _current_idle_angle := 0.0
var _current_tip_local := Vector2.ZERO
var _desired_tip_local := Vector2.ZERO

var _wall_hit_world := Vector2.ZERO
var _wall_contact_found := false
var _target_enemy: Node2D = null
var _target_is_env := false
var _destroyed_tile_this_attack := false

var _last_segment_world := Vector2.ZERO
var _last_attack_dir := Vector2.RIGHT
var _damaged_enemies_this_attack: Array[Node2D] = []

var _attack_tween: Tween = null
var _spawn_tween: Tween = null
var _despawn_tween: Tween = null


## Called by Perk_Blood_Claws after instantiation
func setup(angle_offset: float, reach: float, lunge_reach: float, damage: int, player: Player) -> void:
	_angle_offset = angle_offset
	_noise_offset = angle_offset * 1.37
	_reach = reach
	_lunge_reach = lunge_reach
	_damage = damage
	_player = player


func _ready() -> void:
	_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_line.width = 7.0
	_line.z_index = -1

	_current_idle_angle = _angle_offset
	_current_tip_local = Vector2.RIGHT.rotated(_angle_offset) * 2.0
	_desired_tip_local = _current_tip_local

	_rebuild_curve(_current_tip_local, false)
	_play_spawn_grow()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		queue_free()
		return

	_time += delta
	_strike_timer = max(0.0, _strike_timer - delta)
	_spawn_lock_timer = max(0.0, _spawn_lock_timer - delta)

	global_position = _player.global_position

	if _is_despawning:
		return

	if _is_lunging:
		return

	var sway := sin(_time * SWAY_SPEED + _noise_offset) * SWAY_RANGE
	_current_idle_angle = _angle_offset + sway

	var current_reach = max(2.0, _get_idle_reach() * _spawn_scale)
	_desired_tip_local = Vector2.RIGHT.rotated(_current_idle_angle) * current_reach
	_current_tip_local = _current_tip_local.lerp(_desired_tip_local, clamp(delta * TIP_FOLLOW_SPEED, 0.0, 1.0))

	_rebuild_curve(_current_tip_local, false)

	if _spawn_scale < 0.98 or _spawn_lock_timer > 0.0:
		return

	if _strike_timer <= 0.0:
		_try_strike()


func _play_spawn_grow() -> void:
	_spawn_scale = 0.0
	_spawn_lock_timer = SPAWN_LOCK_DURATION

	if _spawn_tween != null:
		_spawn_tween.kill()

	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_method(Callable(self, "_set_spawn_scale"), 0.0, 1.0, SPAWN_GROW_DURATION)
	_spawn_tween.tween_callback(Callable(self, "_finish_spawn_grow"))


func _finish_spawn_grow() -> void:
	_spawn_tween = null


func _set_spawn_scale(value: float) -> void:
	_spawn_scale = value

	if _is_lunging or _is_despawning:
		return

	var dir := Vector2.RIGHT.rotated(_current_idle_angle)
	_desired_tip_local = dir * max(2.0, _get_idle_reach() * _spawn_scale)
	_current_tip_local = _current_tip_local.lerp(_desired_tip_local, 0.35)
	_rebuild_curve(_current_tip_local, false)


func _get_idle_reach() -> float:
	return _reach * IDLE_REACH_FACTOR


func _get_lunge_max_distance() -> float:
	return _reach + _lunge_reach + LUNGE_EXTENSION_BONUS


func _get_detect_radius() -> float:
	return max(DETECT_RADIUS, _get_lunge_max_distance() + 8.0)


## First point always stays exactly in player center
func _rebuild_curve(tip_local: Vector2, spear_mode: bool) -> void:
	_line.clear_points()

	if tip_local.length() < 1.0:
		var tiny_points: Array[Vector2] = [Vector2.ZERO, tip_local]
		for p in tiny_points:
			_line.add_point(p)
		_sync_tip_nodes_from_points(tiny_points)
		return

	var dir := tip_local.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var len := tip_local.length()
	var points: Array[Vector2] = []

	var curve_strength := LUNGE_CURVE_STRENGTH if spear_mode else IDLE_CURVE_STRENGTH
	var body_point_count = max(2, CURVE_POINTS - 2)
	var lag_vec := _desired_tip_local - tip_local
	var s_phase := _time * BODY_FLIP_SPEED + _noise_offset
	var ripple_phase := _time * BODY_RIPPLE_SPEED + _noise_offset * 1.7

	points.append(Vector2.ZERO)

	for i in range(body_point_count):
		var t := float(i + 1) / float(body_point_count + 1)
		var base := tip_local * t
		var envelope := sin(t * PI)
		var s_wave := sin(t * TAU + s_phase)
		var ripple := sin(t * TAU * 2.0 - ripple_phase) * 0.22

		var point := base
		point += perp * len * envelope * (s_wave * curve_strength + ripple * curve_strength * 0.35)

		if not spear_mode and not _is_despawning:
			point += lag_vec * (t * (1.0 - t)) * 0.42

		if i == 0:
			var inner_anchor = dir * min(LINE_START_OFFSET, len * 0.18)
			point = point.lerp(inner_anchor, 0.7)

		points.append(point)

	points.append(tip_local)

	for p in points:
		_line.add_point(p)

	_sync_tip_nodes_from_points(points)


func _sync_tip_nodes_from_points(points: Array[Vector2]) -> void:
	if points.is_empty():
		return

	var line_end: Vector2 = points[points.size() - 1]
	var end_angle := _current_idle_angle

	if points.size() >= 2:
		var tangent := points[points.size() - 1] - points[points.size() - 2]
		if tangent.length_squared() > 0.001:
			end_angle = tangent.angle()
	elif _current_tip_local.length_squared() > 0.001:
		end_angle = _current_tip_local.angle()

	var forward := Vector2.RIGHT.rotated(end_angle)
	var tip_offset := _get_tip_forward_offset()
	var tip_offset_factor := 0.25 if _is_despawning else 1.0

	_tip.position = line_end + forward * tip_offset * tip_offset_factor
	_tip.rotation = end_angle

	if _is_despawning:
		_area.position = line_end
	else:
		_area.position = _tip.position

	_area.rotation = end_angle


func _get_tip_forward_offset() -> float:
	if not is_instance_valid(_tip):
		return 0.0
	if _tip.texture == null:
		return 0.0
	if not _tip.centered:
		return 0.0

	var tex_width := _tip.texture.get_size().x
	return max(0.0, (tex_width * abs(_tip.scale.x)) * 0.5 - 1.0)


## Hard enemy priority:
## If any enemy exists inside this claw's swing sector, it wins over environment.
func _find_priority_enemy() -> Node2D:
	var best_enemy: Node2D = null
	var best_score := INF

	var detect_radius := _get_detect_radius()
	var current_forward := Vector2.RIGHT.rotated(_current_idle_angle)
	var sweep_forward := Vector2.RIGHT.rotated(_angle_offset)

	for enemy: Node2D in _get_attack_targets():
		if not is_instance_valid(enemy):
			continue

		var to_enemy := enemy.global_position - _player.global_position
		var dist := to_enemy.length()
		if dist < 6.0 or dist > detect_radius:
			continue

		var dir := to_enemy / dist
		var sweep_angle = abs(sweep_forward.angle_to(dir))
		if sweep_angle > SWAY_RANGE + ATTACK_CONE + ENEMY_SWEEP_EXTRA:
			continue

		var current_angle = abs(current_forward.angle_to(dir))

		var score = dist + current_angle * 18.0 + sweep_angle * 10.0
		if current_angle <= ATTACK_CONE:
			score -= 18.0

		if score < best_score:
			best_score = score
			best_enemy = enemy

	return best_enemy


func _get_attack_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	
	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		if is_instance_valid(enemy):
			targets.append(enemy)
	
	for boss: BossEntity in GlobalGame.Bosses:
		if is_instance_valid(boss):
			targets.append(boss)
	
	return targets


## Environment only if no enemy was found for this claw
func _find_nearest_env_tile_in_front() -> Dictionary:
	return _scan_env_fan(
		_player.global_position,
		_current_idle_angle,
		ENV_FAN_SPREAD,
		_get_lunge_max_distance(),
		ENV_FAN_RAY_COUNT
	)


func _scan_env_fan(origin: Vector2, center_angle: float, half_spread: float, scan_distance: float, ray_count: int) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var nearest_dist := INF
	var result_pos := Vector2.ZERO
	var found := false
	var exclude := _build_env_exclude_list()

	for i in range(ray_count):
		var ratio := 0.5 if ray_count == 1 else float(i) / float(ray_count - 1)
		var ray_angle = center_angle + lerp(-half_spread, half_spread, ratio)
		var dir := Vector2.RIGHT.rotated(ray_angle)

		var query := PhysicsRayQueryParameters2D.new()
		query.from = origin
		query.to = origin + dir * scan_distance
		query.collision_mask = ENV_QUERY_MASK
		query.exclude = exclude
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.hit_from_inside = true

		var result := space.intersect_ray(query)
		if result.is_empty():
			continue

		var collider = result.get("collider", null)
		if not _is_valid_env_collider(collider):
			continue

		var hit_world: Vector2 = result["position"]
		var dist := origin.distance_to(hit_world)
		if dist < 4.0:
			continue

		if dist < nearest_dist:
			nearest_dist = dist
			result_pos = hit_world
			found = true

	return {
		"hit": found,
		"world_pos": result_pos,
		"distance": nearest_dist
	}


func _build_env_exclude_list() -> Array:
	var exclude: Array = []

	if is_instance_valid(_player):
		exclude.append(_player.get_rid())
	if is_instance_valid(_area):
		exclude.append(_area.get_rid())

	for target: Node2D in _get_attack_targets():
		if not is_instance_valid(target):
			continue
		if target is CollisionObject2D:
			exclude.append(target.get_rid())

	return exclude


func _is_valid_env_collider(collider: Variant) -> bool:
	if collider == null:
		return false
	if collider == _player or collider == _area:
		return false

	if collider is Node:
		var node: Node = collider

		for target: Node2D in _get_attack_targets():
			if not is_instance_valid(target):
				continue
			if node == target or target.is_ancestor_of(node) or node.is_ancestor_of(target):
				return false

		var cls := node.get_class()
		if cls == "TileMap" or cls == "TileMapLayer":
			return true

		var parent := node.get_parent()
		if is_instance_valid(parent):
			var parent_cls := parent.get_class()
			if parent_cls == "TileMap" or parent_cls == "TileMapLayer":
				return true

			var parent_name := str(parent.name).to_lower()
			if parent_name.contains("tile") or parent_name.contains("wall") or parent_name.contains("env"):
				return true

		var node_name := str(node.name).to_lower()
		if node_name.contains("tile") or node_name.contains("wall") or node_name.contains("env"):
			return true

	return false


func _try_strike() -> void:
	if _is_despawning:
		return

	var enemy := _find_priority_enemy()
	if enemy != null:
		_strike_timer = STRIKE_COOLDOWN
		_target_enemy = enemy
		_target_is_env = false
		_start_attack(enemy.global_position - _player.global_position, enemy, false)
		return

	var env_result := _find_nearest_env_tile_in_front()
	if env_result.hit:
		_strike_timer = STRIKE_COOLDOWN
		_target_enemy = null
		_target_is_env = true
		_wall_hit_world = env_result.world_pos
		_start_attack(_wall_hit_world - _player.global_position, null, true)


## Slingshot attack:
## 1) tip retracts almost back into player center
## 2) from there it shoots out
## 3) then it returns to idle
func _start_attack(local_target: Vector2, target_enemy: Node2D, hit_env: bool) -> void:
	if _is_despawning:
		return
	if local_target.length_squared() <= 1.0:
		return

	_is_lunging = true
	_hit_enabled = false
	_target_enemy = target_enemy
	_target_is_env = hit_env
	_destroyed_tile_this_attack = false
	_wall_contact_found = false
	_damaged_enemies_this_attack.clear()

	var direction := local_target.normalized()
	_last_attack_dir = direction

	var origin := _current_tip_local
	var pullback_end := direction * PULLBACK_CENTER_DISTANCE

	var max_lunge_dist := _get_lunge_max_distance()
	var target_dist := local_target.length()

	if hit_env:
		target_dist += LUNGE_EXTENSION_BONUS
	else:
		target_dist += TIP_HIT_RADIUS

	target_dist = clamp(target_dist, _get_idle_reach() + 8.0, max_lunge_dist)
	var lunge_end := direction * target_dist
	var return_target := _desired_tip_local

	_last_segment_world = _player.global_position + _current_tip_local

	if _attack_tween != null:
		_attack_tween.kill()

	_attack_tween = create_tween()
	var tween := _attack_tween

	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(Callable(self, "_attack_update").bind(origin, pullback_end, false), 0.0, 1.0, RETRACT_DURATION)

	tween.tween_callback(Callable(self, "_set_hit_enabled").bind(true))
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_method(Callable(self, "_attack_update").bind(pullback_end, lunge_end, true), 0.0, 1.0, LUNGE_DURATION)

	tween.tween_callback(Callable(self, "_apply_impact").bind(target_enemy))
	tween.tween_callback(Callable(self, "_set_hit_enabled").bind(false))

	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_method(Callable(self, "_attack_update").bind(lunge_end, return_target, false), 0.0, 1.0, RETURN_DURATION)
	tween.tween_callback(Callable(self, "_finish_attack"))


func _set_hit_enabled(value: bool) -> void:
	_hit_enabled = value
	_last_segment_world = _player.global_position + _current_tip_local


## Tween passes progress first, bind appends from/to/can_hit afterwards
func _attack_update(weight: float, from: Vector2, to: Vector2, can_hit_phase: bool) -> void:
	if not is_instance_valid(_player):
		queue_free()
		return

	var tip := from.lerp(to, weight)
	var from_world := _last_segment_world
	var to_world := _player.global_position + tip

	_current_tip_local = tip
	global_position = _player.global_position

	if can_hit_phase and _hit_enabled:
		_check_forward_hits(from_world, to_world)

	_last_segment_world = to_world
	_rebuild_curve(tip, can_hit_phase)


func _check_forward_hits(from_world: Vector2, to_world: Vector2) -> void:
	if from_world == to_world:
		return

	## Remember env contact, but destroy only at the impact callback
	if _target_is_env and not _wall_contact_found:
		var space := get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.new()
		query.from = from_world
		query.to = to_world
		query.collision_mask = ENV_QUERY_MASK
		query.exclude = _build_env_exclude_list()
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.hit_from_inside = true

		var result := space.intersect_ray(query)
		if not result.is_empty():
			var collider = result.get("collider", null)
			if _is_valid_env_collider(collider):
				_wall_contact_found = true
				_wall_hit_world = result["position"]

	for enemy: Node2D in _get_attack_targets():
		if not is_instance_valid(enemy):
			continue
		if _damaged_enemies_this_attack.has(enemy):
			continue

		var dist := _distance_point_to_segment(enemy.global_position, from_world, to_world)
		if dist <= TIP_HIT_RADIUS:
			_damage_enemy(enemy)


func _apply_impact(target_enemy: Node2D) -> void:
	if not is_instance_valid(_player):
		return

	if is_instance_valid(target_enemy) and not _damaged_enemies_this_attack.has(target_enemy):
		_damage_enemy(target_enemy)

	if _target_is_env and not _destroyed_tile_this_attack:
		var contact_world := _wall_hit_world

		if not _wall_contact_found:
			var fallback := _scan_env_fan(
				_player.global_position,
				_last_attack_dir.angle(),
				ENV_FAN_SPREAD,
				_get_lunge_max_distance(),
				ENV_FAN_RAY_COUNT
			)
			if fallback.hit:
				contact_world = fallback.world_pos
			else:
				contact_world = _player.global_position + _current_tip_local

		_destroy_tiles_in_line(contact_world, _last_attack_dir)


func _damage_enemy(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return

	_damaged_enemies_this_attack.append(enemy)
	if enemy is BossEntity:
		var boss := enemy as BossEntity
		var attack := AttackResource.new()
		attack.damage = _damage
		attack.crit_chance = 0.0
		attack.knockback = 0.0
		boss.get_hit(attack, _player)
		return
	
	if enemy is EnemyBaseTemplate:
		GSignals.HIT_take_Damage.emit(enemy, _damage, 0.0)


## Environment ignores perk damage and gets guaranteed full destruction damage
func _destroy_tiles_in_line(contact_world: Vector2, dir: Vector2) -> void:
	if not is_instance_valid(_player):
		return

	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT.rotated(_current_idle_angle)
	dir = dir.normalized()

	_destroyed_tile_this_attack = true

	var hit_pos: Array[Vector2] = []
	hit_pos.append(contact_world - dir * TILE_LINE_BACK_OFFSET)
	hit_pos.append(contact_world)

	var chain_count := clampi(int(round((_lunge_reach + 22.0) / TILE_LINE_STEP)), 4, 8)
	for i in range(1, chain_count + 1):
		hit_pos.append(contact_world + dir * (float(i) * TILE_LINE_STEP))

	GSignals.ENV_destroy_tile.emit(hit_pos, ENV_KILL_DAMAGE)


func _finish_attack() -> void:
	_is_lunging = false
	_hit_enabled = false
	_target_enemy = null
	_target_is_env = false
	_wall_contact_found = false
	_attack_tween = null


func begin_despawn() -> void:
	if _is_despawning:
		return

	_is_despawning = true
	_is_lunging = false
	_hit_enabled = false
	_target_enemy = null
	_target_is_env = false
	_wall_contact_found = false
	_destroyed_tile_this_attack = false
	_damaged_enemies_this_attack.clear()

	if is_instance_valid(_area):
		_area.monitoring = false
		_area.monitorable = false

	if _attack_tween != null:
		_attack_tween.kill()
		_attack_tween = null

	if _spawn_tween != null:
		_spawn_tween.kill()
		_spawn_tween = null

	if _despawn_tween != null:
		_despawn_tween.kill()
		_despawn_tween = null

	if not is_instance_valid(_player):
		_finish_despawn()
		return

	var start_tip := _current_tip_local
	if start_tip.length() <= DESPAWN_MIN_DISTANCE:
		_finish_despawn()
		return

	var start_radius := start_tip.length()
	var start_angle := start_tip.angle()
	var spin_dir := -1.0 if sin(_angle_offset * 2.37) < 0.0 else 1.0

	_despawn_tween = create_tween()
	_despawn_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_despawn_tween.tween_method(
		Callable(self, "_despawn_spiral_update").bind(start_radius, start_angle, spin_dir),
		0.0,
		1.0,
		DESPAWN_RETRACT_DURATION
	)
	_despawn_tween.tween_callback(Callable(self, "_finish_despawn"))


func _despawn_spiral_update(weight: float, start_radius: float, start_angle: float, spin_dir: float) -> void:
	if not is_instance_valid(_player):
		_finish_despawn()
		return

	var radius = lerp(start_radius, DESPAWN_MIN_DISTANCE, weight)
	var angle := start_angle + spin_dir * TAU * DESPAWN_SPIRAL_TURNS * weight
	angle += sin(weight * TAU + _noise_offset) * DESPAWN_SPIRAL_WOBBLE * (1.0 - weight)

	var tip = Vector2.RIGHT.rotated(angle) * radius

	_current_idle_angle = angle
	_current_tip_local = tip
	_desired_tip_local = tip
	global_position = _player.global_position

	_rebuild_curve(tip, false)


func _finish_despawn() -> void:
	_despawn_tween = null
	despawn_finished.emit(self)
	queue_free()


func _distance_point_to_segment(point: Vector2, from: Vector2, to: Vector2) -> float:
	var segment := to - from
	var segment_length_sq := segment.length_squared()

	if segment_length_sq <= 0.0001:
		return point.distance_to(from)

	var t = clamp((point - from).dot(segment) / segment_length_sq, 0.0, 1.0)
	var closest = from + segment * t
	return point.distance_to(closest)
