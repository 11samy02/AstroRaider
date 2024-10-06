extends Node

@export var enviroment : Enviroment

@onready var entity_spawner: EntitySpawner = $EntitySpawner
@onready var perk_selector_check: Node = $PerkSelectorCheck

const PLAYER = preload("res://Actors/player/player.tscn")

func _enter_tree() -> void:
	enviroment.map_was_created.connect(start_Game)


func start_Game() -> void:
	var player_list = PlayerList.new()
	player_list.name = "player_list"
	add_child(player_list)

	var num_players = GlobalGame.Player_count
	var spacing = 8
	var player_width = 16
	var total_width = num_players * player_width + (num_players - 1) * spacing
	var start_x = -total_width / 2 + player_width / 2

	var i = 0
	for player_id in GlobalGame.Player_count:
		var player_instance = PLAYER.instantiate()
		var x_position = start_x + i * (player_width + spacing)
		player_instance.global_position = Vector2(x_position, 0)
		player_instance.player_id = player_id
		player_list.add_child(player_instance)
		i += 1

	player_list.set_players()
	perk_selector_check.set_player_Stats()

	entity_spawner.start_wave()
