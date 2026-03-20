extends TileMapLayer
class_name Enviroment

@export_enum("Disabled", "GenerateAndSave", "LoadSaved", "LoadRandom")
var persistence_mode: int = 0

@export var saved_dir: String = "res://Levels/level1"
@export var saved_file_prefix: String = "generated_level_"
@export var use_seed_in_filename: bool = true

static var max_tiles_to_generate = 0
static var tiles_generated = 0

@export var chunk_size: Vector2i = Vector2i(50, 50)
@export var Map_Size: Vector2i = Vector2i(200, 200)
var seed: int

@export var batch_size = 400

@export_group("Rooms Settings")
@export var start_area_size: SimplefySettingMath = SimplefySettingMath.new()
@export var room_count: SimplefySettingMath = SimplefySettingMath.new()
@export var room_size: SimplefySettingMath = SimplefySettingMath.new()

@export var terrain_set_id: int = 0
@export var terrain_id: int = 0

var start_area_was_created = false
var finished_map = false
var is_generating := false
var rng = RandomNumberGenerator.new()
var empty_rooms: Array[Dictionary] = []

signal map_was_created

@onready var generator: EnvironmentGenerator = $EnvironmentGenerator
@onready var tiles: EnvironmentTiles = $EnvironmentTiles
@onready var persistence: EnvironmentPersistence = $EnvironmentPersistence
@onready var reveal: EnvironmentReveal = $EnvironmentReveal


func _enter_tree() -> void:
	GSignals.ENV_destroy_tile.connect(_on_destroy_tile)
	GSignals.PERK_show_items_behind_wall.connect(_on_show_items_behind_wall)
	GSignals.ENV_remove_tile_from_wall.connect(_on_remove_tile_from_wall)

func _on_destroy_tile(pos: Array[Vector2], damage: int = 1) -> void:
	tiles.destroy_tile_at(pos, damage)

func _on_show_items_behind_wall(pos: Array[Vector2]) -> void:
	reveal.show_items_behind_wall(pos)

func _on_remove_tile_from_wall(pos_tile: Vector2i) -> void:
	reveal.remove_tile_from_wall(pos_tile)


func _ready() -> void:
	randomize()
	if terrain_set_id == null:
		terrain_set_id = 0
	if terrain_id == null:
		terrain_id = 0

	if Map_Size.x > 0 and Map_Size.y > 0:
		if await persistence._try_load_saved_level():
			return

		is_generating = true
		rng.randomize()
		seed = rng.randi()
		reset_objects()
		room_count.min_value = ceil(3 + Map_Size.x / 20.0)
		room_count.max_value = ceil(7 + Map_Size.x / 20.0)
		await generate_map()


## Generates the full map and emits completion signals
func generate_map() -> void:
	var start_pos := Vector2i(-Map_Size.x / 2, -Map_Size.y / 2)
	var end_pos   := Vector2i( Map_Size.x / 2,  Map_Size.y / 2)
	await generator.fill_map(start_pos, end_pos)
	await tiles.force_refresh_all()
	finished_map = true
	is_generating = false

	if persistence_mode == 1:
		persistence._save_current_level_scene()

	map_was_created.emit()
	ScreenTransition.finished_loading.emit()


## Returns generation progress as a percentage from 0 to 100
func get_generation_percent() -> int:
	if finished_map:
		return 100
	if max_tiles_to_generate <= 0:
		return 0
	var ratio := float(tiles_generated) / float(max_tiles_to_generate)
	return clamp(int(ratio * 99.0), 0, 99)


## Resets all stateful objects before a new generation
func reset_objects() -> void:
	Bomb.reset()
