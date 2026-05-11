extends RoundType
class_name RoundTypeSingleEnemy

@export var forced_enemy: EnemySpawnResource


func pick_enemy(enemy_pool: Array[EnemySpawnResource], rng: RandomNumberGenerator) -> PackedScene:
	if forced_enemy != null and forced_enemy.Entity != null:
		return forced_enemy.Entity
	
	return super.pick_enemy(enemy_pool, rng)
