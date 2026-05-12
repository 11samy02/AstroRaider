extends Node2D
class_name BossTentacleClaws

const CURVE_POINTS := 10
const BODY_FLIP_SPEED := 2.7
const BODY_RIPPLE_SPEED := 5.8
const IDLE_CURVE_STRENGTH := 0.16
const LUNGE_CURVE_STRENGTH := 0.035

@export var boss: BossEntity
@export_range(1, 24, 1) var claw_count: int = 5
@export var body_texture: Texture2D
@export var tip_texture: Texture2D
@export var body_texture_variants: Array[Texture2D] = []
@export var tip_texture_variants: Array[Texture2D] = []

@export_group("Layout")
@export var base_offset: Vector2 = Vector2(0.0, 22.0)
@export var claw_spacing: float = 24.0
@export var idle_length: float = 76.0
@export var side_length_falloff: float = 0.16
@export_range(0.0, 80.0, 1.0) var outer_fan_degrees: float = 58.0
@export_range(0.0, 0.6, 0.01) var outer_arm_bend: float = 0.24
@export var side_attach_lift: float = 9.0
@export_range(0.0, 80.0, 1.0) var idle_sway_degrees: float = 14.0
@export var idle_follow_speed: float = 11.0
@export var fallback_line_width: float = 12.0
@export_range(0.0, 1.0, 0.01) var tip_body_overlap: float = 0.45

@export_group("Attack")
@export var attack_range: float = 220.0
@export var attack_lunge_length: float = 150.0
@export var attack_lunge_overshoot: float = 18.0
@export var attack_hit_radius: float = 18.0
@export var attack_damage: int = 0
@export var attack_knockback_strength: float = 5.0
@export var attack_cooldown_min: float = 2.2
@export var attack_cooldown_max: float = 4.4
@export_range(1.0, 89.0, 1.0) var max_attack_angle_from_down: float = 58.0
@export var hit_cooldown: float = 0.45

@export_group("Timing")
@export var retract_duration: float = 0.08
@export var lunge_duration: float = 0.12
@export var return_duration: float = 0.24
@export var pullback_distance: float = 8.0

var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _attack_timer := 0.0
var _active_attack_index := -1
var _hit_enabled := false
var _last_segment_world := Vector2.ZERO
var _last_attack_dir := Vector2.DOWN
var _attack_tween: Tween = null
var _tentacles: Array[Dictionary] = []
var _hit_players_this_attack: Array[int] = []
var _hit_cooldowns: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	if boss == null:
		boss = get_parent() as BossEntity
	_sync_boss_material()
	_rebuild_tentacles()
	_reset_attack_timer()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.is_dead:
		return

	_sync_boss_material()
	_time += delta
	_attack_timer = max(0.0, _attack_timer - delta)
	_update_idle_tentacles(delta)

	if _active_attack_index >= 0:
		return

	if _attack_timer <= 0.0:
		if not _try_start_attack():
			_reset_attack_timer()


func _rebuild_tentacles() -> void:
	if _attack_tween != null:
		_attack_tween.kill()
		_attack_tween = null
	_active_attack_index = -1
	_hit_enabled = false
	_hit_players_this_attack.clear()

	for child in get_children():
		child.queue_free()

	_tentacles.clear()
	var count = max(1, claw_count)

	for i in range(count):
		var outward := _get_outward(i, count)
		var center_weight := 1.0 - clampf(abs(outward), 0.0, 1.0)
		var variant_index := _get_variant_index(center_weight)
		var current_body_texture := _get_texture_variant(body_texture_variants, body_texture, variant_index)
		var current_tip_texture := _get_texture_variant(tip_texture_variants, tip_texture, variant_index)
		var line_width := _get_line_width(current_body_texture)
		var base := _get_base_local(i, count)
		var dir := _get_idle_dir(i, count)
		var length := _get_idle_length(center_weight)
		var tip := base + dir * length

		var line := Line2D.new()
		line.name = "TentacleLine%d" % (i + 1)
		line.use_parent_material = true
		line.width = line_width
		line.texture = current_body_texture
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.z_index = -2
		add_child(line)

		var tip_sprite := Sprite2D.new()
		tip_sprite.name = "TentacleTip%d" % (i + 1)
		tip_sprite.use_parent_material = true
		tip_sprite.texture = current_tip_texture
		tip_sprite.scale = Vector2.ONE
		tip_sprite.z_index = -1
		add_child(tip_sprite)

		var data := {
			"line": line,
			"tip_sprite": tip_sprite,
			"base": base,
			"current_tip": tip,
			"desired_tip": tip,
			"center_weight": center_weight,
			"outward": outward,
			"variant_index": variant_index,
			"noise": float(i) * 1.731 + _rng.randf_range(0.0, TAU),
		}
		_tentacles.append(data)
		_draw_tentacle(i, tip, false)


