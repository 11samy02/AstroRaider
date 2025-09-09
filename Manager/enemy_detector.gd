extends Area2D
class_name EnemyDetectorArea

var Enemy_list : Array[EnemyBaseTemplate] = []
var Enemy_hit_list : Array[EnemyBaseTemplate] = []
@export var parent: PlayerProjectile
var value : float
var aim_bot_on : bool = false
var aim_locked : bool = false
var locked_dir : Vector2 = Vector2.ZERO

## Initializes signals when the node enters the tree
func _enter_tree() -> void:
	body_entered.connect(enemy_in_area)
	body_exited.connect(enemy_out_area)
	GSignals.PERK_Aim_bot_activate.connect(activate_aim_bot)

## Adds an enemy to the list if it has not been hit before
func enemy_in_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		if !Enemy_hit_list.has(body):
			Enemy_list.append(body)

## Removes an enemy from the list when it leaves the area
func enemy_out_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		if Enemy_list.has(body):
			Enemy_list.erase(body)

## Returns the position of the closest enemy
func get_closest_target_pos() -> Vector2:
	if Enemy_list.is_empty():
		return global_position
	var closest_dist := INF
	var closest_enemy : EnemyBaseTemplate = null
	for enemy in Enemy_list:
		if is_instance_valid(enemy):
			var d := global_position.distance_to(enemy.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_enemy = enemy
	return closest_enemy.global_position

## Updates the target aiming and locked flight behavior each frame
func _process(delta: float) -> void:
	if aim_locked:
		if locked_dir != Vector2.ZERO:
			parent.dir = locked_dir
		return
	if aim_bot_on:
		aim_to_target()

## Activates the aimbot for projectiles belonging to the given player
func activate_aim_bot(player: Player, new_value: float):
	if is_instance_valid(parent) and !aim_locked:
		if parent.player == player:
			value = new_value
			aim_bot_on = true

## Adjusts the projectile direction toward the closest valid enemy without losing speed
func aim_to_target() -> void:
	Enemy_list = Enemy_list.filter(func(e): return is_instance_valid(e) and !Enemy_hit_list.has(e))
	if Enemy_list.is_empty():
		return
	var target_dir := (get_closest_target_pos() - global_position).normalized()
	var t = clamp(value / 100.0, 0.0, 1.0)
	var new_angle := lerp_angle(parent.dir.angle(), target_dir.angle(), t)
	parent.dir = Vector2.RIGHT.rotated(new_angle).normalized()

## Marks an enemy as hit, removes it from tracking, and locks flight direction (no further tracking)
func mark_enemy_as_hit(enemy: EnemyBaseTemplate) -> void:
	if enemy == null:
		return
	if !Enemy_hit_list.has(enemy):
		Enemy_hit_list.append(enemy)
	if Enemy_list.has(enemy):
		Enemy_list.erase(enemy)
	if Enemy_list.is_empty():
		locked_dir = parent.dir.normalized()
		aim_locked = true
