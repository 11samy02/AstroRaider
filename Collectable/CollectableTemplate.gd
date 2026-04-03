extends Area2D
class_name CollectableTemplate

@export var collectable_name := ""

@export var spring_constant := 25.0
@export var damping_coefficient := 5.0
@export var desired_distance := 35.0
@export var mass := 1.0

@export var auto_move_to_generator_distance := 25.0
@export var generator_move_speed := 200.0

@onready var rope: Line2D = $rope
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

static var generator: CrystalGenerator = null

var is_collected := false
var is_attached_to_generator := false
var player_who_collected: Player = null
var is_first_one := true

var velocity := Vector2.ZERO
var random_angle := 0.0
var normal_distance := 35.0

func _ready() -> void:
	randomize_values()
	find_generator()

func randomize_values() -> void:
	mass += randf_range(-0.5, 0.5)
	desired_distance += randf_range(-20.0, 20.0)
	spring_constant += randf_range(-10.0, 10.0)
	damping_coefficient += randf_range(-2.0, 5.0)
	normal_distance = desired_distance

func find_generator() -> void:
	if is_instance_valid(generator):
		return

	for building in GlobalGame.Buildings:
		if building is CrystalGenerator:
			generator = building
			return

func collect(body: Node2D) -> void:
	if not body is Player:
		return
	if is_collected:
		return

	is_collected = true
	player_who_collected = body
	collision_shape_2d.shape.radius = 20
	random_angle = deg_to_rad(randf_range(-5.0, 5.0))

	on_collected()

func on_collected() -> void:
	pass

func _process(delta: float) -> void:
	if not is_collected:
		return
	if not is_instance_valid(player_who_collected):
		return

	if should_attach_to_generator():
		is_attached_to_generator = true

	if is_attached_to_generator:
		update_rope_to_generator()
		move_to_generator(delta)
	else:
		update_rope_to_player()
		update_follow_physics(delta)

	update_custom_behavior(delta)

func should_attach_to_generator() -> bool:
	if is_attached_to_generator:
		return true
	if not is_instance_valid(generator):
		return false
	return player_who_collected.global_position.distance_to(generator.global_position) <= auto_move_to_generator_distance

func update_rope_to_player() -> void:
	rope.clear_points()
	rope.add_point(Vector2.ZERO)
	rope.add_point(rope.to_local(player_who_collected.global_position))

func update_rope_to_generator() -> void:
	if not is_instance_valid(generator):
		return
	rope.clear_points()
	rope.add_point(Vector2.ZERO)
	rope.add_point(rope.to_local(generator.global_position))

func update_follow_physics(delta: float) -> void:
	var to_player := player_who_collected.global_position - global_position
	var direction := to_player.normalized()
	var rotated_direction := direction.rotated(random_angle)

	var desired_position := player_who_collected.global_position - rotated_direction * desired_distance
	var displacement := global_position - desired_position

	var spring_force := -spring_constant * displacement
	var damping_force := -damping_coefficient * velocity
	var total_force := spring_force + damping_force

	velocity += (total_force / mass) * delta
	position += velocity * delta

func move_to_generator(delta: float) -> void:
	if not is_instance_valid(generator):
		return

	velocity = Vector2.ZERO
	var direction := generator.global_position - global_position
	if direction.length() > 0.001:
		global_position += direction.normalized() * generator_move_speed * delta

func update_custom_behavior(delta: float) -> void:
	pass

func destroy() -> void:
	rope.clear_points()
	velocity = Vector2.ZERO
	on_destroy()

func on_destroy() -> void:
	pass
