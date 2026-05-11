extends Node
class_name NoxulMovement

@export var boss: Node2D
@export var sprite: Sprite2D
@export var move_speed: float = 90.0
@export var acceleration: float = 420.0
@export var hover_distance: float = 140.0
@export var stop_distance: float = 36.0
@export_range(0.0, 1.0, 0.05) var orbit_weight: float = 0.45
@export var movement_enabled := true
@export var scream_effect: AnimatedSprite2D
@export var charge_effect: AnimatedSprite2D

var _orbit_dir := 1.0


func _ready() -> void:
	_orbit_dir = -1.0 if randi_range(0, 1) == 0 else 1.0
	if boss == null:
		var script_root := get_parent()
		if script_root != null:
			boss = script_root.get_parent() as Node2D
	if sprite == null and is_instance_valid(boss) and boss.has_node("Sprite2D"):
		sprite = boss.get_node("Sprite2D") as Sprite2D
	if scream_effect == null and is_instance_valid(boss) and boss.has_node("scream_effect"):
		scream_effect = boss.get_node("scream_effect") as AnimatedSprite2D
	if charge_effect == null and is_instance_valid(boss) and boss.has_node("charge_effect"):
		charge_effect = boss.get_node("charge_effect") as AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss):
		return
	
	if not movement_enabled:
		_set_boss_velocity(_get_boss_velocity().move_toward(Vector2.ZERO, acceleration * delta))
		_move_boss()
		return
	
	var target := _get_closest_player_position()
	_flip_to_target(target)
	_move_to_target(target, delta)
	_move_boss()


func set_enabled(value: bool) -> void:
	movement_enabled = value


func face_position(target: Vector2) -> void:
	_flip_to_target(target)


func _move_to_target(target: Vector2, delta: float) -> void:
	var to_target := target - boss.global_position
	if to_target.length() <= stop_distance:
		_set_boss_velocity(_get_boss_velocity().move_toward(Vector2.ZERO, acceleration * delta))
		return
	
	var target_dir := to_target.normalized()
	var desired_position := target - target_dir * hover_distance
	var approach := desired_position - boss.global_position
	var desired_velocity := Vector2.ZERO
	
	if approach.length() > stop_distance:
		desired_velocity = approach.normalized() * move_speed
	
	var tangent := Vector2(-target_dir.y, target_dir.x) * move_speed * orbit_weight * _orbit_dir
	desired_velocity += tangent
	_set_boss_velocity(_get_boss_velocity().move_toward(desired_velocity, acceleration * delta))


func _get_closest_player_position() -> Vector2:
	var closest_pos := boss.global_position
	var closest_dist := INF
	
	for target: Node2D in _get_combat_targets():
		var dist := boss.global_position.distance_to(target.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_pos = target.global_position
	
	return closest_pos


func _get_combat_targets() -> Array[Node2D]:
	var targets: Array[Node2D] = []
	
	for player_res: PlayerResource in GlobalGame.Players:
		if is_instance_valid(player_res.player):
			targets.append(player_res.player)
	
	for support: Node2D in GlobalGame.Player_Support:
		if is_instance_valid(support):
			targets.append(support)
	
	return targets


func _flip_to_target(target: Vector2) -> void:
	if not is_instance_valid(sprite):
		return
	
	var face_left := target.x < boss.global_position.x
	sprite.flip_h = face_left
	
	if is_instance_valid(scream_effect):
		scream_effect.flip_h = face_left
		scream_effect.position.x = -15 if face_left else 15
	
	if is_instance_valid(charge_effect):
		charge_effect.flip_h = face_left
		charge_effect.position.x = -15 if face_left else 15


func _get_boss_velocity() -> Vector2:
	var value = boss.get("velocity")
	if value is Vector2:
		return value
	return Vector2.ZERO


func _set_boss_velocity(value: Vector2) -> void:
	boss.set("velocity", value)


func _move_boss() -> void:
	if boss.has_method("move_and_slide"):
		boss.call("move_and_slide")
