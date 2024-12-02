extends Area2D
class_name Hitbox

@export var entity: CharacterBody2D = null


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if entity is EnemyBaseTemplate:
		entity.killed_by = who_attacked
	GSignals.HIT_take_Damage.emit(entity, calculate_real_damage(attack.damage), attack.crit_chance)


func calculate_real_damage(damage: int) -> int:
	if entity is Player:
		var armor = entity.stats.armor
		
		return ceil(damage / armor)
	return damage
