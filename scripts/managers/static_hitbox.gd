extends Area2D
class_name StaticHitbox

@export var entity : StaticEnemy


func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if entity.can_take_damage:
		entity.hp -= attack.damage
		await get_tree().create_timer(entity.valnuable_time)
