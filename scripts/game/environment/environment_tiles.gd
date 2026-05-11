extends Node
class_name EnvironmentTiles

const GROUND_PARTICLE = preload("res://scenes/particles/destroy_ground_particle.tscn")

@export var TileDrops: Array[TileDropResource]

var tiles_dict: Dictionary = {}

@onready var env: Enviroment = get_parent()


## Refreshes all used tiles terrain connections in batches to avoid frame drops
func force_refresh_all() -> void:
	var used := env.get_used_cells()
	if used.is_empty():
		await get_tree().process_frame
		return
	await get_tree().process_frame
	var batch := []
	var to_live := []
	for cell in used:
		batch.append(cell)
		to_live.append(cell)
		if batch.size() >= env.batch_size:
			env.set_cells_terrain_connect(batch, env.terrain_set_id, env.terrain_id)
			batch.clear()
			await get_tree().process_frame
	if batch.size() > 0:
		env.set_cells_terrain_connect(batch, env.terrain_set_id, env.terrain_id)
		batch.clear()
	set_live_to_tiles(to_live)
	await update_surrounding_tiles_batched(to_live, env.batch_size)


## Assigns drop and health data to tiles that don't yet have an entry in tiles_dict
func set_live_to_tiles(tiles_to_process: Array = []) -> void:
	if tiles_to_process.is_empty():
		tiles_to_process = env.get_used_cells()
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
		if not ("health" in tr):
			tr.health = 3
		tiles_dict[tile_pos] = tr


## Applies damage to tiles at the given world positions and removes destroyed ones
func destroy_tile_at(pos: Array[Vector2], damage: int = 1) -> void:
	if pos.is_empty():
		return
	
	var uniq := {}
	for w in pos:
		uniq[Vector2i(env.local_to_map(w))] = true
	var all_pos: Array[Vector2i] = []
	for k in uniq.keys():
		all_pos.append(k)

	var PARTICLE_BUDGET_PER_BATCH := 60
	var DROP_BUDGET_PER_BATCH := 35

	var i := 0
	while i < all_pos.size():
		var end = min(i + env.batch_size, all_pos.size())
		var removed: Array[Vector2i] = []
		var particles_used := 0
		var drops_used := 0

		for j in range(i, end):
			var tile_pos := all_pos[j]
			if tiles_dict.has(tile_pos):
				var tile: DestroyableTileResource = tiles_dict[tile_pos]
				tile.health -= damage
				if tile.health <= 0:
					if particles_used < PARTICLE_BUDGET_PER_BATCH:
						var particle = GROUND_PARTICLE.instantiate()
						particle.global_position = env.map_to_local(tile_pos)
						env.get_parent().add_child(particle)
						particles_used += 1

					if drops_used < DROP_BUDGET_PER_BATCH:
						drop_items(tile)
						drops_used += 1

					env.erase_cell(tile_pos)
					tiles_dict.erase(tile_pos)
					removed.append(tile_pos)

		if not removed.is_empty():
			var remset := {}
			for p in removed:
				remset[p] = true

			var border: Array[Vector2i] = []
			for p in removed:
				for n in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var q = p + n
					if not remset.has(q) and env.get_cell_source_id(q) != -1:
						border.append(q)

			if not border.is_empty():
				if border.size() > 64:
					await update_surrounding_tiles_batched(border, 128)
				else:
					update_surrounding_tiles(border)

		await get_tree().process_frame
		i = end


## Spawns drop items from a destroyed tile into the world
func drop_items(tile: DestroyableTileResource) -> void:
	var dc = env.rng.randi_range(tile.drop_count.min_value, tile.drop_count.max_value)
	for _i in range(dc):
		var scene = DropData.load_drop_szene(tile.key)
		if scene == null:
			continue
		var item = scene.instantiate()
		var wpos = env.map_to_local(tile.pos)
		if item is CollectableTemplate:
			item.global_position = wpos + Vector2(env.rng.randi_range(-4, 4), env.rng.randi_range(-4, 4))
			env.get_parent().add_child(item)
		elif item is StaticEnemy or item is OreTemplate:
			item.global_position = wpos
			env.get_parent().add_child(item)


## Refreshes terrain connections for tiles surrounding the given positions
func update_surrounding_tiles(tile_positions: Array) -> void:
	var unique_cells = {}
	for pos in tile_positions:
		var surrounding_cells = get_custom_surrounding_cells(pos)
		for cell in surrounding_cells:
			unique_cells[cell] = true
	var to_update = []
	for cell in unique_cells.keys():
		if env.get_cell_source_id(cell) != -1:
			to_update.append(cell)
	if to_update.is_empty():
		return
	var batch = []
	var tiles_to_process = []
	while not to_update.is_empty():
		batch.append(to_update.pop_back())
		if batch.size() >= env.batch_size:
			await get_tree().process_frame
			for cell in batch:
				env.set_cell(cell, -1)
				tiles_to_process.append(cell)
			env.set_cells_terrain_connect(batch, 0, 0)
			batch.clear()
	if batch.size() > 0:
		for cell in batch:
			env.set_cell(cell, -1)
			tiles_to_process.append(cell)
		env.set_cells_terrain_connect(batch, 0, 0)
	set_live_to_tiles(tiles_to_process)


## Refreshes surrounding tiles in frame-yielding batches to avoid stalls
func update_surrounding_tiles_batched(tile_positions: Array, batch_size: int = 25) -> void:
	var unique_cells = {}
	for pos in tile_positions:
		var surrounding_cells = get_custom_surrounding_cells(pos)
		for cell in surrounding_cells:
			unique_cells[cell] = true
	var to_update = []
	for cell in unique_cells.keys():
		if env.get_cell_source_id(cell) != -1:
			to_update.append(cell)
	if to_update.is_empty():
		return
	var index = 0
	var total = to_update.size()
	while index < total:
		var batch = to_update.slice(index, index + batch_size)
		for cell in batch:
			env.set_cell(cell, 0)
		env.set_cells_terrain_connect(batch, 0, 0)
		set_live_to_tiles(batch)
		index += batch_size
		await get_tree().process_frame


## Returns all 8 neighboring cell positions around a given tile
func get_custom_surrounding_cells(pos: Vector2i) -> Array:
	var neighbors = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			neighbors.append(pos + Vector2i(dx, dy))
	return neighbors


## Picks a random drop from TileDrops weighted by rarity
func get_random_drop() -> TileDropResource:
	var list: Array[TileDropResource] = []
	for t in TileDrops:
		for _rar in t.rarity:
			list.append(t)
	if list.is_empty():
		return null
	return list[env.rng.randi_range(0, list.size() - 1)]
