extends TileMap

var tiles_dict: Dictionary = {}

const GROUND_PARTICLE = preload("res://Particles/destroy_ground_particle.tscn")

func _enter_tree() -> void:
	GSignals.ENV_destroy_tile.connect(destroy_tile_at)

func _ready() -> void:
	set_live_to_tiles()

func set_live_to_tiles() -> void:
	for tile_pos in get_used_cells(0):
		var tile_Res := DestroyableTileResource.new()
		tile_Res.pos = tile_pos
		tile_Res.drop_path = "res://Objects/Collectable/crystal.tscn"
		tile_Res.drop_count.min_value = 0
		tile_Res.drop_count.max_value = 2
		
		# Speichere das Tile im Dictionary mit der Position als Schlüssel
		tiles_dict[tile_pos] = tile_Res

func destroy_tile_at(pos: Array[Vector2], damage: int = 1) -> void:
	var to_remove = []  # Liste der zu entfernenden Tiles
	var to_update = []  # Liste der Tiles, die aktualisiert werden müssen

	for i in pos:
		var tile_pos = local_to_map(i)
		
		# Greife direkt auf das Tile im Dictionary zu
		if tiles_dict.has(tile_pos):
			var tile = tiles_dict[tile_pos]
			tile.health -= damage
			
			if tile.health <= 0:
				# Partikel-Instanz hinzufügen
				var particle = GROUND_PARTICLE.instantiate()
				particle.global_position = map_to_local(tile_pos)
				get_parent().add_child(particle)
				
				# Items droppen
				drop_items(tile)
				
				# Markiere Tile zur Entfernung
				to_remove.append(tile_pos)
				erase_cell(0, tile_pos)
				
				# Umgebung des Tiles zum Aktualisieren hinzufügen
				to_update.append(tile_pos)

	# Entferne alle markierten Tiles
	for tile_pos in to_remove:
		tiles_dict.erase(tile_pos)

	# Aktualisiere umliegende Tiles
	update_surrounding_tiles(to_update)

func destroy_multiple_tiles(tile_positions: Array[Vector2], damage: int = 1) -> void:
	var to_remove = []
	var to_update = []

	for tile_pos in tile_positions:
		if tiles_dict.has(tile_pos):
			var tile = tiles_dict[tile_pos]
			tile.health -= damage
			
			if tile.health <= 0:
				# Partikel-Instanz hinzufügen und Items droppen
				var particle = GROUND_PARTICLE.instantiate()
				particle.global_position = map_to_local(tile_pos)
				get_parent().add_child(particle)
				
				drop_items(tile)
				
				# Markiere Tile zur Entfernung und aktualisiere die Umgebung
				to_remove.append(tile_pos)
				erase_cell(0, tile_pos)
				to_update.append(tile_pos)

	# Entferne alle Tiles auf einmal
	for tile_pos in to_remove:
		tiles_dict.erase(tile_pos)
	
	# Aktualisiere alle umliegenden Tiles in einem Durchgang
	update_surrounding_tiles(to_update)

func update_surrounding_tiles(tile_positions: Array):
	var unique_cells = []  # Liste für einzigartige Zellen
	for pos in tile_positions:
		unique_cells.append_array(get_custom_surrounding_cells(pos))  # Verwende die neue Methode
	
	# Entferne Duplikate
	unique_cells = unique_cells.duplicate() 
	
	# Filtere die zu aktualisierenden Zellen
	var to_update = unique_cells.filter(func(cell):
		return get_cell_source_id(0, cell) != -1
	)
	
	# Zwinge ein Update für jede umliegende Zelle durch Entfernen und erneutes Setzen
	for cell in to_update:
		var id = get_cell_source_id(0, cell)
		if id != -1:
			set_cell(0, cell, -1)  # Setze die Zelle auf leer, um ein Update zu erzwingen
			set_cell(0, cell, id)  # Setze die ursprüngliche ID erneut, um die Kachel zu aktualisieren
	
	# Anwenden der Terrain-Verbinde-Funktion
	set_cells_terrain_connect(0, to_update, 0, 0)

func drop_items(tile: DestroyableTileResource) -> void:
	var drop_count = randi_range(tile.drop_count.min_value, tile.drop_count.max_value)
	for i in range(0, drop_count):
		var item = load(tile.drop_path).instantiate()
		
		if item is CollectableTemplate:
			item.global_position = map_to_local(tile.pos)
			item.global_position += Vector2(randi_range(-4, 4), randi_range(-4, 4))
			get_parent().add_child(item)

func fill_map(size: Vector2i) -> void:
	for x in range(0, size.x):
		for y in range(0, size.y):
			set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0), 0)
	
	# Aktualisiere alle Tiles in einem Schritt
	var all_tiles = get_used_cells(0)
	update_surrounding_tiles(all_tiles)

# Neue Funktion zum Abrufen der umliegenden Zellen in allen Richtungen
func get_custom_surrounding_cells(pos: Vector2) -> Array:
	return [
		pos + Vector2(-1, 0),  # links
		pos + Vector2(1, 0),   # rechts
		pos + Vector2(0, -1),  # oben
		pos + Vector2(0, 1),   # unten
		pos + Vector2(-1, -1), # oben links
		pos + Vector2(1, -1),  # oben rechts
		pos + Vector2(-1, 1),  # unten links
		pos + Vector2(1, 1)    # unten rechts
	]
