extends StaticEnemy
class_name Bomb

const EXPLOSION = preload("res://Actors/Enemys/Enviroment/bomb_explosion.tscn")
@onready var sprite: AnimatedSprite2D = $sprite

@export var damage := 10

@onready var explosion_sound: Audio2D = $ExplosionSound
@onready var tiles_detector: Node2D = $TilesDetector

var grid_size := 16
@export var detector_count := 7
@export var detector : PackedScene


func _ready() -> void:
	can_take_damage = false
	hp += randi_range(-2,2)
	
	for i in detector_count * detector_count:
		var detector_instance = detector.instantiate()
		tiles_detector.add_child(detector_instance)

func _on_explode_time_timeout() -> void:
	hp -= 1

func _process(delta: float) -> void:
	var index = 0
	var radius = ceil(detector_count / 2) * grid_size
	for i in tiles_detector.get_children():
		var start_x = index % detector_count - detector_count / 2
		var start_y = index / detector_count - detector_count / 2
		var offset = Vector2(grid_size * start_x, grid_size * start_y)
		
		if offset.length() <= radius:
			i.global_position = (self.global_position + offset).snapped(Vector2(grid_size / 2, grid_size / 2))
		
		index += 1
	
	if hp <= 0:
		check_for_tile_points()
		await get_tree().process_frame
		death()



func death():
	var explosion: BombExplosion = EXPLOSION.instantiate()
	explosion.global_position = global_position
	explosion.damage = damage
	get_parent().add_child(explosion)
	
	var real_sound:Audio2D = explosion_sound.duplicate()
	get_parent().add_child(real_sound)
	real_sound.global_position = self.global_position
	real_sound.play_sound()
	
	super()


func _on_initiate_time_timeout() -> void:
	can_take_damage = true


func check_for_tile_points():
	var all_collision_pos :Array[Vector2]= []
	
	for i:SingleDetector in tiles_detector.get_children():
		if i.has_detected:
			all_collision_pos.append(i.global_position)
	
	
	GSignals.ENV_destroy_tile.emit(all_collision_pos, damage * 100)
	GSignals.CAM_shake_effect.emit()

static func reset() -> void:
	pass
