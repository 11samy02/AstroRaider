extends Area2D
class_name Hitbox

@export var entity: CharacterBody2D = null


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if entity is EnemyBaseTemplate:
		entity.killed_by = who_attacked
	GSignals.HIT_take_Damage.emit(entity, attack.damage)
