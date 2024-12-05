extends Resource
class_name EnemyStats

@export var max_health: int = 10
@export var max_Random_health_edit: int = 0
@export var attack: AttackResource = AttackResource.new()
@export var ai_type_keys: Array[AiTypeKeys]
@export var speed := 150.0
@export var max_speed := 300.0

@export var projectile: PackedScene
@export var ranged_attack: AttackResource = AttackResource.new()
@export var default_crit_chance: float = 20.00

var current_health: int

func update_stats(upgrades: EnemyStats, level: int):
	max_health += upgrades.max_health * level
	max_Random_health_edit += upgrades.max_Random_health_edit * level
	attack.damage += upgrades.attack.damage * level
	attack.knockback += upgrades.attack.knockback * level
	attack.crit_chance += upgrades.attack.crit_chance * level
	default_crit_chance += upgrades.default_crit_chance * level
	speed += upgrades.speed * level
	ranged_attack.damage += upgrades.ranged_attack.damage * level
	ranged_attack.knockback += upgrades.ranged_attack.knockback * level
	ranged_attack.crit_chance += upgrades.ranged_attack.crit_chance * level
	
	clamp(speed,0, max_speed)
