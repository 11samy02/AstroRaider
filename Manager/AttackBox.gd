extends Area2D
class_name AttackBox

@export var owner_entity: EnemyBaseTemplate

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is Player:
			area.get_hit(owner_entity.stats.attack)
			GSignals.CAM_shake_effect.emit()
