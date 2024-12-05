extends CharacterBody2D
class_name EnemyBaseTemplate

const DIE_PARTICLE = preload("res://Particles/Enemys/small/Enemy_die_particle.tscn")
const DAMAGE_PARTICLE = preload("res://Visuel Feedback Tutorial/visuel_counter.tscn")

@onready var sprite: Sprite2D = $sprite


@export var stats: EnemyStats
@export var stats_upgrades: EnemyStats
var level := 0

@export var sprite_variation: Array[Texture2D]
@export var die_particle_variation: Array[Texture2D]
@export var radar_icon: Texture2D

var state_mashine := AiEnemyData.state_mashine

@export var state := state_mashine.Follow

@onready var knockback_time: Timer = $Knockback_time

@onready var death_sound: Audio2D = $Sounds/Death

@export_category("Sounds")
@export var Shoot_sound: Audio2D

var last_state := state

static var max_entitys_on_screen = 60
static var entity_list: Array[EnemyBaseTemplate]

var killed_by : CharacterBody2D = null

func _enter_tree() -> void:
	GlobalGame.Enemies.append(self)
	GSignals.HIT_take_Damage.connect(applay_damage)
	
	

func _ready() -> void:
	stats.update_stats(stats_upgrades, level)
	stats.max_health += randi_range(0, stats.max_Random_health_edit)
	stats.current_health = stats.max_health
	load_ai_to_node()



func load_ai_to_node():
	for type_data: AiTypeKeys in stats.ai_type_keys:
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

func applay_damage(entity: CharacterBody2D, damage: int = 1, crit_chance: float = 0.00) -> void:
	if entity == self:
		var is_critical_hit := false
		var random_num = randf_range(0.00,100.00)
		var damage_part = DAMAGE_PARTICLE.instantiate()
		if random_num <= stats.default_crit_chance + crit_chance:
			damage_part.text = str(damage*3)
			damage_part.color = Color("#ff5400")
			damage_part.global_position = self.global_position
			get_parent().add_child(damage_part)
			
			is_critical_hit = true
			stats.current_health -= damage * 3
			return
		
		damage_part.text = str(damage)
		damage_part.color = Color("#ffff00")
		damage_part.global_position = self.global_position
		get_parent().add_child(damage_part)
		
		stats.current_health -= damage

func get_knockback(dir: Vector2, knockback: float = 1.0) -> void:
	if knockback_time.is_stopped():
		velocity = Vector2.ZERO
		knockback_time.start()
		velocity = dir * knockback * stats.speed * 2
		last_state = state
		state = state_mashine.Knockback



func reset_to_last_state() -> void:
	state = last_state

func check_health() -> void:
	if stats.current_health <= 0 and state != state_mashine.Knockback:
		death()

##should be overwritten if you want any effect on death
func death() -> void:
	var particle = DIE_PARTICLE.instantiate()
	particle.global_position = global_position
	particle.sprite_variation = die_particle_variation
	particle.sprite_id = sprite_variation.find(sprite.texture)
	get_parent().add_child(particle)
	
	var real_sound:Audio2D = death_sound.duplicate()
	get_parent().add_child(real_sound)
	real_sound.play_sound()
	real_sound.global_position = self.global_position
	if self in entity_list:
		entity_list.erase(self)
		GSignals.ENE_killed_by.emit(killed_by)
	queue_free()


func _exit_tree() -> void:
	GlobalGame.Enemies.erase(self)


static func reset() -> void:
	entity_list.clear()
	GlobalGame.Players.clear()
