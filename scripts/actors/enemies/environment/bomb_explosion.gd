extends CPUParticles2D
class_name BombExplosion

@onready var static_attack_box = $StaticAttackBox
@onready var collision_shape_2d: CollisionShape2D = $StaticAttackBox/CollisionShape2D

var damage: int = 1
var _hit_entities: Array = []
@export var radius_px: float = 0.0

func _ready() -> void:
	emitting = true
	_apply_radius_to_shape()
	await get_tree().create_timer(lifetime + 0.1).timeout
	static_attack_box.get_child(0).disabled = true
	queue_free()

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
		s.size = Vector2(radius_px * 2, radius_px * 2)
	elif s is CapsuleShape2D:
		s.radius = radius_px
	amount = int(radius_px / 60.0 * 3)



func _on_static_attack_box_area_entered(area: Area2D) -> void:
	if is_instance_valid(area):
		if area is Hitbox:
			if _hit_entities.has(area.entity):
				return
			_hit_entities.append(area.entity)
			
			var attack := AttackResource.new()
			attack.damage = damage
			attack.knockback = 10
			if area.entity is Player:
				area.get_hit(attack)
				GSignals.CAM_shake_effect.emit()
				var dir = (area.entity.global_position - global_position).normalized()
				area.entity.get_knockback(dir, attack.knockback)
			if area.entity is EnemyBaseTemplate:
				area.get_hit(attack)
				var dir := (area.global_position - global_position).normalized()
				area.entity.get_knockback(dir, attack.knockback)