func _update_idle_tentacles(delta: float) -> void:
	if _tentacles.size() != max(1, claw_count):
		_rebuild_tentacles()
		return

	var count := _tentacles.size()
	for i in range(count):
		if i == _active_attack_index:
			continue

		var data := _tentacles[i]
		var base := _get_base_local(i, count)
		var center_weight: float = data["center_weight"]
		var dir := _get_idle_dir(i, count)
		var target := base + dir * _get_idle_length(center_weight)
		var current: Vector2 = data["current_tip"]
		current = current.lerp(target, clampf(delta * idle_follow_speed, 0.0, 1.0))

		data["base"] = base
		data["desired_tip"] = target
		data["current_tip"] = current
		_tentacles[i] = data
		_draw_tentacle(i, current, false)


func _try_start_attack() -> bool:
	var target := _find_attack_target()
	if not is_instance_valid(target):
		return false

	var index := _get_tentacle_index_for_target(target.global_position)
	if index < 0:
		return false

	_start_attack(index, target)
	_reset_attack_timer()
	return true


func _start_attack(index: int, target: Player) -> void:
	if index < 0 or index >= _tentacles.size():
		return

	if _attack_tween != null:
		_attack_tween.kill()

	_active_attack_index = index
	_hit_enabled = false
	_hit_players_this_attack.clear()

	var data := _tentacles[index]
	var base: Vector2 = data["base"]
	var start: Vector2 = data["current_tip"]
	var to_target := to_local(target.global_position) - base
	var dir := _clamp_dir_to_down(to_target)
	_last_attack_dir = dir

	var target_dist := clampf(
		to_target.length() + attack_lunge_overshoot,
		idle_length * 0.75,
		attack_lunge_length
	)
	var pullback = base + dir * max(0.0, pullback_distance)
	var lunge_end := base + dir * target_dist
	var return_target: Vector2 = data["desired_tip"]

	_last_segment_world = to_global(start)
	_attack_tween = create_tween()
	_attack_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_attack_tween.tween_method(
		Callable(self, "_attack_update").bind(index, start, pullback, false),
		0.0,
		1.0,
		retract_duration
	)
	_attack_tween.tween_callback(Callable(self, "_set_hit_enabled").bind(true))
	_attack_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_method(
		Callable(self, "_attack_update").bind(index, pullback, lunge_end, true),
		0.0,
		1.0,
		lunge_duration
	)
	_attack_tween.tween_callback(Callable(self, "_apply_impact").bind(index))
	_attack_tween.tween_callback(Callable(self, "_set_hit_enabled").bind(false))
	_attack_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_attack_tween.tween_method(
		Callable(self, "_attack_update").bind(index, lunge_end, return_target, false),
		0.0,
		1.0,
		return_duration
	)
	_attack_tween.tween_callback(Callable(self, "_finish_attack"))


func _set_hit_enabled(value: bool) -> void:
	_hit_enabled = value
	if _active_attack_index >= 0 and _active_attack_index < _tentacles.size():
		var data := _tentacles[_active_attack_index]
		_last_segment_world = to_global(data["current_tip"])


func _attack_update(weight: float, index: int, from: Vector2, to: Vector2, can_hit_phase: bool) -> void:
	if index < 0 or index >= _tentacles.size():
		return

	var data := _tentacles[index]
	var tip := from.lerp(to, weight)
	var from_world := _last_segment_world
	var to_world := to_global(tip)

	data["current_tip"] = tip
	_tentacles[index] = data
	_draw_tentacle(index, tip, can_hit_phase)

	if can_hit_phase and _hit_enabled:
		_check_player_hits(from_world, to_world)

	_last_segment_world = to_world


func _apply_impact(index: int) -> void:
	if index < 0 or index >= _tentacles.size():
		return

	var data := _tentacles[index]
	var base: Vector2 = data["base"]
	var tip: Vector2 = data["current_tip"]
	_check_player_hits(to_global(base), to_global(tip))


