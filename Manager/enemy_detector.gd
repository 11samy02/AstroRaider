extends Area2D
class_name EnemyDetectorArea

var Enemy_list : Array[EnemyBaseTemplate] = []
@export var parent: PlayerProjectile
var value : float
var aim_bot_on : bool = false

func _enter_tree() -> void:
	body_entered.connect(enemy_in_area)
	body_exited.connect(enemy_out_area)
	GSignals.PERK_Aim_bot_activate.connect(activate_aim_bot)

func enemy_in_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		Enemy_list.append(body)

func enemy_out_area(body: Node2D) -> void:
	if body is EnemyBaseTemplate:
		if Enemy_list.has(body):
			Enemy_list.erase(body)


func get_closest_target_pos() -> Vector2:
	var closest_target = global_position.distance_to(Enemy_list[0].global_position)
	var target_pos = Enemy_list[0]
	
	for enemy in Enemy_list:
		if global_position.distance_to(enemy.global_position) < closest_target:
			closest_target = global_position.distance_to(enemy.global_position)
			target_pos = enemy
	
	return target_pos.global_position


func _process(delta: float) -> void:
	if aim_bot_on:
		aim_to_target()

func activate_aim_bot(new_value: float):
	value = new_value
	aim_bot_on = true

func aim_to_target() -> void:
	if !Enemy_list.is_empty():
		parent.dir = (get_closest_target_pos() - global_position).normalized()
