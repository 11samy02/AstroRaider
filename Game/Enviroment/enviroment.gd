extends TileMapLayer
class_name Enviroment

var tiles_dict: Dictionary = {}

const GROUND_PARTICLE = preload("res://Particles/destroy_ground_particle.tscn")

@export var TileDrops: Array[TileDropResource]


@export var chunk_size: Vector2i = Vector2i(25, 25)
@export var Map_Size: Vector2i = Vector2i(200, 200)
@export var Min_Enemy_Room_AREA = 20
var seed: int

var map_corner := {
	"Left": 0,
	"Right": 0,
	"Bottom": 0,
	"Up": 0
}

@export var threshold := Vector2i(25,20)
@export var batch_size := 200

@export_group("Rooms Settings")
@export var start_area_size: SimplefySettingMath = SimplefySettingMath.new()
@export var room_count: SimplefySettingMath = SimplefySettingMath.new()
@export var room_size: SimplefySettingMath = SimplefySettingMath.new()
@export var EnemyBuildingList: Array[EnemyBuildingResource]

var start_area_was_created := false
var finished_map := false

var rng = RandomNumberGenerator.new()

var empty_rooms: Array[Dictionary] = []

signal map_was_created

func _enter_tree() -> void:
	GSignals.ENV_destroy_tile.connect(destroy_tile_at)

func _ready() -> void:
	set_Enemy_building_in_list()
	rng.randomize()
	seed = rng.randi()
	reset_objects()
	room_count.min_value = ceil(3 + Map_Size.x / 20)
	room_count.max_value = ceil(7 + Map_Size.x / 20)
	fill_map(Vector2i(-Map_Size.x / 2, -Map_Size.y / 2), Vector2i(Map_Size.x / 2, Map_Size.y / 2))

func set_Enemy_building_in_list():
	var new_list : Array[EnemyBuildingResource] = []
	for res: EnemyBuildingResource in EnemyBuildingList:
		for rar in res.rarity:
			new_list.append(res)
	
	EnemyBuildingList = new_list

func _process(delta: float) -> void:
	check_player_pos()

func set_live_to_tiles(tiles_to_process: Array = []) -> void:
	if tiles_to_process.is_empty():
		tiles_to_process = get_used_cells()
	for tile_pos in tiles_to_process:
		tile_pos = Vector2i(tile_pos)
		if tiles_dict.has(tile_pos):
			continue
		var tile_Res := DestroyableTileResource.new()
		var tile_drop := get_random_drop()
		tile_Res.pos = tile_pos
		tile_Res.drop_path = tile_drop.Drop_path
		tile_Res.drop_count.min_value = tile_drop.min_amount
		tile_Res.drop_count.max_value = tile_drop.max_amount
		tiles_dict[tile_pos] = tile_Res

func destroy_tile_at(pos: Array[Vector2], damage: int = 1) -> void:
	var to_remove = []
	var to_update = []
	for i in pos:
		var tile_pos = local_to_map(i)
		tile_pos = Vector2i(tile_pos)
		if tiles_dict.has(tile_pos):
			var tile = tiles_dict[tile_pos]
			tile.health -= damage
			if tile.health <= 0:
				var particle = GROUND_PARTICLE.instantiate()
				particle.global_position = map_to_local(tile_pos)
				get_parent().add_child(particle)
				drop_items(tile)
				to_remove.append(tile_pos)
				erase_cell(tile_pos)
				to_update.append(tile_pos)
	for tile_pos in to_remove:
		tiles_dict.erase(tile_pos)
	if to_update.size() > 10:
		update_surrounding_tiles_batched(to_update)
	else:
		update_surrounding_tiles(to_update)

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

func update_surrounding_tiles_batched(tile_positions: Array, batch_size: int = 50) -> void:
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
	while index < total:
		var batch = to_update.slice(index, index + batch_size)
		for cell in batch:
			set_cell(cell, -1)
		set_cells_terrain_connect(batch, 0, 0)
		set_live_to_tiles(batch)
		index += batch_size
		await get_tree().process_frame



func drop_items(tile: DestroyableTileResource) -> void:
	var drop_count = rng.randi_range(tile.drop_count.min_value, tile.drop_count.max_value)
	for i in range(drop_count):
		var item = load(tile.drop_path).instantiate()
		if item is CollectableTemplate:
			item.global_position = map_to_local(tile.pos)
			item.global_position += Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
			get_parent().add_child(item)
		elif item is StaticEnemy or item is OreTemplate:
			item.global_position = map_to_local(tile.pos)
			get_parent().add_child(item)

