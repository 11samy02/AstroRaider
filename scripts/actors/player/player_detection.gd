extends Node
class_name PlayerRevealDetection

@export var player: Player
@export var grid_size := 16
@export var reveal_radius_tiles := 0

var _last_tile_pos := Vector2i(999999, 999999)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	if reveal_radius_tiles <= 0:
		return
	
	var current_tile := _get_player_tile_position()
	if current_tile == _last_tile_pos:
		return
	
	_last_tile_pos = current_tile
	_emit_reveal_positions()


## Sets the reveal radius in tiles.
func set_reveal_radius(value: int) -> void:
	reveal_radius_tiles = max(0, value)
	
	if reveal_radius_tiles <= 0:
		_last_tile_pos = Vector2i(999999, 999999)
		return
	
	_emit_reveal_positions()


## Returns the player's current tile position.
func _get_player_tile_position() -> Vector2i:
	var snap := Vector2(grid_size / 2.0, grid_size / 2.0)
	var center := player.global_position.snapped(snap)
	return Vector2i(roundi(center.x / grid_size), roundi(center.y / grid_size))


## Emits all reveal positions around the player.
func _emit_reveal_positions() -> void:
	var positions := _get_positions_in_radius()
	if positions.is_empty():
		return
	
	GSignals.PERK_show_items_behind_wall.emit(positions)


## Returns all snapped world positions inside the reveal radius.
func _get_positions_in_radius() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	if reveal_radius_tiles <= 0:
		return positions
	
	var snap := Vector2(grid_size / 2.0, grid_size / 2.0)
	var center := player.global_position.snapped(snap)
	
	for x in range(-reveal_radius_tiles, reveal_radius_tiles + 1):
		for y in range(-reveal_radius_tiles, reveal_radius_tiles + 1):
			var tile_offset := Vector2i(x, y)
			
			if Vector2(tile_offset).length() <= reveal_radius_tiles:
				var world_pos := center + Vector2(tile_offset * grid_size)
				positions.append(world_pos.snapped(snap))
	
	return positions
