extends Resource
class_name EnemyStats

@export var max_health: int = 10
@export var max_Random_health_edit: int = 0
@export var attack: AttackResource = AttackResource.new()
@export var ai_type_keys: Array[AiTypeKeys]
@export var speed := 150.0

@export var projectile: PackedScene
@export var ranged_attack: AttackResource = AttackResource.new()

var current_health: int
