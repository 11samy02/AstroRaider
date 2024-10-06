extends Area2D
class_name StaticAttackBox

@export var parent : BombExplosion


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		if area.entity is Player:
			area.get_hit(parent.damage)
			GSignals.CAM_shake_effect.emit()
		if area.entity is BarrierShield:
			area.get_hit(parent.damage)
