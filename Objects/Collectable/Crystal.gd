extends CollectableTemplate
class_name ItemCrystal

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var rope: Line2D = $rope
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var value = 1

var is_collected = false
var player_who_collected: CharacterBody2D = null

var is_first_one = true

var velocity = Vector2.ZERO
var random_angle = 0.0  # Speichert den zufälligen Winkel

var spring_constant = 20.0      # Federkonstante
var damping_coefficient = 5.0   # Dämpfung
var desired_distance = 35.0     # Gewünschter Abstand zum Spieler
var mass = 1.0                  # Masse des Kristalls

func _ready() -> void:
	sprite.frame = randi_range(0, 2)
	animation_player.play("spawn")

func collect(body: Node2D) -> void:
	is_collected = true
	player_who_collected = body
	if is_first_one:
		GSignals.PERK_event_collect_crystal.emit(global_position)
		is_first_one = false

	collision_shape_2d.shape.radius = 5  # Verkleinere den Kollisionsradius
	random_angle = deg_to_rad(randf_range(-5, 5))  # Berechne den zufälligen Winkel einmal

func _process(delta: float) -> void:
	if is_collected and player_who_collected != null:
		# Aktualisiere das Seil
		rope.clear_points()
		rope.add_point(Vector2.ZERO)
		rope.add_point(rope.to_local(player_who_collected.global_position))

		# Berechne die Richtung zum Spieler in jedem Frame
		var to_player = player_who_collected.global_position - global_position
		var direction = to_player.normalized()
		# Rotierte Richtung unter Verwendung des zuvor berechneten zufälligen Winkels
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
			player_res.crystal_count += value
			break
	animation_player.play("Collect")
