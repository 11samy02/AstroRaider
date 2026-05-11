extends Node
class_name EntitySpawner

@export var ENEMY: Array[EnemySpawnResource]
@export var round_types: Array[RoundType]

@export var spawn_per_round: SimplefySettingMath = SimplefySettingMath.new()
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

@onready var spawn_time: Timer = $spawn_time
@onready var wave_time: Timer = $wave_time

var rng := RandomNumberGenerator.new()

var wave_spawn_count := 0
var current_round: RoundType = null

static var wave_count := 0
static var wave_time_to_next := 0.0
static var wave_time_max_time := 0.0
static var wave_time_stopped := true
static var pause_time := 30
static var wave_count_added_per_round: int = 1
static var enemy_levels_after: int = 3

@export var local_wave_count := wave_count


func _ready() -> void:
	rng.randomize()
	#Dialogic.signal_event.connect(dialog_event)
	reset()


func start_wave() -> void:
	start_new_wave()


func _process(delta: float) -> void:
	if not GlobalGame.is_in_tutorial:
		wave_time_max_time = wave_time.wait_time
		wave_time_to_next = wave_time.wait_time - wave_time.time_left
		wave_time_stopped = wave_time.is_stopped()
		wave_count = local_wave_count
	else:
		wave_count = 1
		local_wave_count = 1


func _on_wave_time_timeout() -> void:
	if GlobalGame.is_in_tutorial:
		return
	
	if EnemyBaseTemplate.entity_list.is_empty():
		start_new_wave()


func _on_spawn_time_timeout() -> void:
	if current_round != null and current_round.is_break_round():
		return
	
	if wave_spawn_count > 0 and EnemyBaseTemplate.entity_list.size() < EnemyBaseTemplate.max_entitys_on_screen:
		spawn_enemy()
		return
	
	if wave_spawn_count <= 0:
		if EnemyBaseTemplate.entity_list.is_empty() and wave_time.is_stopped():
			_finish_current_round_and_start_break()


func start_new_wave() -> void:
	if GlobalGame.is_in_tutorial:
		return
	
	GSignals.WAV_wave_endet.emit()
	
	wave_count += wave_count_added_per_round
	local_wave_count = wave_count
	
	current_round = _get_round_type_for_wave(wave_count)
	
	var base_spawn_count := rng.randi_range(
		spawn_per_round.min_value + wave_count + GlobalGame.Players.size(),
		spawn_per_round.max_value + wave_count + GlobalGame.Players.size()
	)
	
	if current_round != null:
		wave_spawn_count = current_round.get_spawn_count(base_spawn_count, wave_count, GlobalGame.Players.size())
		current_round.on_round_started(self)
	else:
		wave_spawn_count = base_spawn_count
	
	if wave_spawn_count > 0:
		spawn_time.start()
	else:
		_finish_current_round_and_start_break()


func spawn_enemy(random_enemy: bool = true) -> void:
	var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
	var enemy_scene: PackedScene = null
	
	if not random_enemy:
		enemy_scene = _get_first_enemy_scene()
	elif current_round != null:
		enemy_scene = current_round.pick_enemy(ENEMY, rng)
	else:
		enemy_scene = _pick_random_enemy_scene()
	
	if enemy_scene == null:
		push_warning("EntitySpawner: No enemy scene found.")
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	if "level" in enemy:
		var bonus := 0
		if current_round != null:
			bonus = current_round.enemy_level_bonus
		
		enemy.level = floori(wave_count / enemy_levels_after) + bonus
	
	get_parent().add_child(enemy)
	EnemyBaseTemplate.entity_list.append(enemy)
	
	wave_spawn_count -= 1


func reset() -> void:
	local_wave_count = 0
	wave_count = 0
	wave_spawn_count = 0
	current_round = null
	EnemyBaseTemplate.entity_list.clear()


func _finish_current_round_and_start_break() -> void:
	if current_round != null:
		current_round.on_round_finished(self)
		
		if current_round.ends_run:
			return
	
	var wait_time := 0.0
	
	if current_round != null:
		wait_time = current_round.get_wait_time(rng)
	else:
		wait_time = rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value)
	
	wave_time.set_wait_time(wait_time)
	wave_time.start()


func _get_round_type_for_wave(wave: int) -> RoundType:
	var selected: RoundType = null
	
	for round_type: RoundType in round_types:
		if round_type == null:
			continue
		
		if not round_type.matches(wave):
			continue
		
		if selected == null or round_type.priority > selected.priority:
			selected = round_type
	
	return selected


func _pick_random_enemy_scene() -> PackedScene:
	var weighted_enemies: Array[PackedScene] = []
	
	for enemy_res: EnemySpawnResource in ENEMY:
		if enemy_res == null or enemy_res.Entity == null:
			continue
		
		for i in enemy_res.rarity:
			weighted_enemies.append(enemy_res.Entity)
	
	if weighted_enemies.is_empty():
		return null
	
	return weighted_enemies.pick_random()


func _get_first_enemy_scene() -> PackedScene:
	for enemy_res: EnemySpawnResource in ENEMY:
		if enemy_res != null and enemy_res.Entity != null:
			return enemy_res.Entity
	
	return null


func dialog_event(argument: String) -> void:
	if argument == "spawn_enemies":
		wave_spawn_count = 3
		
		for i in wave_spawn_count:
			spawn_enemy(false)