func get_custom_surrounding_cells(pos: Vector2i) -> Array:
	var surrounding_positions = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			surrounding_positions.append(pos + Vector2i(dx, dy))
	return surrounding_positions


func get_random_drop() -> TileDropResource:
	var rarity_list: Array[TileDropResource] = []
	for tile_drop_resource in TileDrops:
		for rarity in tile_drop_resource.rarity:
			rarity_list.append(tile_drop_resource)
	return rarity_list[rng.randi_range(0, rarity_list.size() - 1)]

func fill_map(start_position: Vector2i, end_position: Vector2i, reverse: bool = false) -> void:
	update_map_corners(start_position, end_position)
	var map_size = end_position - start_position
	var chunk_count_x = ceil(map_size.x / float(chunk_size.x))
	var chunk_count_y = ceil(map_size.y / float(chunk_size.y))
	
	var all_tiles = []
	var edge_tiles = []
	var chunk_batch_size = 100
	
	for chunk_x in range(chunk_count_x):
		for chunk_y in range(chunk_count_y):
			var chunk_start = start_position + Vector2i(chunk_x * chunk_size.x, chunk_y * chunk_size.y)
			var chunk_end = chunk_start + chunk_size - Vector2i(1, 1)
			var chunk_tiles = fill_chunk(chunk_start, chunk_end)
			all_tiles.append_array(chunk_tiles)
	
			edge_tiles.append_array(get_edge_tiles(chunk_start, chunk_end))
	
			if int(chunk_x * chunk_count_y + chunk_y) % chunk_batch_size == 0:
				await get_tree().process_frame
	
	if not start_area_was_created:
		start_area_was_created = true
		create_start_area(Vector2i(start_area_size.get_rand_value() + GlobalGame.Player_count, start_area_size.get_rand_value()))
	
	create_random_rooms(start_position, end_position, room_count.get_rand_value(), 0.5, start_position, end_position)
	
	var combined_tiles = all_tiles + edge_tiles
	await update_surrounding_tiles_batched(combined_tiles, batch_size)
	
	if not finished_map:
		finished_map = true
		spawn_enemy_buildings()
		map_was_created.emit()
		ScreenTransition.finished_loading.emit()


