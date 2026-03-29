extends Area2D
class_name Hitbox

@export var entity: CharacterBody2D = null


## Applies damage, crit and knockback to the entity
func get_hit(attack: AttackResource, who_attacked: CharacterBody2D = null) -> void:
	if entity is EnemyBaseTemplate:
		entity.killed_by = who_attacked
		entity.stun_activated(attack)
	
	var final_damage := calculate_real_damage(attack.damage)
	
	if randf_range(0.0, 100.0) <= attack.crit_chance:
		final_damage *= 3
	
	GSignals.HIT_take_Damage.emit(entity, final_damage, 0.0)
	
	if entity is Player and is_instance_valid(who_attacked):
		var to_player := entity.global_position - who_attacked.global_position
		var attacker_vel := who_attacked.velocity if who_attacked is CharacterBody2D else Vector2.ZERO
		var dir: Vector2
		if attacker_vel.dot(to_player) < 0:
			dir = -attacker_vel.normalized()
		else:
			dir = to_player.normalized()
		var knockback_multiplier := 1.0
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == entity:
				if player_res.shield_res.has_shield:
					knockback_multiplier = player_res.shield_res.knockback_multiplier
				break
		entity.get_knockback(dir, attack.knockback * knockback_multiplier)


## Calculates real damage after armor reduction for players
func calculate_real_damage(damage: int) -> int:
	if entity is Player:
		return ceil(float(damage) / entity.stats.get_armor_total())
	return damage
