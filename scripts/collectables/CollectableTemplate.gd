extends Area2D
class_name CollectableTemplate

static var _magnetic_bonus_frame := -1
static var _magnetic_bonus_pct := 0

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
var is_destroying := false
var player_who_collected: Player = null
var is_first_one := true

var velocity := Vector2.ZERO
var random_angle := 0.0
var normal_distance := 35.0

var _base_pickup_radius := 0.0
var _has_magnetic_pickup_shape := false
var _last_applied_magnetic_pct := -1


func _ready() -> void:
	randomize_values()
	find_generator()
	_connect_magnetic_pull_signal()
	call_deferred("_cache_base_pickup_radius")


func _exit_tree() -> void:
	_disconnect_magnetic_pull_signal()


#region Setup

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


func _cache_base_pickup_radius() -> void:
	if not is_instance_valid(collision_shape_2d):
		return

	if not is_instance_valid(collision_shape_2d.shape):
		return

	if not collision_shape_2d.shape is CircleShape2D:
		return

	collision_shape_2d.shape = collision_shape_2d.shape.duplicate(true)

	var circle_shape := collision_shape_2d.shape as CircleShape2D
	_base_pickup_radius = circle_shape.radius
	_has_magnetic_pickup_shape = true

	_force_refresh_magnetic_pickup_radius()

#endregion


#region Magnetic Pull

func _connect_magnetic_pull_signal() -> void:
	if GSignals.PERK_magnetic_pull_changed.is_connected(_on_magnetic_pull_changed):
		return

	GSignals.PERK_magnetic_pull_changed.connect(_on_magnetic_pull_changed)


func _disconnect_magnetic_pull_signal() -> void:
	if not GSignals.PERK_magnetic_pull_changed.is_connected(_on_magnetic_pull_changed):
		return

	GSignals.PERK_magnetic_pull_changed.disconnect(_on_magnetic_pull_changed)


func _on_magnetic_pull_changed() -> void:
	if is_collected:
		return

	_force_refresh_magnetic_pickup_radius()


func _force_refresh_magnetic_pickup_radius() -> void:
	CollectableTemplate._magnetic_bonus_frame = -1
	_last_applied_magnetic_pct = -1
	_apply_magnetic_pickup_radius()


static func _magnetic_bonus_percent_for_frame() -> int:
	var frame := Engine.get_process_frames()

	if frame != _magnetic_bonus_frame:
		_magnetic_bonus_frame = frame
		_magnetic_bonus_pct = _compute_max_magnetic_bonus_percent()

	return _magnetic_bonus_pct


static func _compute_max_magnetic_bonus_percent() -> int:
	var best := 0

	for player_res: PlayerResource in GlobalGame.Players:
		if not is_instance_valid(player_res.player):
			continue

		best = maxi(best, _magnetic_bonus_for_player(player_res.player))

	return best


static func _magnetic_bonus_for_player(ply: Player) -> int:
	var best := 0

	if is_instance_valid(ply.perk_manager) and is_instance_valid(ply.perk_manager.perks_node):
		for child in ply.perk_manager.perks_node.get_children():
			if child is PerkBuild and child.Key == PerkData.Keys.Magnetic_Pull and child.selected_in_run:
				best = maxi(best, child.get_value())

	var parent := ply.get_parent()

	if is_instance_valid(parent):
		for child in parent.get_children():
			if child is PerkBuild and child.player == ply and child.Key == PerkData.Keys.Magnetic_Pull and child.selected_in_run:
				best = maxi(best, child.get_value())

	return best


func _apply_magnetic_pickup_radius() -> void:
	if not _has_magnetic_pickup_shape:
		return

	if not is_instance_valid(collision_shape_2d):
		return

	if not collision_shape_2d.shape is CircleShape2D:
		return

	var pct := _magnetic_bonus_percent_for_frame()

	if pct == _last_applied_magnetic_pct:
		return

	_last_applied_magnetic_pct = pct

	var circle_shape := collision_shape_2d.shape as CircleShape2D
	circle_shape.radius = _base_pickup_radius * (1.0 + float(pct) / 100.0)

#endregion


#region Collect

func collect(body: Node2D) -> void:
	if not body is Player:
		return

	if not _can_player_collect_now():
		return

	if is_collected:
		return

	is_collected = true
	player_who_collected = body

	if collision_shape_2d.shape is CircleShape2D:
		(collision_shape_2d.shape as CircleShape2D).radius = 20.0

	random_angle = deg_to_rad(randf_range(-5.0, 5.0))

	on_collected()


func on_collected() -> void:
	pass

#endregion


#region Process

func _process(delta: float) -> void:
	if not is_collected:
		_apply_magnetic_pickup_radius()
		_collect_overlapping_player_if_allowed()
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

#endregion


func _collect_overlapping_player_if_allowed() -> void:
	if not _can_player_collect_now():
		return

	for body in get_overlapping_bodies():
		if body is Player:
			collect(body)
			return


func _can_player_collect_now() -> bool:
	if not GlobalGame.is_in_tutorial or GlobalGame.tutorial == 1:
		return true

	if self is ItemCrystal:
		return GlobalGame.is_tutorial_action_allowed("collect_crystal")

	if self is OreTemplate:
		return (
			GlobalGame.is_tutorial_action_allowed("mining")
			or GlobalGame.is_tutorial_action_allowed("collect_crystal")
			or GlobalGame.is_tutorial_action_allowed("deliver_crystal")
			or GlobalGame.is_tutorial_action_allowed("select_building")
			or GlobalGame.is_tutorial_action_allowed("place_building")
			or GlobalGame.is_tutorial_action_allowed("salvage_building")
		)

	return true


#region Generator Attach

func should_attach_to_generator() -> bool:
	if is_attached_to_generator:
		return true

	if not is_instance_valid(generator):
		find_generator()

	if not is_instance_valid(generator):
		return false

	if not is_instance_valid(player_who_collected):
		return false

	if self is ItemCrystal and not GlobalGame.is_tutorial_action_allowed("deliver_crystal"):
		return false

	if generator.player_list.has(player_who_collected):
		return true

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

#endregion


#region Movement

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

#endregion


#region Custom Hooks

func update_custom_behavior(delta: float) -> void:
	pass


func destroy() -> void:
	if is_destroying:
		return

	is_destroying = true
	rope.clear_points()
	velocity = Vector2.ZERO
	on_destroy()


func on_destroy() -> void:
	pass

#endregion
