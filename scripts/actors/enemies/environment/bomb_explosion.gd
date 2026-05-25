extends CPUParticles2D
class_name BombExplosion

@onready var static_attack_box: Area2D = $StaticAttackBox
@onready var collision_shape_2d: CollisionShape2D = $StaticAttackBox/CollisionShape2D

var damage: int = 1
var _hit_entity_ids := {}
@export var radius_px: float = 0.0
@export_range(0.0, 1.0, 0.01) var shield_damage_multiplier := 1.0
@export var max_shield_damage_per_hit := 25


func _ready() -> void:
	emitting = true
	_apply_radius_to_shape()
	await get_tree().create_timer(lifetime + 0.1).timeout
	_disable_attack_box()
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
	if not area is Hitbox:
		return

	var hitbox := area as Hitbox
	var target := hitbox.entity

	if not is_instance_valid(target):
		return

	# Deduplicate by target entity — covers both direct player hits and shield hits
	# that reference the same player entity. Also deduplicate the shield node itself
	# to block re-entry events caused by runtime shape resizing.
	var target_id := target.get_instance_id()
	var area_id := area.get_instance_id()

	if _hit_entity_ids.has(target_id) or _hit_entity_ids.has(area_id):
		return

	var attack := _make_base_attack()

	if target is Player:
		_hit_entity_ids[target_id] = true

		if target.has_active_barrier_shield():
			var shield := target.active_barrier_shield as BarrierShield
			if is_instance_valid(shield):
				# Also mark the shield area so resize-triggered re-entries are blocked
				_hit_entity_ids[shield.get_instance_id()] = true

				var shield_attack := _make_shield_attack(attack)
				var shield_hp_before := shield.Health
				shield.get_hit(shield_attack)
				GSignals.CAM_shake_effect.emit()

				# Pass overflow damage to player if shield broke under the hit
				var actual_shield_damage := shield_hp_before - maxi(shield.Health, 0)
				var overflow := maxi(shield_attack.damage - actual_shield_damage, 0)

				if overflow > 0 and target.can_take_damage:
					var overflow_attack := attack.duplicate() as AttackResource
					overflow_attack.damage = overflow
					hitbox.get_hit(overflow_attack)

				_apply_player_knockback(target, attack.knockback * target.get_active_shield_knockback_multiplier())
			return

		if not target.can_take_damage:
			return

		hitbox.get_hit(attack)
		GSignals.CAM_shake_effect.emit()
		_apply_player_knockback(target, attack.knockback)
		return

	# BarrierShield area arrived before the player hitbox — mark both the shield
	# and its owner so neither fires again, then apply the hit via the shield.
	if hitbox is BarrierShield:
		var shield := hitbox as BarrierShield
		if not is_instance_valid(shield.entity):
			return

		var player := shield.entity as Player
		if not is_instance_valid(player):
			return

		_hit_entity_ids[area_id] = true
		_hit_entity_ids[player.get_instance_id()] = true

		var shield_attack := _make_shield_attack(attack)
		var shield_hp_before := shield.Health
		shield.get_hit(shield_attack)
		GSignals.CAM_shake_effect.emit()

		var actual_shield_damage := shield_hp_before - maxi(shield.Health, 0)
		var overflow := maxi(shield_attack.damage - actual_shield_damage, 0)

		if overflow > 0 and player.can_take_damage:
			var player_hitbox := _find_player_hitbox(player)
			if is_instance_valid(player_hitbox):
				var overflow_attack := attack.duplicate() as AttackResource
				overflow_attack.damage = overflow
				player_hitbox.get_hit(overflow_attack)

		_apply_player_knockback(player, attack.knockback * player.get_active_shield_knockback_multiplier())
		return

	if target is EnemyBaseTemplate:
		_hit_entity_ids[target_id] = true
		hitbox.get_hit(attack)

		var dir := target.global_position - global_position
		if dir != Vector2.ZERO:
			target.get_knockback(dir.normalized(), attack.knockback)


## Finds the non-shield Hitbox of a player for overflow damage delivery
func _find_player_hitbox(player: Player) -> Hitbox:
	for child in player.get_children():
		if child is Hitbox and not child is BarrierShield:
			return child as Hitbox
	return null


func _make_base_attack() -> AttackResource:
	var attack := AttackResource.new()
	attack.damage = damage
	attack.knockback = 10
	return attack


func _make_shield_attack(source_attack: AttackResource) -> AttackResource:
	var shield_attack := source_attack.duplicate() as AttackResource
	var raw_shield_damage := int(ceil(float(source_attack.damage) * shield_damage_multiplier))
	shield_attack.damage = clampi(raw_shield_damage, 1, max_shield_damage_per_hit)
	return shield_attack


func _apply_player_knockback(player: Player, strength: float) -> void:
	var dir := player.global_position - global_position
	if dir != Vector2.ZERO:
		player.get_knockback(dir.normalized(), strength)


func _disable_attack_box() -> void:
	static_attack_box.set_deferred("monitoring", false)
	if is_instance_valid(collision_shape_2d):
		collision_shape_2d.set_deferred("disabled", true)
