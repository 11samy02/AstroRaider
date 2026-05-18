extends CPUParticles2D
class_name BombExplosion

@onready var static_attack_box: Area2D = $StaticAttackBox
@onready var collision_shape_2d: CollisionShape2D = $StaticAttackBox/CollisionShape2D

var damage: int = 1
var _hit_entity_ids := {}
var _shield_absorbed_player_ids := {}
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

	var s := collision_shape_2d.shape

	if s is CircleShape2D:
		s.radius = radius_px
	elif s is RectangleShape2D:
		s.size = Vector2(radius_px * 2.0, radius_px * 2.0)
	elif s is CapsuleShape2D:
		s.radius = radius_px

	amount = int(radius_px / 60.0 * 3.0)


func _on_static_attack_box_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return

	if not area is Hitbox:
		return

	var hitbox := area as Hitbox
	var target := hitbox.entity

	if not is_instance_valid(target):
		return

	var target_id := target.get_instance_id()
	if _hit_entity_ids.has(target_id):
		return

	var attack := AttackResource.new()
	attack.damage = damage
	attack.knockback = 10

	if target is Player:
		if hitbox is BarrierShield:
			_hit_entity_ids[target_id] = true
			_shield_absorbed_player_ids[target_id] = true

			var direct_shield_multiplier = target.get_active_shield_knockback_multiplier()
			var direct_shield_attack := _make_shield_attack(attack, direct_shield_multiplier)
			hitbox.get_hit(direct_shield_attack)
			GSignals.CAM_shake_effect.emit()

			var direct_shield_dir := target.global_position - global_position
			if direct_shield_dir != Vector2.ZERO:
				target.get_knockback(direct_shield_dir.normalized(), attack.knockback * direct_shield_multiplier)

			return

		var shield_multiplier = target.get_active_shield_knockback_multiplier()
		var shield_attack := _make_shield_attack(attack, shield_multiplier)
		if target.damage_active_barrier_shield(shield_attack):
			_hit_entity_ids[target_id] = true
			_shield_absorbed_player_ids[target_id] = true
			GSignals.CAM_shake_effect.emit()

			var shielded_dir := target.global_position - global_position
			if shielded_dir != Vector2.ZERO:
				target.get_knockback(shielded_dir.normalized(), attack.knockback * shield_multiplier)

			return

		var overlapping_shield := _get_overlapping_shield_for_player(target)
		if is_instance_valid(overlapping_shield):
			_hit_entity_ids[target_id] = true
			_shield_absorbed_player_ids[target_id] = true
			overlapping_shield.get_hit(shield_attack)
			GSignals.CAM_shake_effect.emit()

			var fallback_shield_dir := target.global_position - global_position
			if fallback_shield_dir != Vector2.ZERO:
				target.get_knockback(fallback_shield_dir.normalized(), attack.knockback * shield_multiplier)

			return

		if _shield_absorbed_player_ids.has(target_id):
			return

		if not target.can_take_damage:
			return

		_hit_entity_ids[target_id] = true
		hitbox.get_hit(attack)

		GSignals.CAM_shake_effect.emit()

		var dir := target.global_position - global_position
		if dir != Vector2.ZERO:
			target.get_knockback(dir.normalized(), attack.knockback)

		return

	if target is EnemyBaseTemplate:
		_hit_entity_ids[target_id] = true
		hitbox.get_hit(attack)

		var dir := target.global_position - global_position
		if dir != Vector2.ZERO:
			target.get_knockback(dir.normalized(), attack.knockback)

		return


func _get_overlapping_shield_for_player(player: Player) -> BarrierShield:
	for overlap_area in static_attack_box.get_overlapping_areas():
		if overlap_area is BarrierShield and overlap_area.entity == player:
			return overlap_area
	return null


func _make_shield_attack(source_attack: AttackResource, shield_multiplier: float) -> AttackResource:
	var shield_attack := source_attack.duplicate() as AttackResource
	shield_attack.damage = maxi(1, int(ceil(float(source_attack.damage) * shield_multiplier)))
	return shield_attack
