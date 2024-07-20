extends Node

const FIREBALL = preload("res://Projectiles/fire_ball.tscn")

@onready var fire_time: Timer = $fire_time
@onready var wave_time: Timer = $wave_time

var rng = RandomNumberGenerator.new()


var wave_started := false
var wave_fire_count := 2

@export var fire_per_round: SimplefySettingMath = SimplefySettingMath.new()
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

func _on_wave_time_timeout() -> void:
	wave_started = true


func _on_fire_time_timeout() -> void:
	if wave_started:
		if wave_fire_count <= 0:
			wave_started = false
			wave_fire_count = rng.randi_range(fire_per_round.min_value, fire_per_round.max_value)
			wave_time.set_wait_time(rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value))
			wave_time.start()
			return
		
		var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
		
		var target_pos: Vector2 = GlobalGame.Players.pick_random().player.global_position
		
		var fire_ball = FIREBALL.instantiate()
		fire_ball.global_position = spawn_pos
		fire_ball.dir = (target_pos - spawn_pos).normalized()
		
		get_parent().add_child(fire_ball)
		wave_fire_count -= 1
