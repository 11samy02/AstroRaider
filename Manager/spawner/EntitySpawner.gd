extends Node
class_name EntitySpawner

@export var ENEMY : Array[EnemySpawnResource]

@onready var spawn_time: Timer = $spawn_time
@onready var wave_time: Timer = $wave_time

var rng = RandomNumberGenerator.new()

var wave_spawn_count := 0
static var wave_count := 0
static var wave_time_to_next := 0.00
static var wave_time_max_time := 0.00
static var wave_time_stopped := true
static var pause_time := 120

@export var spawn_per_round: SimplefySettingMath = SimplefySettingMath.new()
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

@export var wave_types : Array[WaveTypeResource]




func _ready() -> void:
	reset()

func start_wave():
	start_new_wave()

func _process(delta: float) -> void:
	wave_time_max_time = wave_time.wait_time
	wave_time_to_next = wave_time.wait_time - wave_time.time_left
	wave_time_stopped = wave_time.is_stopped()

func _on_wave_time_timeout() -> void:
	if EnemyBaseTemplate.entity_list.is_empty():
		start_new_wave()

func _on_spawn_time_timeout() -> void:
	if wave_spawn_count > 0 and EnemyBaseTemplate.entity_list.size() < EnemyBaseTemplate.max_entitys_on_screen:
		spawn_enemy()
	elif wave_spawn_count <= 0:
		if EnemyBaseTemplate.entity_list.is_empty() and wave_time.is_stopped():
			if !Manage_Wave_Types():
				wave_time.set_wait_time(rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value))
			wave_time.start()

func start_new_wave() -> void:
	GSignals.WAV_wave_endet.emit()
	wave_count += GlobalGame.wave_count_added_per_round
	wave_spawn_count = rng.randi_range(spawn_per_round.min_value + wave_count + GlobalGame.Players.size(), spawn_per_round.max_value + wave_count + GlobalGame.Players.size())
	spawn_time.start()

func spawn_enemy() -> void:
	randomize()
	var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
	var enemy_list : Array[PackedScene] = []
	
	for enemy_res in ENEMY:
		for i in enemy_res.rarity:
			enemy_list.append(enemy_res.Entity)
	
	var enemy = enemy_list.pick_random().instantiate()
	enemy.global_position = spawn_pos
	enemy.level = floori(wave_count/10)
	get_parent().add_child(enemy)
	EnemyBaseTemplate.entity_list.append(enemy)
	wave_spawn_count -= 1

func reset():
	wave_count = 0
	EnemyBaseTemplate.entity_list.clear()


func Manage_Wave_Types() -> bool:
	for wave_type_res : WaveTypeResource in wave_types:
		if wave_type_res.repeatable:
			if wave_count % wave_type_res.WaveStart == 0:
				return get_wave_type(wave_type_res)
			
		elif wave_count == wave_type_res.WaveStart:
			return get_wave_type(wave_type_res)
	return false

func get_wave_type(wave_type_res: WaveTypeResource) -> bool:
	var Types = WaveTypeResource.WaveTypeEnum
	if wave_type_res.WaveType == Types.Pause:
		wave_time.set_wait_time(pause_time)
		return true
	return false
