extends Area2D
class_name Hitbox

@onready var entity: Node2D = null



func get_hit(attack: AttackResource) -> void:
	GSignals.HIT_take_Damage.emit(entity, attack.damage)
