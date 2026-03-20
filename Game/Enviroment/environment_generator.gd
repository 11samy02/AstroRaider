extends Node
class_name EnvironmentGenerator

var noise = FastNoiseLite.new()

@onready var env: Enviroment = get_parent()


func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX


## Fills the entire map area with chunks and rooms
func fill_map(start_position: Vector2i, end_position: Vector2i, _reverse: bool = false) -> void:
	var map_size = end_position - start_position
	var chunk_count_x = ceil(map_size.x / float(env.chunk_size.x))
	var chunk_count_y = ceil(map_size.y / float(env.chunk_size.y))
	Enviroment.max_tiles_to_generate = (
		int(ceil((end_position - start_position).x / float(env.chunk_size.x))) * env.chunk_size.x *
		int(ceil((end_position - start_position).y / float(env.chunk_size.y))) * env.chunk_size.y
	)
	var edge_tiles_accum: Array[Vector2i] = []
	var counter = 0
	Enviroment.tiles_generated = 0

	for chunk_x in range(chunk_count_x):
		for chunk_y in range(chunk_count_y):
			var chunk_start = start_position + Vector2i(chunk_x * env.chunk_size.x, chunk_y * env.chunk_size.y)
			var chunk_end = chunk_start + env.chunk_size - Vector2i(1, 1)
			var chunk_tiles = fill_chunk(chunk_start, chunk_end)
			env.tiles.set_live_to_tiles(chunk_tiles)
			edge_tiles_accum.append_array(get_edge_tiles(chunk_start, chunk_end))
			counter += 1
			if counter % 8 == 0:
				await get_tree().process_frame

	await create_random_rooms(start_position, end_position, env.room_count.get_rand_value(), 0.5, start_position, end_position)

	if not env.start_area_was_created:
		env.start_area_was_created = true
		await create_start_area(Vector2i(env.start_area_size.get_rand_value() + GlobalGame.Player_count, env.start_area_size.get_rand_value()))

	if edge_tiles_accum.size() > 0:
		await env.tiles.update_surrounding_tiles_batched(edge_tiles_accum, env.batch_size)

	env.tiles.update_surrounding_tiles(env.get_used_cells())


## Fills a single chunk with tiles and returns all tile positions
func fill_chunk(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var positions = []
	for x in range(chunk_start.x, chunk_end.x + 1):
		for y in range(chunk_start.y, chunk_end.y + 1):
			positions.append(Vector2i(x, y))
			Enviroment.tiles_generated += 1
	if positions.size() > 0:
		env.set_cells_terrain_connect(positions, env.terrain_set_id, env.terrain_id)
	return positions


## Creates a number of randomly placed rooms within the map bounds
func create_random_rooms(area_start: Vector2i, area_end: Vector2i, max_rooms: int, randomness: float, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	for _i in range(max_rooms):
		var room_size_x = env.room_size.get_rand_value()
		var room_size_y = env.room_size.get_rand_value()
		var available_width = max(chunk_max.x - chunk_min.x + 1 - room_size_x, 1)
		var available_height = max(chunk_max.y - chunk_min.y + 1 - room_size_y, 1)
		var room_position_x = env.rng.randi_range(chunk_min.x, chunk_min.x + available_width - 1)
		var room_position_y = env.rng.randi_range(chunk_min.y, chunk_min.y + available_height - 1)
		var room_position = Vector2i(room_position_x, room_position_y)

		env.empty_rooms.append({ "position": room_position, "size": Vector2i(room_size_x, room_size_y) })
		await create_area(Vector2i(room_size_x, room_size_y), randomness, room_position, chunk_min, chunk_max)


## Carves out an organic room shape using noise at the given position
func create_area(size: Vector2i, randomness: float, position: Vector2i, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	noise.frequency = env.rng.randf_range(0.05, 0.1)
	noise.seed = env.seed

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

	for p in to_remove:
		env.erase_cell(p)
	if to_add.size() > 0:
		env.set_cells_terrain_connect(to_add, env.terrain_set_id, env.terrain_id)

	var unique = {}
	for p in to_remove:
		for npos in env.tiles.get_custom_surrounding_cells(p):
			unique[npos] = true
	for p in to_add:
		for npos in env.tiles.get_custom_surrounding_cells(p):
			unique[npos] = true

	var refresh: Array[Vector2i] = []
	for c in unique.keys():
		if env.get_cell_source_id(c) != -1:
			refresh.append(c)

	if refresh.size() > 0:
		env.set_cells_terrain_connect(refresh, env.terrain_set_id, env.terrain_id)

	if to_add.size() > 0:
		env.tiles.set_live_to_tiles(to_add)

	await get_tree().process_frame


## Creates the initial spawn area around the origin using noise for organic edges
func create_start_area(size: Vector2i) -> void:
	var start_position = Vector2i(0, 0)
	env.empty_rooms.append({ "position": start_position, "size": size })

	var to_remove: Array[Vector2i] = []
	var radius = size.x / 2
	var local_noise = FastNoiseLite.new()
	local_noise.seed = env.rng.randi()
	local_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	local_noise.frequency = 0.1

	for x in range(-size.x / 2, size.x / 2):
		for y in range(-size.y / 2, size.y / 2):
			var p = Vector2i(x, y)
			var distance = p.length()
			var nv = local_noise.get_noise_2d(float(x), float(y)) * (radius * 0.2)
			if distance <= radius + nv:
				to_remove.append(p)

	for center_x in range(-2, 2):
		for center_y in range(-2, 2):
			to_remove.append(Vector2i(center_x, center_y))

	for p in to_remove:
		env.erase_cell(p)

	var unique = {}
	for q in to_remove:
		for npos in env.tiles.get_custom_surrounding_cells(q):
			unique[npos] = true

	var refresh: Array[Vector2i] = []
	for c in unique.keys():
		if env.get_cell_source_id(c) != -1:
			refresh.append(c)
	if refresh.size() > 0:
		env.set_cells_terrain_connect(refresh, env.terrain_set_id, env.terrain_id)
	await get_tree().process_frame


## Returns all tiles on the border edges of a chunk
func get_edge_tiles(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var edge_tiles = []
	for x in range(chunk_start.x, chunk_end.x + 1):
		edge_tiles.append(Vector2i(x, chunk_start.y))
		edge_tiles.append(Vector2i(x, chunk_end.y))
	for y in range(chunk_start.y + 1, chunk_end.y):
		edge_tiles.append(Vector2i(chunk_start.x, y))
		edge_tiles.append(Vector2i(chunk_end.x, y))
	return edge_tiles
