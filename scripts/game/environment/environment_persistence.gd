extends Node
class_name EnvironmentPersistence

const BINARY_LEVEL_MAGIC := "ARL1"
const BINARY_LEVEL_HEADER_SIZE := 20
const LEVEL_COORD_OFFSET := 32768

var _built_in_saved_binary_levels := PackedStringArray([
	"res://resources/levels/level1/planet_test_1149408979.arl",
	"res://resources/levels/level1/planet_test_1208765509.arl",
	"res://resources/levels/level1/planet_test_1910316198.arl",
	"res://resources/levels/level1/planet_test_1947861754.arl",
	"res://resources/levels/level1/planet_test_2035204963.arl",
	"res://resources/levels/level1/planet_test_2537608839.arl",
	"res://resources/levels/level1/planet_test_3488657853.arl",
	"res://resources/levels/level1/planet_test_740601264.arl",
	"res://resources/levels/level1/planet_test_940610946.arl",
])

@onready var env: Enviroment = get_parent()


## Attempts to load a saved level based on persistence_mode, returns true if successful
func _try_load_saved_level() -> bool:
	if env.persistence_mode != 2 and env.persistence_mode != 3:
		return false
	
	var data := _get_saved_level_data()
	if data == null:
		push_warning(
			"No saved level data found in %s with prefix %s. Explicit resource paths: %d, binary paths: %d, built-in binary levels: %d. Generating a new level."
			% [env.saved_dir, env.saved_file_prefix, env.saved_level_paths.size(), env.saved_binary_level_paths.size(), _built_in_saved_binary_levels.size()]
		)
		return false
	
	await _apply_tile_map_data(data)
	
	env.finished_map = true
	env.is_generating = false
	env.map_was_created.emit()
	ScreenTransition.finished_loading.emit()
	print("Loaded saved level seed %s with %d tiles." % [str(data.seed), data.positions_x.size()])
	
	return true


func _get_saved_level_data() -> TileMapData:
	var binary_data := _get_binary_saved_level_data()
	if binary_data != null:
		return binary_data

	var direct_levels := _get_direct_saved_levels()
	if not direct_levels.is_empty():
		if env.persistence_mode == 3:
			var local_rng := RandomNumberGenerator.new()
			local_rng.randomize()
			return direct_levels[local_rng.randi_range(0, direct_levels.size() - 1)]

		return direct_levels[0]

	var path: String
	if env.persistence_mode == 3:
		path = _get_random_saved_path()
	else:
		path = _get_latest_saved_path()

	if path == "":
		return null

	var data := ResourceLoader.load(path) as TileMapData
	if data == null:
		push_warning("Saved level could not be loaded as TileMapData: %s" % path)
	elif data.positions_x.is_empty():
		push_warning("Saved TileMapData has no tiles: %s" % path)
		return null
	return data


## Saves the current level as a lightweight TileMapData resource
func _save_current_level_scene() -> void:
	DirAccess.make_dir_recursive_absolute(env.saved_dir)

	var used := env.get_used_cells()
	var data := TileMapData.new()
	data.seed = env.seed
	data.map_size = env.Map_Size
	data.terrain_set_id = env.terrain_set_id
	data.terrain_id = env.terrain_id

	for cell in used:
		var sid := env.get_cell_source_id(cell)
		var ac := env.get_cell_atlas_coords(cell)
		var alt := env.get_cell_alternative_tile(cell)
		data.positions_x.append(cell.x)
		data.positions_y.append(cell.y)
		data.source_ids.append(sid)
		data.atlas_x.append(ac.x)
		data.atlas_y.append(ac.y)
		data.alternatives.append(alt)

	var file_name := ""
	if env.use_seed_in_filename:
		file_name = "%s%s.tres" % [env.saved_file_prefix, str(env.seed)]
	else:
		file_name = "%s%s.tres" % [env.saved_file_prefix, "static"]

	var full_path := "%s/%s" % [env.saved_dir, file_name]
	var err := ResourceSaver.save(data, full_path)
	if err != OK:
		push_error("Saving failed: %s" % str(err))

	var binary_path := "%s/%s" % [env.saved_dir, file_name.replace(".tres", ".arl")]
	var binary_err := _save_tile_map_binary(data, binary_path)
	if binary_err != OK:
		push_error("Binary level saving failed: %s" % str(binary_err))