func _finish_attack() -> void:
	_active_attack_index = -1
	_hit_enabled = false
	_attack_tween = null
	_hit_players_this_attack.clear()


func _draw_tentacle(index: int, tip_local: Vector2, spear_mode: bool) -> void:
	if index < 0 or index >= _tentacles.size():
		return

	var data := _tentacles[index]
	var line := data["line"] as Line2D
	var tip_sprite := data["tip_sprite"] as Sprite2D
	var base: Vector2 = data["base"]
	if not is_instance_valid(line) or not is_instance_valid(tip_sprite):
		return

	line.clear_points()
	var to_tip := tip_local - base
	if to_tip.length() < 1.0:
		line.add_point(base)
		line.add_point(tip_local)
		tip_sprite.position = tip_local
		return

	var dir := to_tip.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var len := to_tip.length()
	var outward: float = data["outward"]
	var curve_strength := LUNGE_CURVE_STRENGTH if spear_mode else IDLE_CURVE_STRENGTH
	var body_point_count = max(2, CURVE_POINTS - 2)
	var points: Array[Vector2] = []
	var root := _get_root_local(index, _tentacles.size())
	points.append(root)
	if base.distance_to(root) > 1.0:
		points.append(base)
	var desired_tip: Vector2 = data["desired_tip"]
	var lag_vec := desired_tip - tip_local
	var noise: float = data["noise"]
	var s_phase := _time * BODY_FLIP_SPEED + noise
	var ripple_phase := _time * BODY_RIPPLE_SPEED + noise * 1.7

	for point_index in range(body_point_count):
		var t := float(point_index + 1) / float(body_point_count + 1)
		var point := base + to_tip * t
		var envelope := sin(t * PI)
		var s_wave := sin(t * TAU + s_phase)
		var ripple := sin(t * TAU * 2.0 - ripple_phase) * 0.22
		point += perp * len * envelope * (s_wave * curve_strength + ripple * curve_strength * 0.35)
		point += Vector2(signf(outward), 0.0) * len * abs(outward) * outer_arm_bend * envelope

		if not spear_mode:
			point += lag_vec * (t * (1.0 - t)) * 0.32

		points.append(point)

	points.append(tip_local)

	for point in points:
		line.add_point(point)

	var tangent := points[points.size() - 1] - points[points.size() - 2]
	var angle := tangent.angle() if tangent.length_squared() > 0.001 else Vector2.DOWN.angle()
	var forward := Vector2.RIGHT.rotated(angle)
	var tip_offset := _get_tip_forward_offset(tip_sprite) - line.width * tip_body_overlap
	tip_sprite.position = tip_local + forward * tip_offset
	tip_sprite.rotation = angle


func _find_attack_target() -> Player:
	var best_player: Player = null
	var best_score := INF

	for player_res: PlayerResource in GlobalGame.Players:
		var player := player_res.player
		if not is_instance_valid(player):
			continue

		var local_pos := to_local(player.global_position)
		if local_pos.y < base_offset.y:
			continue

		var index := _get_tentacle_index_for_target(player.global_position)
		if index < 0:
			continue

		var base := _get_base_local(index, max(1, _tentacles.size()))
		var dist := local_pos.distance_to(base)
		if dist > attack_range:
			continue

		var score = dist + abs(local_pos.x - base.x) * 0.35
		if score < best_score:
			best_score = score
			best_player = player

	return best_player


func _get_tentacle_index_for_target(world_position: Vector2) -> int:
	if _tentacles.is_empty():
		return -1

	var local_pos := to_local(world_position)
	var best_index := 0
	var best_dist := INF
	var count := _tentacles.size()

	for i in range(count):
		var base := _get_base_local(i, count)
		var dist = abs(local_pos.x - base.x)
		if dist < best_dist:
			best_dist = dist
			best_index = i

	return best_index


func _check_player_hits(from_world: Vector2, to_world: Vector2) -> void:
	if from_world == to_world:
		return

	for player_res: PlayerResource in GlobalGame.Players:
		var player := player_res.player
		if not is_instance_valid(player):
			continue

		if _hit_players_this_attack.has(player.get_instance_id()):
			continue

		var dist := _distance_point_to_segment(player.global_position, from_world, to_world)
		if dist <= attack_hit_radius:
			_hit_player(player)


