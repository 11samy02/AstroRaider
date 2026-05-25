extends CollectableTemplate
class_name ItemCrystal

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@export var value := 1

var default_sprite := 0

func _ready() -> void:
	default_sprite = randi_range(0, 4)
	set_sprite()
	animation_player.play("spawn")
	super()

func set_sprite() -> void:
	if value > 10:
		sprite.frame = default_sprite + 10
	elif value > 5:
		sprite.frame = default_sprite + 5
	else:
		sprite.frame = default_sprite

func on_collected() -> void:
	var max_collect_count := 25

	if GlobalGame.Players.size() <= 2:
		max_collect_count = 20
	elif GlobalGame.Players.size() <= 4:
		max_collect_count = 15
	else:
		max_collect_count = 10

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

	GSignals.PLA_collects_crystal.emit()

func _process(delta: float) -> void:
	super(delta)
	if is_collected:
		set_sprite()

func on_destroy() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.player == player_who_collected:
			player_who_collected.collected_crystals.erase(self)
			break

	animation_player.play("Collect")
