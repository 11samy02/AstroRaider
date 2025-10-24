extends Node

@export var enviroment : Enviroment

@onready var entity_spawner: EntitySpawner = $EntitySpawner
@onready var tutorial: CanvasLayer = $Tutorial

const PLAYER = preload("res://Actors/player/player.tscn")


func _enter_tree() -> void:
	enviroment.map_was_created.connect(start_Game)
	GlobalGame.time_played = 0
#
func _ready():
	var dir := "res://Levels/level1"
	if DirAccess.dir_exists_absolute(dir):
		var files := DirAccess.get_files_at(dir)  # Godot 4
		print("Files in level1:", files)
		print("Exists test:", ResourceLoader.exists(dir + "/new_planet_85956716.tscn"))
	else:
		print("Dir missing:", dir)


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_B) and is_instance_valid(tutorial):
		tutorial.queue_free()

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
	entity_spawner.start_wave()
	save_game()


func _process(delta: float) -> void:
	GlobalGame.time_played += delta


##muss geändert werden
func save_game():
	enviroment.Map_Size = Vector2.ZERO
	var game_file = PackedScene.new()
	game_file.pack(self)
	if not FileAccess.file_exists("user://saves"):
		DirAccess.make_dir_absolute("user://saves")
	ResourceSaver.save(game_file, "user://saves/game_1.tscn")