func _hit_player(player: Player) -> void:
	if not is_instance_valid(player):
		return

	var player_id := player.get_instance_id()
	var now := Time.get_ticks_msec() * 0.001
	var next_allowed := float(_hit_cooldowns.get(player_id, 0.0))
	if next_allowed > now:
		return

	_hit_cooldowns[player_id] = now + hit_cooldown
	_hit_players_this_attack.append(player_id)

	if attack_damage > 0 and is_instance_valid(player.hitbox):
		var attack := AttackResource.new()
		attack.damage = attack_damage
		attack.knockback = 0.0
		attack.crit_chance = 0.0
		player.hitbox.get_hit(attack)

	var dir := player.global_position - global_position
	if dir.length_squared() <= 0.001:
		dir = _last_attack_dir
	player.get_knockback(dir.normalized(), attack_knockback_strength)
	GSignals.CAM_shake_effect.emit()


func _reset_attack_timer() -> void:
	_attack_timer = _rng.randf_range(
		min(attack_cooldown_min, attack_cooldown_max),
		max(attack_cooldown_min, attack_cooldown_max)
	)


func _get_base_local(index: int, count: int) -> Vector2:
	var outward := _get_outward(index, count)
	var center := float(count - 1) * 0.5
	return base_offset + Vector2((float(index) - center) * claw_spacing, -abs(outward) * side_attach_lift)


func _get_root_local(index: int, count: int) -> Vector2:
	var base := _get_base_local(index, count)
	var outward := _get_outward(index, count)
	return Vector2(base.x * 0.72, base_offset.y - abs(outward) * side_attach_lift * 0.65)


func _get_idle_dir(index: int, count: int) -> Vector2:
	var outward := _get_outward(index, count)

	var sway := sin(_time * 1.8 + float(index) * 0.91) * deg_to_rad(idle_sway_degrees)
	var fan := -outward * deg_to_rad(outer_fan_degrees)
	return Vector2.DOWN.rotated(fan + sway)


func _get_idle_length(center_weight: float) -> float:
	return idle_length * lerpf(1.0 - side_length_falloff, 1.0, center_weight)


func _clamp_dir_to_down(vector: Vector2) -> Vector2:
	var dir := vector.normalized()
	if dir.length_squared() <= 0.001:
		return Vector2.DOWN

	var max_angle := deg_to_rad(max_attack_angle_from_down)
	var angle_from_down := Vector2.DOWN.angle_to(dir)
	if abs(angle_from_down) <= max_angle:
		return dir

	return Vector2.DOWN.rotated(signf(angle_from_down) * max_angle)


func _get_tip_forward_offset(tip_sprite: Sprite2D) -> float:
	if not is_instance_valid(tip_sprite) or tip_sprite.texture == null or not tip_sprite.centered:
		return 0.0

	return max(0.0, (tip_sprite.texture.get_size().x * abs(tip_sprite.scale.x)) * 0.5)


func _get_variant_index(center_weight: float) -> int:
	var variant_count = max(body_texture_variants.size(), tip_texture_variants.size())
	if variant_count <= 1:
		return 0

	return clampi(int(round(center_weight * float(variant_count - 1))), 0, variant_count - 1)


func _get_texture_variant(variants: Array[Texture2D], fallback: Texture2D, variant_index: int) -> Texture2D:
	if variants.is_empty():
		return fallback

	var clamped_index := clampi(variant_index, 0, variants.size() - 1)
	var texture := variants[clamped_index]
	if texture != null:
		return texture

	return fallback


func _get_line_width(texture: Texture2D) -> float:
	if texture != null:
		return max(1.0, float(texture.get_height()))

	return fallback_line_width


func _get_outward(index: int, count: int) -> float:
	if count <= 1:
		return 0.0

	var center := float(count - 1) * 0.5
	if center <= 0.0:
		return 0.0

	return clampf((float(index) - center) / center, -1.0, 1.0)


func _sync_boss_material() -> void:
	if use_parent_material and material == null:
		return

	material = null
	use_parent_material = true


func _distance_point_to_segment(point: Vector2, from: Vector2, to: Vector2) -> float:
	var segment := to - from
	var segment_length_sq := segment.length_squared()
	if segment_length_sq <= 0.0001:
		return point.distance_to(from)

	var t = clampf((point - from).dot(segment) / segment_length_sq, 0.0, 1.0)
	var closest = from + segment * t
	return point.distance_to(closest)
