extends CollectableTemplate
class_name ItemCrystal

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var rope: Line2D = $rope
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var value = 1

var is_collected = false
var player_who_collected: Player = null

var is_first_one = true

var velocity = Vector2.ZERO
var random_angle = 0.0  # Speichert den zufälligen Winkel

var spring_constant = 20.0      # Federkonstante
var damping_coefficient = 5.0   # Dämpfung
var desired_distance = 35.0     # Gewünschter Abstand zum Spieler
var mass = 1.0                  # Masse des Kristalls

var default_sprite := 0

func _ready() -> void:
	default_sprite = randi_range(0, 4)
	set_sprite()
	
	animation_player.play("spawn")
	mass = randf_range(0.8,2)
	desired_distance += randf_range(-10.0, 10.0)

func set_sprite() -> void:
	if value > 10:
		sprite.frame = default_sprite + 10
	elif value > 5:
		sprite.frame = default_sprite + 5
	else:
		sprite.frame = default_sprite

func collect(body: Node2D) -> void:
	if body is Player and !is_collected:
		is_collected = true
		player_who_collected = body
		
		var max_collect_count := 50
		
		if GlobalGame.Players.size() <= 2:
			max_collect_count = 50
		elif GlobalGame.Players.size() <= 4:
			max_collect_count = 30
		else:
			max_collect_count = 20
		
		if player_who_collected.collected_crystals.size() < max_collect_count:
			player_who_collected.collected_crystals.push_back(self)
		else:
			rope.hide()
			player_who_collected.clear_collected_null()
			var crystal = player_who_collected.collected_crystals.pick_random()
			if is_instance_valid(crystal):
				crystal.value += value
			animation_player.play("Collect")
		if is_first_one:
			GSignals.PERK_event_collect_crystal.emit(global_position)
			is_first_one = false
		
		collision_shape_2d.shape.radius = 20
		random_angle = deg_to_rad(randf_range(-5, 5)) 

func _process(delta: float) -> void:
	if is_collected and player_who_collected != null:
		# Aktualisiere das Seil
		rope.clear_points()
		rope.add_point(Vector2.ZERO)
		rope.add_point(rope.to_local(player_who_collected.global_position))
		set_sprite()
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

func destroy():
	rope.clear_points()
	set_physics_process(false)
	velocity = Vector2.ZERO
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.player == player_who_collected:
			player_who_collected.collected_crystals.erase(self)
			break
	animation_player.play("Collect")
