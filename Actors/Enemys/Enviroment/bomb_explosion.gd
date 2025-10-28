extends CPUParticles2D
class_name BombExplosion

@onready var static_attack_box = $StaticAttackBox
@onready var collision_shape_2d: CollisionShape2D = $StaticAttackBox/CollisionShape2D

var damage: int = 1
@export var radius_px: float = 0.0

func _ready() -> void:
	emitting = true
	_apply_radius_to_shape()

func set_radius_px(r: float) -> void:
	radius_px = r
	_apply_radius_to_shape()

func _apply_radius_to_shape() -> void:
	if not is_instance_valid(collision_shape_2d) or collision_shape_2d.shape == null:
		return
	var s = collision_shape_2d.shape
	if s is CircleShape2D:
		s.radius = radius_px
	elif s is RectangleShape2D:
		s.extents = Vector2(radius_px, radius_px)
	elif s is CapsuleShape2D:
		s.radius = radius_px
	elif s is WorldBoundaryShape2D:
		pass
	
	scale = Vector2(radius_px / 60.0, radius_px / 60.0)
	amount = int(radius_px * 10)



func _on_finished() -> void:
	static_attack_box.get_child(0).disabled = true
	queue_free()

func _on_static_attack_box_area_entered(area: Area2D) -> void:
	await (get_tree().create_timer(0.1).timeout)
	if is_instance_valid(area):
		if area is Hitbox:
			var attack := AttackResource.new()
			attack.damage = damage
			attack.knockback = 5
			if area.entity is Player:
				area.get_hit(attack)
				GSignals.CAM_shake_effect.emit()
			if area.entity is BarrierShield:
				area.get_hit(attack)
			if area.entity is EnemyBaseTemplate:
				area.get_hit(attack)
				var dir: Vector2 = (area.global_position - global_position).normalized()
				area.entity.get_knockback(dir, attack.knockback)
