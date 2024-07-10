extends Area2D


@export var atk_resource: AttackResource = AttackResource.new()


func _on_area_entered(area: Hitbox) -> void:
	area.get_hit(atk_resource)
