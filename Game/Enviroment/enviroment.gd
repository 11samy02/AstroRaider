extends TileMap

var tiles_array: Array[DestroyableTileResource] = []

var default_tiles

func _enter_tree() -> void:
	GSignals.ENV_destroy_tile.connect(destroy_tile_at)

func _ready() -> void:
	set_live_to_tiles()

func set_live_to_tiles() -> void:
	for tile in get_used_cells(0):
		var tile_Res := DestroyableTileResource.new()
		
		tile_Res.pos = tile
		tile_Res.drop_path = "res://Objects/Collectable/crystal.tscn"
		tile_Res.drop_count.min_value = 1
		tile_Res.drop_count.max_value = 2
		
		tiles_array.append(tile_Res)

func destroy_tile_at(pos: Vector2, damage: int = 1) -> void:
	var tile_pos = local_to_map(pos)
	
	
	for tile: DestroyableTileResource in tiles_array:
		if tile.pos == tile_pos:
			tile.health -= damage
		
		if tile.health <= 0:
			drop_items(tile)
			tiles_array.erase(tile)
			erase_cell(0, tile_pos)
			update_surrounding(tile_pos)
			

func drop_items(tile: DestroyableTileResource) -> void:
	var drop_count = randi_range(tile.drop_count.min_value, tile.drop_count.max_value)
	for i in range(0 ,drop_count):
		
		var item = load(tile.drop_path).instantiate()
		
		if item is CollectableTemplate:
				item.global_position = map_to_local(tile.pos)
				item.global_position += Vector2(randi_range(-4,4), randi_range(-4,4))
				get_parent().add_child(item)
	

func update_surrounding(pos: Vector2):
	var surrounding = get_surrounding_cells(pos)
	var to_update = []
	for cell in surrounding:
		if get_cell_source_id(0, cell) != -1:
			to_update += [cell]
	for cell in to_update:
		set_cell(0, cell)
	set_cells_terrain_connect(0, to_update, 0, 0)
