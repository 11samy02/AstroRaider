extends TileMapLayer
class_name Enviroment

@export_enum("Disabled", "GenerateAndSave", "LoadSaved", "LoadRandom")
var persistence_mode: int = 0

@export var saved_dir: String = "res://Levels/level1"
@export var saved_file_prefix: String = "generated_level_"
@export var use_seed_in_filename: bool = true


static var max_tiles_to_generate = 0
static var tiles_generated = 0

var wall_notification : Array[Vector2i]

var tiles_dict: Dictionary = {}

const GROUND_PARTICLE = preload("res://Particles/destroy_ground_particle.tscn")
const ITEM_IN_WALL_NOTIFICATION = preload("res://Visuel Feedback Tutorial/item_in_wall_notification.tscn")

@export var TileDrops: Array[TileDropResource]

@export var chunk_size: Vector2i = Vector2i(50, 50)
@export var Map_Size: Vector2i = Vector2i(200, 200)
var seed: int
var noise = FastNoiseLite.new()


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

func _enter_tree() -> void:
	GSignals.ENV_destroy_tile.connect(destroy_tile_at)
	GSignals.PERK_show_items_behind_wall.connect(show_items_behind_wall)
	GSignals.ENV_remove_tile_from_wall.connect(remove_tile_from_wall)

func _ready() -> void:
	randomize()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	if terrain_set_id == null:
		terrain_set_id = 0
	if terrain_id == null:
		terrain_id = 0
	
	if Map_Size.x > 0 and Map_Size.y > 0:
		if await _try_load_saved_level():
			return

		is_generating = true
		rng.randomize()
		seed = rng.randi()
		reset_objects()
		room_count.min_value = ceil(3 + Map_Size.x / 20.0)
		room_count.max_value = ceil(7 + Map_Size.x / 20.0)
		await generate_map()


func generate_map() -> void:
	var start_pos := Vector2i(-Map_Size.x / 2, -Map_Size.y / 2)
	var end_pos   := Vector2i( Map_Size.x / 2,  Map_Size.y / 2)
	await fill_map(start_pos, end_pos)
	await force_refresh_all()
	finished_map = true
	is_generating = false
	
	if persistence_mode == 1:
		_save_current_level_scene()

	map_was_created.emit()
	ScreenTransition.finished_loading.emit()


func force_refresh_all() -> void:
	var used := get_used_cells()
	if used.is_empty():
		await get_tree().process_frame
		return
	await get_tree().process_frame
	var batch := []
	var to_live := []
	for cell in used:
		batch.append(cell)
		to_live.append(cell)
		if batch.size() >= batch_size:
			set_cells_terrain_connect(batch, terrain_set_id, terrain_id)
			batch.clear()
			await get_tree().process_frame
	if batch.size() > 0:
		set_cells_terrain_connect(batch, terrain_set_id, terrain_id)
		batch.clear()
	set_live_to_tiles(to_live)
	await update_surrounding_tiles_batched(to_live, batch_size)

# ---- Tiles lebendig machen (Resource, kein Dict-Mix) ----
func set_live_to_tiles(tiles_to_process: Array = []) -> void:
	if tiles_to_process.is_empty():
		tiles_to_process = get_used_cells()
	for t in tiles_to_process:
		var tile_pos: Vector2i = Vector2i(t)
		if tiles_dict.has(tile_pos):
			continue
		var drop: TileDropResource = get_random_drop()
		var tr = DestroyableTileResource.new()
		tr.pos = tile_pos
		tr.key = (drop.key if drop != null else 0)
		tr.drop_count.min_value = (drop.min_amount if drop != null else 0)
		tr.drop_count.max_value = (drop.max_amount if drop != null else 0)
		# Health-Default, falls die Resource keins setzt
		if not ("health" in tr):
			tr.health = 3
		tiles_dict[tile_pos] = tr

