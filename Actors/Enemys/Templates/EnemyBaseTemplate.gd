extends CharacterBody2D
class_name EnemyBaseTemplate

@export var stats: EnemyStats = EnemyStats.new()

var state_mashine := AiEnemyData.state_mashine

@export var state := state_mashine.Follow

@onready var knockback_time: Timer = $Knockback_time

var last_state := state

func _enter_tree() -> void:
	GSignals.HIT_take_Damage.connect(applay_damage)

func _ready() -> void:
	load_ai_to_node()

func load_ai_to_node():
	for type_data: AiTypeKeys in stats.ai_type_keys:
		var ai_init: Entity_Ai  = AiEnemyData.load_ai(type_data.key).instantiate()
		ai_init.parent = self
		ai_init.state = type_data.state
		add_child(ai_init)

func get_closest_target() -> Vector2:
	var player_pos: Array[Vector2]
	
	for player_res: PlayerResource in GlobalGame.Players:
		player_pos.append(player_res.player.global_position)
	
	var closest_distance := global_position.distance_to(player_pos[0])
	var current_pos := player_pos[0]
	
	for pos in player_pos:
		if global_position.distance_to(pos) < closest_distance:
			closest_distance = global_position.distance_to(pos)
			current_pos = pos
	
	return current_pos

func applay_damage(entity: CharacterBody2D, damage: int = 1) -> void:
	if entity == self:
		stats.current_health -= damage

func get_knockback(dir: Vector2, knockback: float = 1.0) -> void:
	if knockback_time.is_stopped():
		velocity = Vector2.ZERO
		knockback_time.start()
		velocity = dir * knockback * stats.speed
		last_state = state
		state = state_mashine.Knockback



func reset_to_last_state() -> void:
	state = last_state

func check_health() -> void:
	if stats.current_health <= 0:
		death()

##should be overwritten if you want any effect on death
func death() -> void:
	GlobalGame.entity_list.erase(self)
	queue_free()
