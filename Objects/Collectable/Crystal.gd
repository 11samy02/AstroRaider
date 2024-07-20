extends CollectableTemplate
class_name ItemCrystal

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var sprite: Sprite2D = $Sprite2D

@export var value := 1

var is_collected := false
var player_who_collected: CharacterBody2D = null

var is_first_one := true

var speed := 50

func _ready() -> void:
	sprite.frame = randi_range(0,2)
	animation_player.play("spawn")


func collect(body: Node2D) -> void:
	is_collected = true
	player_who_collected = body
	if is_first_one:
		GSignals.PERK_event_collect_crystal.emit(global_position)

func _physics_process(delta: float) -> void:
	if is_collected and !player_who_collected == null:
		if global_position.distance_to(player_who_collected.global_position) > 10:
			translate((player_who_collected.global_position - global_position).normalized() * speed * delta)
		else:
			animation_player.play("Collect")
			
			for player_res: PlayerResource in GlobalGame.Players:
				if player_res.player == player_who_collected:
					player_res.crystal_count += value
			set_physics_process(false)
	