# ---- Abbau & Drops (batched, border-only refresh, budgets) ----
func destroy_tile_at(pos: Array[Vector2], damage: int = 1) -> void:
	if pos.is_empty():
		return

	# 1) World->Map deduplizieren (verhindert doppelte Arbeit bei Überlappung)
	var uniq := {}
	for w in pos:
		uniq[Vector2i(local_to_map(w))] = true
	var all_pos: Array[Vector2i] = []
	for k in uniq.keys():
		all_pos.append(k)
	# Budgets pro Batch (einfach; später gern pro Frame auslagern)
	var PARTICLE_BUDGET_PER_BATCH := 60
	var DROP_BUDGET_PER_BATCH := 35

	var i := 0
	while i < all_pos.size():
		var end = min(i + batch_size, all_pos.size())
		var removed: Array[Vector2i] = []
		var particles_used := 0
		var drops_used := 0

		# 2) Tiles in diesem Batch verarbeiten
		for j in range(i, end):
			var tile_pos := all_pos[j]
			if tiles_dict.has(tile_pos):
				var tile: DestroyableTileResource = tiles_dict[tile_pos]
				tile.health -= damage
				if tile.health <= 0:
					# Partikel (budgetiert)
					if particles_used < PARTICLE_BUDGET_PER_BATCH:
						var particle = GROUND_PARTICLE.instantiate()
						particle.global_position = map_to_local(tile_pos)
						get_parent().add_child(particle)
						particles_used += 1

					# Drops (budgetiert)
					if drops_used < DROP_BUDGET_PER_BATCH:
						drop_items(tile)
						drops_used += 1

					erase_cell(tile_pos)
					tiles_dict.erase(tile_pos)
					removed.append(tile_pos)

		# 3) Nur Border-Zellen updaten (Grenzen der entfernten Zellen)
		if not removed.is_empty():
			var remset := {}
			for p in removed:
				remset[p] = true

			var border: Array[Vector2i] = []
			for p in removed:
				for n in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var q = p + n
					if not remset.has(q) and get_cell_source_id(q) != -1:
						border.append(q)

			if not border.is_empty():
				if border.size() > 64:
					await update_surrounding_tiles_batched(border, 128) # größerer Refresh-Batch
				else:
					update_surrounding_tiles(border)

		# 4) Frame freigeben → flüssig bei vielen Bomben
		await get_tree().process_frame
		i = end

func drop_items(tile: DestroyableTileResource) -> void:
	var dc = rng.randi_range(tile.drop_count.min_value, tile.drop_count.max_value)
	for _i in range(dc):
		var scene = DropData.load_drop_szene(tile.key)
		if scene == null:
			continue
		var item = scene.instantiate()
		var wpos = map_to_local(tile.pos)
		if item is CollectableTemplate:
			item.global_position = wpos + Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
			get_parent().add_child(item)
		elif item is StaticEnemy or item is OreTemplate:
			item.global_position = wpos
			get_parent().add_child(item)

func update_surrounding_tiles(tile_positions: Array) -> void:
	var unique_cells = {}  
	for pos in tile_positions:  
		var surrounding_cells = get_custom_surrounding_cells(pos)  
		for cell in surrounding_cells:  
			unique_cells[cell] = true  
	var to_update = []  
	for cell in unique_cells.keys():  
		if get_cell_source_id(cell) != -1:  
			to_update.append(cell)  
	if to_update.is_empty():  
		return  
	var batch = []  
	var tiles_to_process = []  
	while not to_update.is_empty():  
		batch.append(to_update.pop_back())  
		if batch.size() >= batch_size:  
			await get_tree().process_frame  
			for cell in batch:  
				set_cell(cell, -1)  
				tiles_to_process.append(cell)  
			set_cells_terrain_connect(batch, 0, 0)  
			batch.clear()  
	if batch.size() > 0:  
		for cell in batch:  
			set_cell(cell, -1)  
			tiles_to_process.append(cell)  
		set_cells_terrain_connect(batch, 0, 0)  
	set_live_to_tiles(tiles_to_process)  
  
func update_surrounding_tiles_batched(tile_positions: Array, batch_size: int = 25) -> void:
	var unique_cells = {}  
	for pos in tile_positions:  
		var surrounding_cells = get_custom_surrounding_cells(pos)  
		for cell in surrounding_cells:  
			unique_cells[cell] = true  
	var to_update = []  
	for cell in unique_cells.keys():  
		if get_cell_source_id(cell) != -1:  
			to_update.append(cell)  
	if to_update.is_empty():  
		return  
	var index = 0  
	var total = to_update.size()  
	  
	var all_cells_from_all_batches := []  
	while index < total:  
		var batch = to_update.slice(index, index + batch_size)  
		for cell in batch:  
			set_cell(cell, 0)  
		set_cells_terrain_connect(batch, 0, 0)  
		set_live_to_tiles(batch)  
		index += batch_size  
		await get_tree().process_frame  

