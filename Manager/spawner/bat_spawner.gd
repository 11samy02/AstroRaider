extends Node

const ENEMY = [preload("res://Actors/Enemys/Small Enemys/bat.tscn"), preload("res://Actors/Enemys/Small Enemys/DemonEye.tscn")]

@onready var spawn_time: Timer = $spawn_time
@onready var wave_time: Timer = $wave_time


var rng = RandomNumberGenerator.new()


var wave_started := false
var wave_spawn_count := 2

var wave_count := 0


@export var spawn_per_round: SimplefySettingMath = SimplefySettingMath.new()
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

func _on_wave_time_timeout() -> void:
	wave_started = true
	wave_count += 1

func _on_spawn_time_timeout() -> void:
	randomize()
	if GlobalGame.entity_list.size() < GlobalGame.max_entitys_on_screen:
		if wave_started:
			if wave_spawn_count <= 0:
				wave_started = false
				wave_spawn_count = rng.randi_range(spawn_per_round.min_value + 1*(wave_count%10), spawn_per_round.max_value + 1*(wave_count%5))
				wave_time.set_wait_time(rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value))
				wave_time.start()
				return
			
			var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
			
			var target_pos: Vector2 = GlobalGame.Players.pick_random().player.global_position
			
			var enemy = ENEMY.pick_random().instantiate()
			enemy.global_position = spawn_pos
			
			get_parent().add_child(enemy)
			GlobalGame.entity_list.append(enemy)
			wave_spawn_count -= 1
