extends Area2D
class_name Hitbox

@export var entity: CharacterBody2D = null



func get_hit(attack: AttackResource) -> void:
	GSignals.HIT_take_Damage.emit(entity, attack.damage)
