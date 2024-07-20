extends Resource
class_name EnemyStats

@export var max_health: int = 10
@export var current_health: int = max_health
@export var attack: AttackResource = AttackResource.new()
@export var ai_type_keys: Array[AiTypeKeys]
@export var speed := 150.0