func _get_binary_saved_level_data() -> TileMapData:
	var candidates := _get_existing_saved_binary_level_paths()
	if candidates.is_empty():
		return null

	var start_index := 0
	if env.persistence_mode == 3:
		var local_rng := RandomNumberGenerator.new()
		local_rng.randomize()
		start_index = local_rng.randi_range(0, candidates.size() - 1)

	for offset in range(candidates.size()):
		var path := candidates[(start_index + offset) % candidates.size()]
		var data := _load_tile_map_binary(path)
		if data != null and not data.positions_x.is_empty():
			print("Loaded binary level data: %s" % path)
			return data

	return null


func _load_tile_map_binary(path: String) -> TileMapData:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Binary level could not be opened: %s (%s)" % [path, str(FileAccess.get_open_error())])
		return null

	if file.get_length() < BINARY_LEVEL_HEADER_SIZE:
		push_warning("Binary level is too small: %s" % path)
		return null

	var magic := file.get_buffer(4).get_string_from_ascii()
	if magic != BINARY_LEVEL_MAGIC:
		push_warning("Binary level has invalid magic: %s" % path)
		return null

	var data := TileMapData.new()
	data.seed = file.get_32()
	data.map_size = Vector2i(file.get_16(), file.get_16())
	data.terrain_set_id = file.get_16()
	data.terrain_id = file.get_16()

	var count := file.get_32()
	var available_count := int((file.get_length() - file.get_position()) / 12)
	if count > available_count:
		push_warning("Binary level tile count is larger than file data: %s" % path)
		count = available_count

	data.positions_x.resize(count)
	data.positions_y.resize(count)
	data.source_ids.resize(count)
	data.atlas_x.resize(count)
	data.atlas_y.resize(count)
	data.alternatives.resize(count)

	var actual_count := 0
	for i in range(count):
		if file.get_position() + 12 > file.get_length():
			push_warning("Binary level ended early: %s" % path)
			break

		data.positions_x[i] = file.get_16() - LEVEL_COORD_OFFSET
		data.positions_y[i] = file.get_16() - LEVEL_COORD_OFFSET
		data.source_ids[i] = clampi(file.get_16(), 0, 255)
		data.atlas_x[i] = file.get_16()
		data.atlas_y[i] = file.get_16()
		data.alternatives[i] = file.get_16()
		actual_count += 1

	if actual_count < count:
		data.positions_x.resize(actual_count)
		data.positions_y.resize(actual_count)
		data.source_ids.resize(actual_count)
		data.atlas_x.resize(actual_count)
		data.atlas_y.resize(actual_count)
		data.alternatives.resize(actual_count)

	return data


