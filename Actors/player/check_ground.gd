extends Area2D

@export var player_hand: PlayerHand

var defauls_grid_size := 16

func _process(delta: float) -> void:
	set_building_collision()

func set_building_collision() -> void:
	if get_child(0).shape is RectangleShape2D:
		var rect_shape = get_child(0).shape as RectangleShape2D
		if player_hand.building_res != null:
			rect_shape.size = player_hand.building_res.size * defauls_grid_size
			rect_shape.size -= Vector2(1,1)
