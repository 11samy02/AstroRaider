extends CharacterBody2D
class_name EnemyBaseTemplate

const DIE_PARTICLE = preload("res://Particles/Enemys/small/Enemy_die_particle.tscn")
const DAMAGE_PARTICLE = preload("res://Visuel Feedback Tutorial/visuel_counter.tscn")

@onready var sprite: Sprite2D = $sprite
@onready var stun_sprite: Sprite2D = %stun_sprite
@onready var stun_timer: Timer = %Stun_Timer
@onready var knockback_time: Timer = $Knockback_time
@onready var death_sound: Audio2D = $Sounds/Death

@export var stats: EnemyStats
@export var stats_upgrades: EnemyStatsUpgrade
@export_category("Sounds")
@export var Shoot_sound: Audio2D
@export var sprite_variation: Array[Texture2D]
@export var die_particle_variation: Array[Texture2D]
@export var radar_icon: Texture2D

var level := 0
var state_mashine := AiEnemyData.state_mashine
@export var state := state_mashine.Follow
var last_state := state
var killed_by: CharacterBody2D = null
var shader_value: float = 0.0

var _cached_target: Vector2 = Vector2.ZERO
var _target_cache_frame: int = -1

static var max_entitys_on_screen = 50
static var entity_list: Array[EnemyBaseTemplate]


func _enter_tree() -> void:
	GlobalGame.Enemies.append(self)
	GSignals.HIT_take_Damage.connect(applay_damage)


func _ready() -> void:
	stats.update_stats(stats_upgrades, level)
	stats.max_health += randi_range(0, stats.max_Random_health_edit)
	stats.current_health = stats.max_health
	stats._sync_ai_flags()
	load_ai_to_node()
	sprite.texture = sprite_variation.pick_random()
	stun_timer.timeout.connect(remove_stun)


func _process(_delta: float) -> void:
	look_direction()
	check_if_stunned()


## Instantiates and attaches AI behavior nodes from stats configuration
func load_ai_to_node() -> void:
	for type_data: AiTypeKeys in stats.ai_type_keys:
		var ai_init: Entity_Ai = AiEnemyData.load_ai(type_data.key).instantiate()
		add_child(ai_init)
		ai_init.parent = self
		ai_init.state = type_data.state


## Returns the closest target position, cached per frame to avoid redundant iterations
func get_closest_target() -> Vector2:
	if Engine.get_process_frames() == _target_cache_frame:
		return _cached_target
	_target_cache_frame = Engine.get_process_frames()

	if GlobalGame.Players.is_empty():
		return global_position

	var positions: Array[Vector2] = []
	for player_res: PlayerResource in GlobalGame.Players:
		positions.append(player_res.player.global_position)
	for build: Building in GlobalGame.Buildings:
		if build.has_health:
			positions.append(build.global_position)

	var closest_pos := positions[0]
	var closest_dist := global_position.distance_to(closest_pos)
	for pos in positions:
		var d := global_position.distance_to(pos)
		if d < closest_dist:
			closest_dist = d
			closest_pos = pos

	_cached_target = closest_pos
	return _cached_target


## Applies damage with crit chance calculation and spawns damage particle
func applay_damage(entity: CharacterBody2D, damage: int = 1, crit_chance: float = 0.00) -> void:
	if entity != self:
		return
	var random_num := randf_range(0.00, 100.00)
	var damage_part = DAMAGE_PARTICLE.instantiate()
	get_parent().add_child(damage_part)
	damage_part.global_position = global_position
	if random_num <= stats.default_crit_chance + crit_chance:
		damage_part.setup(str(damage * 3), Color("#ff5400"))
		stats.current_health -= damage * 3
		return
	damage_part.setup(str(damage), Color("#ffff00"))
	stats.current_health -= damage


## Applies knockback force and switches to Knockback state
func get_knockback(dir: Vector2, knockback: float = 1.0) -> void:
	if knockback_time.is_stopped():
		velocity = Vector2.ZERO
		knockback_time.start()
		velocity = dir * knockback * stats.speed * 2
		last_state = state
		state = state_mashine.Knockback


## Resets state to the state before knockback
func reset_to_last_state() -> void:
	state = last_state


## Triggers death if health is zero and not in knockback state
func check_health() -> void:
	if stats.current_health <= 0 and state != state_mashine.Knockback:
		death()


## Handles death — spawns particles, plays sound, emits signal and frees the node
func death() -> void:
	var particle = DIE_PARTICLE.instantiate()
	particle.global_position = global_position
	particle.sprite_variation = die_particle_variation
	particle.sprite_id = sprite_variation.find(sprite.texture)
	get_parent().add_child(particle)
	var real_sound: Audio2D = death_sound.duplicate()
	get_parent().add_child(real_sound)
	real_sound.play_sound()
	real_sound.global_position = global_position
	if self in entity_list:
		entity_list.erase(self)
		GSignals.ENE_killed_by.emit(killed_by)
	queue_free()


func _exit_tree() -> void:
	GlobalGame.Enemies.erase(self)


static func reset() -> void:
	entity_list.clear()
	GlobalGame.Players.clear()


## Flips sprite based on target direction
func look_direction() -> void:
	sprite.flip_h = get_closest_target().x < global_position.x


## Plays hit animation with scale and shader flash
func get_hit_anim() -> void:
	var tween := create_tween()
	shader_value = 1
	sprite.scale = Vector2(1.5, 1.5)
	tween.tween_property(self, "shader_value", 0, 0.2)
	tween.parallel().tween_property(sprite, "scale", Vector2(1, 1), 0.2)


## Shows or hides stun sprite and freezes velocity when stunned
func check_if_stunned() -> void:
	if stats.is_stunned:
		velocity = Vector2.ZERO
		stun_sprite.show()
	else:
		stun_sprite.hide()


## Activates stun if attack has stun and enemy is not already stunned
func stun_activated(atk_res: AttackResource) -> void:
	if atk_res.has_stun and !stats.is_stunned:
		stats.is_stunned = true
		stun_timer.set_wait_time(atk_res.stun_strength / stats.stun_resistence)
		stun_timer.start()


## Removes stun state when stun timer ends
func remove_stun() -> void:
	stats.is_stunned = false
