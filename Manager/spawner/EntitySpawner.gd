extends Node
class_name EntitySpawner

const ENEMY = [
	preload("res://Actors/Enemys/Small Enemys/bat.tscn"),
	preload("res://Actors/Enemys/Small Enemys/DemonEye.tscn")
]

@onready var spawn_time: Timer = $spawn_time
@onready var wave_time: Timer = $wave_time

var rng = RandomNumberGenerator.new()

var wave_spawn_count := 0
static var wave_count := 0

@export var spawn_per_round: SimplefySettingMath = SimplefySettingMath.new()
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

func _ready() -> void:
	reset()
	start_new_wave()

func _on_wave_time_timeout() -> void:
	if EnemyBaseTemplate.entity_list.is_empty():
		start_new_wave()

func _on_spawn_time_timeout() -> void:
	if wave_spawn_count > 0 and EnemyBaseTemplate.entity_list.size() < EnemyBaseTemplate.max_entitys_on_screen:
		spawn_enemy()
	elif wave_spawn_count <= 0:
		if EnemyBaseTemplate.entity_list.is_empty() and wave_time.is_stopped():
			wave_time.set_wait_time(rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value))
			wave_time.start()

func start_new_wave() -> void:
	GSignals.WAV_wave_endet.emit()
	wave_count += 1
	wave_spawn_count = rng.randi_range(spawn_per_round.min_value + wave_count + GlobalGame.Players.size(), spawn_per_round.max_value + wave_count + GlobalGame.Players.size())
	spawn_time.start()

func spawn_enemy() -> void:
	randomize()
	var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
	var enemy = ENEMY.pick_random().instantiate()
	enemy.global_position = spawn_pos
	enemy.level = floori(wave_count/10)
	get_parent().add_child(enemy)
	EnemyBaseTemplate.entity_list.append(enemy)
	wave_spawn_count -= 1

func reset():
	wave_count = 0
	EnemyBaseTemplate.entity_list.clear()