# ---- Helpers ----
func get_custom_surrounding_cells(pos: Vector2i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			neighbors.append(pos + Vector2i(dx, dy))
	return neighbors

func get_random_drop() -> TileDropResource:
	var list: Array[TileDropResource] = []
	for t in TileDrops:
		for _rar in t.rarity:
			list.append(t)
	if list.is_empty():
		return null
	return list[rng.randi_range(0, list.size() - 1)]
	

# Normalisiert Einträge aus DirAccess:
# akzeptiert *.tscn und *.tscn.remap, gibt IMMER den .tscn-Pfad zurück (ohne .remap)
func _normalize_scene_path(dir_path: String, fname: String) -> String:
	if fname.ends_with(".tscn.remap"):
		return dir_path + "/" + fname.replace(".tscn.remap", ".tscn")
	elif fname.ends_with(".tscn"):
		return dir_path + "/" + fname
	return ""

# Existenz-Check über ResourceLoader (kennt Remaps)
func _resource_exists_scene(path_tscn: String) -> bool:
	return ResourceLoader.exists(path_tscn)

# Modified-Time für .tscn ODER .tscn.remap
func _get_modified_time_any(path_tscn: String) -> int:
	if FileAccess.file_exists(path_tscn):
		return FileAccess.get_modified_time(path_tscn)
	var remap := path_tscn + ".remap"
	if FileAccess.file_exists(remap):
		return FileAccess.get_modified_time(remap)
	return -1


# ---- Map-Generierung (streamend, ohne Hänger) ----
func fill_map(start_position: Vector2i, end_position: Vector2i, _reverse: bool = false) -> void:
	var map_size = end_position - start_position
	var chunk_count_x = ceil(map_size.x / float(chunk_size.x))
	var chunk_count_y = ceil(map_size.y / float(chunk_size.y))
	max_tiles_to_generate = (
		int(ceil((end_position - start_position).x / float(chunk_size.x))) * chunk_size.x * int(ceil((end_position - start_position).y / float(chunk_size.y))) * chunk_size.y
		)
	var edge_tiles_accum: Array[Vector2i] = []
	var counter = 0
	tiles_generated = 0
	
	for chunk_x in range(chunk_count_x):
		for chunk_y in range(chunk_count_y):
			var chunk_start = start_position + Vector2i(chunk_x * chunk_size.x, chunk_y * chunk_size.y)
			var chunk_end = chunk_start + chunk_size - Vector2i(1, 1)
			var chunk_tiles = fill_chunk(chunk_start, chunk_end)
			set_live_to_tiles(chunk_tiles)
			edge_tiles_accum.append_array(get_edge_tiles(chunk_start, chunk_end))
			counter += 1
			if counter % 8 == 0:
				await get_tree().process_frame
	
	await create_random_rooms(start_position, end_position, room_count.get_rand_value(), 0.5, start_position, end_position)
	
	if not start_area_was_created:
		start_area_was_created = true
		await create_start_area(Vector2i(start_area_size.get_rand_value() + GlobalGame.Player_count, start_area_size.get_rand_value()))
	
	
	if edge_tiles_accum.size() > 0:
		await update_surrounding_tiles_batched(edge_tiles_accum, batch_size)
	
	update_surrounding_tiles(get_used_cells())


func fill_chunk(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var positions = []
	for x in range(chunk_start.x, chunk_end.x + 1):
		for y in range(chunk_start.y, chunk_end.y + 1):
			positions.append(Vector2i(x, y))
			tiles_generated += 1
	if positions.size() > 0:
		set_cells_terrain_connect(positions, terrain_set_id, terrain_id)
		# edge_tiles-Update HIER entfernen
	return positions


# ---- Räume & Startbereich ----
func create_random_rooms(area_start: Vector2i, area_end: Vector2i, max_rooms: int, randomness: float, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	for _i in range(max_rooms):
		var room_size_x = room_size.get_rand_value()
		var room_size_y = room_size.get_rand_value()
		var available_width = max(chunk_max.x - chunk_min.x + 1 - room_size_x, 1)
		var available_height = max(chunk_max.y - chunk_min.y + 1 - room_size_y, 1)
		var room_position_x = rng.randi_range(chunk_min.x, chunk_min.x + available_width - 1)
		var room_position_y = rng.randi_range(chunk_min.y, chunk_min.y + available_height - 1)
		var room_position = Vector2i(room_position_x, room_position_y)

		empty_rooms.append({ "position": room_position, "size": Vector2i(room_size_x, room_size_y) })
		await create_area(Vector2i(room_size_x, room_size_y), randomness, room_position, chunk_min, chunk_max)

func create_area(size: Vector2i, randomness: float, position: Vector2i, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	noise.frequency = rng.randf_range(0.05, 0.1)
	noise.seed = seed

	var to_remove: Array[Vector2i] = []
	var to_add: Array[Vector2i] = []

	var half_x = int(ceil(size.x / 2.0))
	var half_y = int(ceil(size.y / 2.0))
	var size_len = max(1.0, Vector2(size.x, size.y).length())

	for sx in range(-half_x, half_x):
		for sy in range(-half_y, half_y):
			var tile_position = position + Vector2i(sx, sy)
			if tile_position.x < chunk_min.x or tile_position.x > chunk_max.x or tile_position.y < chunk_min.y or tile_position.y > chunk_max.y:
				continue

			var distance_to_center = Vector2(sx, sy).length()
			var n = noise.get_noise_2d(float(sx), float(sy))

			if n > randomness - (distance_to_center / size_len):
				if n + randomness * distance_to_center > 0.1:
					to_remove.append(tile_position)
			elif n < randomness and distance_to_center > size_len * 0.3:
				if n * randomness < -0.2:
					to_add.append(tile_position)

	# Anwenden
	for p in to_remove:
		erase_cell(p)
	if to_add.size() > 0:
		set_cells_terrain_connect(to_add, terrain_set_id, terrain_id)

	# Nachbarn refreshen
	var unique = {}
	for p in to_remove:
		for npos in get_custom_surrounding_cells(p):
			unique[npos] = true
	for p in to_add:
		for npos in get_custom_surrounding_cells(p):
			unique[npos] = true

	var refresh: Array[Vector2i] = []
	for c in unique.keys():
		if get_cell_source_id(c) != -1:
			refresh.append(c)

	if refresh.size() > 0:
		set_cells_terrain_connect(refresh, terrain_set_id, terrain_id)

	if to_add.size() > 0:
		set_live_to_tiles(to_add)

	await get_tree().process_frame

func create_start_area(size: Vector2i) -> void:
	var start_position = Vector2i(0, 0)
	empty_rooms.append({ "position": start_position, "size": size })
	
	var to_remove: Array[Vector2i] = []
	var radius = size.x / 2
	var noise = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.1
	
	for x in range(-size.x / 2, size.x / 2):
		for y in range(-size.y / 2, size.y / 2):
			var p = Vector2i(x, y)
			var distance = p.length()
			var nv = noise.get_noise_2d(float(x), float(y)) * (radius * 0.2)
			if distance <= radius + nv:
				to_remove.append(p)
				
	for center_x in range(-2,2):
		for center_y in range(-2,2):
			to_remove.append(Vector2i(center_x, center_y))
		
	for p in to_remove:
		erase_cell(p)
		
	var unique = {}
	for q in to_remove:
		for npos in get_custom_surrounding_cells(q):
			unique[npos] = true
			
	var refresh: Array[Vector2i] = []
	for c in unique.keys():
		if get_cell_source_id(c) != -1:
			refresh.append(c)
	if refresh.size() > 0:
		set_cells_terrain_connect(refresh, terrain_set_id, terrain_id)
	await get_tree().process_frame

# ---- Chunk-Ränder ----
func get_edge_tiles(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var edge_tiles = []
	for x in range(chunk_start.x, chunk_end.x + 1):
		edge_tiles.append(Vector2i(x, chunk_start.y))
		edge_tiles.append(Vector2i(x, chunk_end.y))
	for y in range(chunk_start.y + 1, chunk_end.y):
		edge_tiles.append(Vector2i(chunk_start.x, y))
		edge_tiles.append(Vector2i(chunk_end.x, y))
	return edge_tiles

# ---- Reset/Buildings/Reveal ----
func reset_objects() -> void:
	Bomb.reset()

func show_items_behind_wall(pos: Array[Vector2]) -> void:
	for i in pos:
		var tile_pos = Vector2i(local_to_map(i))
		if tiles_dict.has(tile_pos):
			if !wall_notification.has(tile_pos):
				var tile: DestroyableTileResource = tiles_dict[tile_pos]
				if tile.key != DropData.Keys.Crystal:
					var notification = ITEM_IN_WALL_NOTIFICATION.instantiate()
					notification.global_position = i
					notification._set_icon(tile.key)
					wall_notification.append(tile_pos)
					notification.pos = tile_pos
					get_parent().add_child(notification)
			else:
				GSignals.ENV_reset_timer_for_wall_notification.emit(tile_pos)

func get_generation_percent() -> int:
	if finished_map:
		return 100
	if max_tiles_to_generate <= 0:
		return 0
	var ratio := float(tiles_generated) / float(max_tiles_to_generate)
	return clamp(int(ratio * 99.0), 0, 99)

func remove_tile_from_wall(pos_tile: Vector2i) -> void:
	if wall_notification.has(pos_tile):
		wall_notification.erase(pos_tile)


func _try_load_saved_level() -> bool:
	if persistence_mode != 2 and persistence_mode != 3:
		return false
	
	var path: String
	if persistence_mode == 3:
		path = _get_random_saved_scene_path()
	else:
		path = _get_latest_saved_scene_path()
	
	
	if path == "":
		return false

	var packed := ResourceLoader.load(path)
	if packed == null:
		return false
	var wrapper = packed.instantiate()
	if wrapper == null:
		return false

	var loaded_env := _find_first_env(wrapper)
	if loaded_env == null and (wrapper is Enviroment):
		loaded_env = wrapper
	if loaded_env == null:
		return false

	# --- WICHTIG: in DIESES Enviroment kopieren, nicht ersetzen ---
	await _apply_loaded_env_to_self(loaded_env)

	# Fertig signalisieren (auf DIESEM Node, damit Listener greifen)
	finished_map = true
	is_generating = false
	map_was_created.emit()
	ScreenTransition.finished_loading.emit()
	
	wrapper.free()
	return true




func _save_current_level_scene() -> void:
	DirAccess.make_dir_recursive_absolute(saved_dir)
	
	var wrapper := Node2D.new()
	wrapper.name = "LevelRoot"
	
	var cloned := duplicate(true)
	cloned.name = name
	wrapper.add_child(cloned)
	
	_set_owner_recursive(wrapper, cloned)
	
	var ps := PackedScene.new()
	var pack_err := ps.pack(wrapper)
	if pack_err != OK:
		push_error("Packing failed with error: %s" % str(pack_err))
		return
	
	var file_name := ""
	if use_seed_in_filename:
		file_name = "%s%s.tscn" % [saved_file_prefix, str(seed)]
	else:
		file_name = "%s%s.tscn" % [saved_file_prefix, "static"]
	
	var full_path := "%s/%s" % [saved_dir, file_name]
	var save_err := ResourceSaver.save(ps, full_path)
	if save_err != OK:
		push_error("Saving failed with error: %s" % str(save_err))


func _get_latest_saved_scene_path() -> String:
	if use_seed_in_filename:
		var try_path := "%s/%s%s.tscn" % [saved_dir, saved_file_prefix, str(seed)]
		if _resource_exists_scene(try_path):
			return try_path
	
	var dir := DirAccess.open(saved_dir)
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
		# WICHTIG: sowohl .tscn als auch .tscn.remap akzeptieren
		if !(f.ends_with(".tscn") or f.ends_with(".tscn.remap")):
			continue
		if not f.begins_with(saved_file_prefix):
			continue
		var normalized := _normalize_scene_path(saved_dir, f)
		if !_resource_exists_scene(normalized):
			continue
		var mt := _get_modified_time_any(normalized)
		if mt > best_time:
			best_time = mt
			best_path = normalized
	dir.list_dir_end()
	return best_path



func _find_first_env(n: Node) -> Enviroment:
	if n is Enviroment:
		return n
	for c in n.get_children():
		var r := _find_first_env(c)
		if r != null:
			return r
	return null

func _get_random_saved_scene_path() -> String:
	var dir := DirAccess.open(saved_dir)
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
		if !(f.ends_with(".tscn") or f.ends_with(".tscn.remap")):
			continue
		if not f.begins_with(saved_file_prefix):
			continue
		var normalized := _normalize_scene_path(saved_dir, f)
		if _resource_exists_scene(normalized):
			candidates.append(normalized)
	dir.list_dir_end()
	if candidates.is_empty():
		return ""
	var local_rng := RandomNumberGenerator.new()
	local_rng.randomize()
	return candidates[local_rng.randi_range(0, candidates.size() - 1)]


func _set_owner_recursive(root: Node, node: Node) -> void:
	node.owner = root
	for c in node.get_children():
		_set_owner_recursive(root, c)

func _apply_loaded_env_to_self(src: Enviroment) -> void:
	# Relevante Settings übernehmen (optional)
	seed = src.seed
	Map_Size = src.Map_Size
	terrain_set_id = src.terrain_set_id
	terrain_id = src.terrain_id

	# Tiles übernehmen
	clear()

	var used := src.get_used_cells()
	if used.is_empty():
		return

	var i := 0
	for cell in used:
		var sid := src.get_cell_source_id(cell)
		if sid == -1:
			continue
		var ac := src.get_cell_atlas_coords(cell)
		var alt := src.get_cell_alternative_tile(cell)
		# exakte Zelle setzen
		set_cell(cell, sid, ac, alt)

		i += 1
		if i % batch_size == 0:
			await get_tree().process_frame

	# Autotile-Connects herstellen (idempotent)
	await get_tree().process_frame
	set_cells_terrain_connect(used, terrain_set_id, terrain_id)

	# Laufzeitdaten neu aufbauen (Drops/Health in tiles_dict)
	set_live_to_tiles(used)
