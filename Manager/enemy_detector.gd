extends Area2D
class_name EnemyDetectorArea

var Enemy_list: Array[EnemyBaseTemplate] = []
var Enemy_hit_list: Array[EnemyBaseTemplate] = []

@export var parent: PlayerProjectile

var value: float
var aim_bot_on: bool = false
var aim_locked: bool = false
var locked_dir: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	body_entered.connect(enemy_in_area)
	body_exited.connect(enemy_out_area)
	GSignals.PERK_Aim_bot_activate.connect(activate_aim_bot)


func enemy_in_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		if !Enemy_hit_list.has(body) and !Enemy_list.has(body):
			Enemy_list.append(body)


func enemy_out_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		if Enemy_list.has(body):
			Enemy_list.erase(body)


func get_closest_target_pos() -> Vector2:
	if Enemy_list.is_empty():
		return global_position

	var closest_dist := INF
	var closest_enemy: EnemyBaseTemplate = null

	for enemy in Enemy_list:
		if is_instance_valid(enemy):
			var d := global_position.distance_squared_to(enemy.global_position)
			if d < closest_dist:
				closest_dist = d
				closest_enemy = enemy

	if closest_enemy == null:
		return global_position

	return closest_enemy.global_position


func _process(_delta: float) -> void:
	if aim_locked:
		if locked_dir != Vector2.ZERO:
			parent.dir = locked_dir
		return

	if aim_bot_on:
		aim_to_target()


func activate_aim_bot(player: Player, new_value: float) -> void:
	if is_instance_valid(parent) and !aim_locked:
		if parent.player == player:
			value = new_value
			aim_bot_on = true


func aim_to_target() -> void:
	for i in range(Enemy_list.size() - 1, -1, -1):
		var e := Enemy_list[i]
		if !is_instance_valid(e) or Enemy_hit_list.has(e):
			Enemy_list.remove_at(i)
	if Enemy_list.is_empty():
		return

	var target_pos := get_closest_target_pos()
	var target_dir := (target_pos - global_position).normalized()
	var dist := global_position.distance_to(target_pos)

	if dist < 40.0:
		parent.dir = target_dir
		return

	var max_turn := deg_to_rad(value * 0.1)
	var current_angle := parent.dir.angle()
	var target_angle := target_dir.angle()
	var angle_diff := wrapf(target_angle - current_angle, -PI, PI)
	var step = clamp(angle_diff, -max_turn, max_turn)
	var new_angle = current_angle + step
	parent.dir = Vector2.RIGHT.rotated(new_angle).normalized()
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
