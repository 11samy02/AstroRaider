extends Node
class_name EnvironmentReveal

const ITEM_IN_WALL_NOTIFICATION = preload("res://scenes/tutorials/visual_feedback/item_in_wall_notification.tscn")

var wall_notification: Array[Vector2i]

@onready var env: Enviroment = get_parent()


## Shows an icon above tiles that contain items hidden behind walls
func show_items_behind_wall(pos: Array[Vector2]) -> void:
	for i in pos:
		var tile_pos = Vector2i(env.local_to_map(i))
		if env.tiles.tiles_dict.has(tile_pos):
			if !wall_notification.has(tile_pos):
				var tile: DestroyableTileResource = env.tiles.tiles_dict[tile_pos]
				if tile.key != DropData.Keys.Crystal:
					var notification = ITEM_IN_WALL_NOTIFICATION.instantiate()
					notification.global_position = i
					notification._set_icon(tile.key)
					wall_notification.append(tile_pos)
					notification.pos = tile_pos
					env.get_parent().add_child(notification)
			else:
				GSignals.ENV_reset_timer_for_wall_notification.emit(tile_pos)


## Removes a tile position from the wall notification tracking list
func remove_tile_from_wall(pos_tile: Vector2i) -> void:
	if wall_notification.has(pos_tile):
		wall_notification.erase(pos_tile)
