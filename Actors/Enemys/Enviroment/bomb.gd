extends StaticEnemy

const EXPLOSION = preload("res://Actors/Enemys/Enviroment/bomb_explosion.tscn")
@onready var sprite: AnimatedSprite2D = $sprite

@export var damage := 10

@onready var explosion_sound: Audio2D = $ExplosionSound

func _ready() -> void:
	can_take_damage = false

func _on_explode_time_timeout() -> void:
	hp -= 1

func _process(delta: float) -> void:
	if hp <= 0:
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