func fill_chunk(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var tile_positions = []
	for x in range(chunk_start.x, chunk_end.x + 1):
		for y in range(chunk_start.y, chunk_end.y + 1):
			var tile_position = Vector2i(x, y)
			set_cell(tile_position, 0, Vector2i(0, 0), 0)
			tile_positions.append(tile_position)
	return tile_positions




func update_map_corners(new_start_position: Vector2i, new_end_position: Vector2i) -> void:
	if new_start_position.x < map_corner.Left:
		map_corner.Left = new_start_position.x
	if new_end_position.x > map_corner.Right:
		map_corner.Right = new_end_position.x
	if new_start_position.y < map_corner.Up:
		map_corner.Up = new_start_position.y
	if new_end_position.y > map_corner.Bottom:
		map_corner.Bottom = new_end_position.y



func create_random_rooms(area_start: Vector2i, area_end: Vector2i, max_rooms: int, randomness: float, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	var area_size = area_end - area_start
	for i in range(max_rooms):
		var room_size_x = room_size.get_rand_value()
		var room_size_y = room_size.get_rand_value()
		var available_width = max(chunk_max.x - chunk_min.x + 1 - room_size_x, 1)
		var available_height = max(chunk_max.y - chunk_min.y + 1 - room_size_y, 1)
		var room_position_x = rng.randi_range(chunk_min.x, chunk_min.x + available_width - 1)
		var room_position_y = rng.randi_range(chunk_min.y, chunk_min.y + available_height - 1)
		var room_position = Vector2i(room_position_x, room_position_y)
		empty_rooms.append({
			"position": room_position,
			"size": Vector2i(room_size_x, room_size_y)
		})

		create_area(Vector2i(room_size_x, room_size_y), randomness, room_position, chunk_min, chunk_max)

func create_area(size: Vector2i, randomness: float, position: Vector2i, chunk_min: Vector2i, chunk_max: Vector2i) -> void:
	var noise := FastNoiseLite.new()
	noise.set_noise_type(randi_range(0,3))
	noise.frequency = randf_range(0.05,0.1)
	noise.seed = seed
	
	var modified_tiles = []
	for size_x in range(-int(ceil(size.x / 2.0)), int(ceil(size.x / 2.0))):
		for size_y in range(-int(ceil(size.y / 2.0)), int(ceil(size.y / 2.0))):
			var tile_position = position + Vector2i(size_x, size_y)
			
			if tile_position.x >= chunk_min.x and tile_position.x <= chunk_max.x and tile_position.y >= chunk_min.y and tile_position.y <= chunk_max.y:
				var distance_to_center = Vector2(size_x, size_y).length()
				var noise_value = noise.get_noise_2d(float(size_x), float(size_y))
				
				if noise_value > randomness - (distance_to_center / float(size.length())):
					if noise_value + randomness * distance_to_center > 0.1:
						set_cell(tile_position, -1, Vector2i(0, 0), 0)
						modified_tiles.append(tile_position)
				elif noise_value < randomness and distance_to_center > float(size.length()) * 0.3:
					if noise_value * randomness < -0.2:
						set_cell(tile_position, 0, Vector2i(0, 0), 0)
						modified_tiles.append(tile_position)
	
	await update_surrounding_tiles_batched(modified_tiles)



func create_start_area(size: Vector2i):
	var start_position = Vector2i(0, 0)
	empty_rooms.append({
		"position": start_position,
		"size": size
	})

	var modified_tiles = []
	var radius = size.x / 2
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.set_noise_type(0)
	noise.frequency = 0.1
	for x in range(-size.x / 2, size.x / 2):
		for y in range(-size.y / 2, size.y / 2):
			var tile_position = Vector2i(x, y)
			var distance = tile_position.length()
			var noise_value = noise.get_noise_2d(float(x), float(y)) * (radius * 0.2)
			if distance <= radius + noise_value:
				set_cell(tile_position, -1, Vector2i(0, 0), 0)
				modified_tiles.append(tile_position)
	await update_surrounding_tiles_batched(modified_tiles)



func get_edge_tiles(chunk_start: Vector2i, chunk_end: Vector2i) -> Array:
	var edge_tiles = []
	# Top and bottom edges
	for x in range(chunk_start.x, chunk_end.x + 1):
		edge_tiles.append(Vector2i(x, chunk_start.y))
		edge_tiles.append(Vector2i(x, chunk_end.y))
	# Left and right edges
	for y in range(chunk_start.y + 1, chunk_end.y):
		edge_tiles.append(Vector2i(chunk_start.x, y))
		edge_tiles.append(Vector2i(chunk_end.x, y))
	return edge_tiles


func check_player_pos() -> void:
	if GlobalGame.Players.is_empty():
		return
		
	
	for player_res in GlobalGame.Players:
		var pos = local_to_map(player_res.player.global_position)
		pos = Vector2i(pos)
		var chunks_to_fill = []
		
		
		if pos.x < map_corner.Left + threshold.x:
			var new_start = Vector2i(map_corner.Left - chunk_size.x, map_corner.Up)
			var new_end = Vector2i(map_corner.Left - 1, map_corner.Bottom)
			chunks_to_fill.append([new_start, new_end, true])
			
		if pos.x > map_corner.Right - threshold.x:
			var new_start = Vector2i(map_corner.Right, map_corner.Up)
			var new_end = Vector2i(map_corner.Right + chunk_size.x - 1, map_corner.Bottom)
			chunks_to_fill.append([new_start, new_end, false])
			
		if pos.y < map_corner.Up + threshold.y:
			var new_start = Vector2i(map_corner.Left, map_corner.Up - chunk_size.y)
			var new_end = Vector2i(map_corner.Right, map_corner.Up - 1)
			chunks_to_fill.append([new_start, new_end, true])
			
		if pos.y > map_corner.Bottom - threshold.y:
			var new_start = Vector2i(map_corner.Left, map_corner.Bottom)
			var new_end = Vector2i(map_corner.Right, map_corner.Bottom + chunk_size.y - 1)
			chunks_to_fill.append([new_start, new_end, false])
			
		for chunk_info in chunks_to_fill:
			await fill_map(chunk_info[0], chunk_info[1], chunk_info[2])
			await get_tree().process_frame

func reset_objects() -> void:
	Bomb.reset()

func spawn_enemy_buildings():
	if EnemyBuildingList.is_empty():
		return
	for room in empty_rooms:
		if room.size.x * room.size.y < Min_Enemy_Room_AREA:
			continue
		var center_position = room.position + room.size / 2
		var building_position = Vector2i(
			clamp(center_position.x, room.position.x, room.position.x + room.size.x - 1),
			clamp(center_position.y, room.position.y, room.position.y + room.size.y - 1)
		)
		var building_resource: EnemyBuildingResource = EnemyBuildingList[rng.randi_range(0, EnemyBuildingList.size() - 1)]
		var building_instance = building_resource.Enemy_Building.instantiate()
		
		building_instance.global_position = map_to_local(building_position)
		get_parent().add_child(building_instance)
