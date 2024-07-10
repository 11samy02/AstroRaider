extends Area2D
class_name Hitbox

@onready var player: Node2D = null



func get_hit(attack: AttackResource) -> void:
	GSignals.PLA_take_damage.emit(player, attack.damage)
