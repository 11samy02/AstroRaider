extends Node

@export var enviroment: Enviroment

@export var entity_spawner: EntitySpawner

@export var tutorial: CanvasLayer

const PLAYER = preload("res://scenes/actors/player/player.tscn")
const ENTITY_SPAWNER_SCENE_PATH := "res://scenes/managers/spawner/EntitySpawner.tscn"
const ENVIROMENT_NODE_NAME := "Enviroment"
const ENTITY_SPAWNER_NODE_NAME := "EntitySpawner"

var game_started := false
var start_game_pending := false


func _ready() -> void:
	GlobalGame.time_played = 0
	enviroment = _resolve_enviroment()
	entity_spawner = _resolve_entity_spawner()
	
	if enviroment == null:
		push_error("MainGame: Enviroment node is not assigned and could not be found.")
		return
	
	if not enviroment.map_was_created.is_connected(start_Game):
		enviroment.map_was_created.connect(start_Game, CONNECT_DEFERRED)
	
	if enviroment.finished_map:
		call_deferred("start_Game")

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_B) and is_instance_valid(tutorial):
		tutorial.queue_free()

func start_Game() -> void:
	if game_started or start_game_pending:
		return
	
	entity_spawner = _resolve_entity_spawner()
	if entity_spawner == null:
		start_game_pending = true
		call_deferred("_start_game_when_ready")
		return
	
	_start_game()


func _start_game_when_ready() -> void:
	var retries := 0
	while retries < 3:
		await get_tree().process_frame
		entity_spawner = _resolve_entity_spawner()
		if entity_spawner != null:
			break
		retries += 1
	
	start_game_pending = false
	
	if game_started:
		return
	
	if entity_spawner == null:
		push_error("MainGame: EntitySpawner node is not assigned and could not be found.")
		return
	
	_start_game()


func _start_game() -> void:
	game_started = true
	
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


func _resolve_enviroment() -> Enviroment:
	if is_instance_valid(enviroment):
		return enviroment
	
	var node := get_node_or_null(ENVIROMENT_NODE_NAME)
	if node is Enviroment:
		return node
	
	node = find_child(ENVIROMENT_NODE_NAME, true, false)
	if node is Enviroment:
		return node
	
	return null


func _resolve_entity_spawner() -> EntitySpawner:
	if is_instance_valid(entity_spawner):
		return entity_spawner
	
	var spawner := _find_entity_spawner_in(self)
	if spawner != null:
		return spawner
	
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene != self:
		spawner = _find_entity_spawner_in(current_scene)
		if spawner != null:
			return spawner
	
	return _create_entity_spawner()


func _find_entity_spawner_in(root: Node) -> EntitySpawner:
	var node := root.get_node_or_null(ENTITY_SPAWNER_NODE_NAME)
	if node is EntitySpawner:
		return node
	
	node = root.find_child(ENTITY_SPAWNER_NODE_NAME, true, false)
	if node is EntitySpawner:
		return node
	
	return null


func _create_entity_spawner() -> EntitySpawner:
	var spawner_scene := load(ENTITY_SPAWNER_SCENE_PATH) as PackedScene
	if spawner_scene == null:
		push_error("MainGame: Could not load EntitySpawner scene.")
		return null
	
	var spawner := spawner_scene.instantiate() as EntitySpawner
	if spawner == null:
		push_error("MainGame: Could not instantiate EntitySpawner scene.")
		return null
	
	spawner.name = ENTITY_SPAWNER_NODE_NAME
	add_child(spawner)
	return spawner


func _process(delta: float) -> void:
	GlobalGame.time_played += delta
