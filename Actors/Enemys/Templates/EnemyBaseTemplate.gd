extends CharacterBody2D
class_name EnemyBaseTemplate

@export var stats: Array[EnemyStats] = [EnemyStats.new()]
var level := 0
var active_stats: EnemyStats = stats[level]

@export var sprite_variation: Array[Texture2D]

var state_mashine := AiEnemyData.state_mashine

@export var state := state_mashine.Follow

@onready var knockback_time: Timer = $Knockback_time


var last_state := state

static var max_entitys_on_screen = 80
static var entity_list: Array[EnemyBaseTemplate]

var killed_by : CharacterBody2D = null

func _enter_tree() -> void:
	clamp(level, 0, stats.size())
	GSignals.HIT_take_Damage.connect(applay_damage)
	active_stats = stats[level-1].duplicate()
	active_stats.max_health += randi_range(0, active_stats.max_Random_health_edit)
	active_stats.current_health = active_stats.max_health
	print(level)

func _ready() -> void:
	load_ai_to_node()


func load_ai_to_node():
	for type_data: AiTypeKeys in active_stats.ai_type_keys:
		var ai_init: Entity_Ai = AiEnemyData.load_ai(type_data.key).instantiate()
		ai_init.parent = self
		ai_init.state = type_data.state
		add_child(ai_init)

func get_closest_target() -> Vector2:
	if !GlobalGame.Players.is_empty():
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
	
	return global_position

func applay_damage(entity: CharacterBody2D, damage: int = 1) -> void:
	if entity == self:
		active_stats.current_health -= damage

func get_knockback(dir: Vector2, knockback: float = 1.0) -> void:
	if knockback_time.is_stopped():
		velocity = Vector2.ZERO
		knockback_time.start()
		velocity = dir * knockback * active_stats.speed * 2
		last_state = state
		state = state_mashine.Knockback



func reset_to_last_state() -> void:
	state = last_state

func check_health() -> void:
	if active_stats.current_health <= 0 and state != state_mashine.Knockback:
		death()

##should be overwritten if you want any effect on death
func death() -> void:
	if self in entity_list:
		entity_list.erase(self)
		GSignals.ENE_killed_by.emit(self)
	queue_free()


static func reset() -> void:
	entity_list.clear()
	GlobalGame.Players.clear()