func _save_tile_map_binary(data: TileMapData, path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	var count := _get_tile_data_count(data)
	file.store_buffer(BINARY_LEVEL_MAGIC.to_ascii_buffer())
	file.store_32(data.seed)
	file.store_16(data.map_size.x)
	file.store_16(data.map_size.y)
	file.store_16(data.terrain_set_id)
	file.store_16(data.terrain_id)
	file.store_32(count)

	for i in range(count):
		file.store_16(_encode_level_coord(data.positions_x[i]))
		file.store_16(_encode_level_coord(data.positions_y[i]))
		file.store_16(data.source_ids[i])
		file.store_16(data.atlas_x[i])
		file.store_16(data.atlas_y[i])
		file.store_16(data.alternatives[i])

	return OK


func _get_tile_data_count(data: TileMapData) -> int:
	var count := data.positions_x.size()
	count = mini(count, data.positions_y.size())
	count = mini(count, data.source_ids.size())
	count = mini(count, data.atlas_x.size())
	count = mini(count, data.atlas_y.size())
	count = mini(count, data.alternatives.size())
	return count


func _encode_level_coord(value: int) -> int:
	return clampi(value + LEVEL_COORD_OFFSET, 0, 65535)


## Applies finished saved tile data without recalculating terrain connections.
func _apply_tile_map_data(data: TileMapData) -> void:
	env.seed = data.seed
	env.Map_Size = data.map_size
	env.terrain_set_id = data.terrain_set_id
	env.terrain_id = data.terrain_id

	env.clear()
	env.tiles.tiles_dict.clear()
	env.rng.seed = data.seed

	var count := _get_tile_data_count(data)
	await _apply_saved_tile_pattern(data, count)
	print("Applied saved level cells: %d" % count)


func _apply_saved_tile_pattern(data: TileMapData, count: int) -> void:
	if count <= 0:
		await get_tree().process_frame
		return

	var origin := Vector2i(data.positions_x[0], data.positions_y[0])
	for i in range(1, count):
		origin.x = mini(origin.x, data.positions_x[i])
		origin.y = mini(origin.y, data.positions_y[i])

	var pattern := TileMapPattern.new()
	for i in range(count):
		var pos := Vector2i(data.positions_x[i], data.positions_y[i])
		var atlas := Vector2i(data.atlas_x[i], data.atlas_y[i])
		pattern.set_cell(pos - origin, data.source_ids[i], atlas, data.alternatives[i])

	env.set_pattern(origin, pattern)
	await get_tree().process_frame


## Returns the path to the most recently modified saved level
func _get_latest_saved_path() -> String:
	var explicit_paths := _get_existing_saved_level_paths()
	if not explicit_paths.is_empty():
		return explicit_paths[0]

	if env.use_seed_in_filename:
		var try_path := "%s/%s%s.tres" % [env.saved_dir, env.saved_file_prefix, str(env.seed)]
		if ResourceLoader.exists(try_path):
			return try_path

	var dir := DirAccess.open(env.saved_dir)
	if dir == null:
		return ""

	dir.list_dir_begin()
	var best_path := ""
	var best_time := -1
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if dir.current_is_dir():
			continue
		if !f.ends_with(".tres"):
			continue
		if not f.begins_with(env.saved_file_prefix):
			continue
		var full := "%s/%s" % [env.saved_dir, f]
		var mt := FileAccess.get_modified_time(full)
		if mt > best_time:
			best_time = mt
			best_path = full
	dir.list_dir_end()
	return best_path


## Returns a random saved level path from the saved directory
func _get_random_saved_path() -> String:
	var explicit_paths := _get_existing_saved_level_paths()
	if not explicit_paths.is_empty():
		var local_rng := RandomNumberGenerator.new()
		local_rng.randomize()
		return explicit_paths[local_rng.randi_range(0, explicit_paths.size() - 1)]

	var dir := DirAccess.open(env.saved_dir)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var candidates: Array[String] = []
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if dir.current_is_dir():
			continue
		if !f.ends_with(".tres"):
			continue
		if not f.begins_with(env.saved_file_prefix):
			continue
		candidates.append("%s/%s" % [env.saved_dir, f])
	dir.list_dir_end()
	if candidates.is_empty():
		return ""
	var local_rng := RandomNumberGenerator.new()
	local_rng.randomize()
	return candidates[local_rng.randi_range(0, candidates.size() - 1)]


func _get_existing_saved_level_paths() -> PackedStringArray:
	var candidates := PackedStringArray()
	for path in env.saved_level_paths:
		if path == "":
			continue
		if not path.ends_with(".tres"):
			continue
		candidates.append(path)
	return candidates


func _get_existing_saved_binary_level_paths() -> Array[String]:
	var candidates: Array[String] = []

	for path in env.saved_binary_level_paths:
		if _is_binary_level_path(path) and not candidates.has(path):
			candidates.append(path)

	for path in _built_in_saved_binary_levels:
		if _is_binary_level_path(path) and not candidates.has(path):
			candidates.append(path)

	return candidates


func _is_binary_level_path(path: String) -> bool:
	return path != "" and path.ends_with(".arl")


func _get_direct_saved_levels() -> Array[TileMapData]:
	var candidates: Array[TileMapData] = []

	for path in env.saved_level_paths:
		var data := ResourceLoader.load(path) as TileMapData
		if data != null and not data.positions_x.is_empty() and not candidates.has(data):
			candidates.append(data)

	return candidates
