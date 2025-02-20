extends Area2D
class_name BuildingHitbox

@export var entity : Building

func _ready() -> void:
	if entity == null:
		printerr("Building is null, cant get hit")

func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if is_instance_valid(entity):
		if entity.has_health:
			entity.current_health -= attack.damage
			entity.get_hit()
