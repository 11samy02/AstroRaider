extends Sprite2D

func _ready() -> void:
	var tween = create_tween()
	await get_tree().create_timer(1).timeout
	queue_free()

func _set_icon(key: DropData.Keys) -> void:
	var Keys = DropData.Keys
	if key == Keys.Crystal:
		modulate.a = 0
	elif key == Keys.Copper:
		frame = 1
	elif key == Keys.Gold:
		frame = 2
	elif key == Keys.Iron:
		frame = 3
	elif key == Keys.Bomb_key:
		frame = 0
