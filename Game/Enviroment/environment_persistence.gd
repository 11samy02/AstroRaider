extends Node
class_name EnvironmentPersistence

@onready var env: Enviroment = get_parent()


## Attempts to load a saved level based on persistence_mode, returns true if successful
func _try_load_saved_level() -> bool:
	if env.persistence_mode != 2 and env.persistence_mode != 3:
		return false
	
	var path: String
	if env.persistence_mode == 3:
		path = _get_random_saved_path()
	else:
		path = _get_latest_saved_path()
	
	if path == "":
		return false
	
	var data := ResourceLoader.load(path) as TileMapData
	if data == null:
		return false
	
	await _apply_tile_map_data(data)
	
	env.finished_map = true
	env.is_generating = false
	env.map_was_created.emit()
	ScreenTransition.finished_loading.emit()
	
	return true


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


## Applies a TileMapData resource directly to the tilemap without recalculating autotiles
func _apply_tile_map_data(data: TileMapData) -> void:
	env.seed = data.seed
	env.Map_Size = data.map_size
	env.terrain_set_id = data.terrain_set_id
	env.terrain_id = data.terrain_id

	env.clear()

	var count := data.positions_x.size()
	var positions: Array[Vector2i] = []
	var i := 0

	while i < count:
		var pos := Vector2i(data.positions_x[i], data.positions_y[i])
		var sid := data.source_ids[i]
		var ac := Vector2i(data.atlas_x[i], data.atlas_y[i])
		var alt := data.alternatives[i]
		env.set_cell(pos, sid, ac, alt)
		positions.append(pos)
		i += 1
		if i % env.batch_size == 0:
			await get_tree().process_frame

	env.tiles.set_live_to_tiles(positions)


## Returns the path to the most recently modified saved level
func _get_latest_saved_path() -> String:
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
