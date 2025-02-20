extends Area2D
class_name OreTemplate

enum Ores {
	Iron,
	Copper,
	Gold,
}

@export var Ore_type := Ores.Iron

@onready var sprite: Sprite2D = $Sprite2D
@onready var rope: Line2D = $rope
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer


var is_collected := false
var player_who_collected: Player = null

var is_first_one := true

var velocity := Vector2.ZERO
var random_angle := 0.0  

var spring_constant := 20.0      # Federkonstante
var damping_coefficient := 5.0   # Dämpfung
var desired_distance := 35.0     # Gewünschter Abstand zum Spieler

var normal_distance := 35.0
var reduce_distance := 0.0

@export var mass = 1                 

func _ready() -> void:
	anim.play("Appear")
	mass += randf_range(-0.5,0.5)
	desired_distance += randf_range(-20,20)
	normal_distance = desired_distance

func collect(body: Node2D) -> void:
	if body is Player and !is_collected:
		is_collected = true
		player_who_collected = body
		
		
		collision_shape_2d.shape.radius = 20  
		random_angle = deg_to_rad(randf_range(-5, 5))  

func _process(delta: float) -> void:
	if is_collected and player_who_collected != null:
		rope.clear_points()
		rope.add_point(Vector2.ZERO)
		rope.add_point(rope.to_local(player_who_collected.global_position))
		
		var to_player = player_who_collected.global_position - global_position
		var direction = to_player.normalized()
		var rotated_direction = direction.rotated(random_angle)
		
		var desired_position = player_who_collected.global_position - rotated_direction * desired_distance
		var displacement = global_position - desired_position
		
		var spring_force = -spring_constant * displacement
		var damping_force = -damping_coefficient * velocity
		var total_force = spring_force + damping_force
		
		velocity += (total_force / mass) * delta
		position += velocity * delta
		
		if GlobalGame.Player_count <= 1:
			if Input.is_action_pressed("pull_collected") or Input.is_joy_button_pressed(player_who_collected.controller_id, JOY_BUTTON_LEFT_SHOULDER):
				rope.set_modulate("#4898ff")
				reduce_distance += 25 * delta
			else:
				rope.set_modulate("#ffc400")
			
			if desired_distance >= 2:
				desired_distance = normal_distance - reduce_distance
		else:
			if Input.is_joy_button_pressed(player_who_collected.controller_id, JOY_BUTTON_LEFT_SHOULDER):
				rope.set_modulate("#4898ff")
				reduce_distance += 25 * delta
			else:
				rope.set_modulate("#ffc400")
			
			if desired_distance >= 2:
				desired_distance = normal_distance - reduce_distance

func destroy():
	rope.clear_points()
	set_physics_process(false)
	velocity = Vector2.ZERO
	anim.play("Clear")
