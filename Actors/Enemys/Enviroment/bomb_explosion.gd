extends CPUParticles2D
class_name BombExplosion

@onready var static_attack_box = $StaticAttackBox

var damage : int = 1


func _ready() -> void:
	emitting = true

func _on_finished() -> void:
	static_attack_box.get_child(0).disabled = true
	queue_free()


func _on_static_attack_box_area_entered(area: Area2D) -> void:
	await(get_tree().create_timer(0.1).timeout)
	if is_instance_valid(area):
		if area is Hitbox:
			var attack := AttackResource.new()
			attack.damage = damage
			attack.knockback = 0
			if area.entity is Player:
				area.get_hit(attack)
				GSignals.CAM_shake_effect.emit()
			if area.entity is BarrierShield:
				area.get_hit(attack)
