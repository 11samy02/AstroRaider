extends Sprite2D
class_name ItemWallNotification
var pos : Vector2i

@onready var timer: Timer = $Timer

func _enter_tree() -> void:
	GSignals.ENV_reset_timer_for_wall_notification.connect(_increasee_time)

func _ready() -> void:
	scale = Vector2.ZERO
	timer.set_wait_time(1.0 + randf_range(-0.25,0.25))
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.75,0.75), 0.25)
	await tween.finished

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


func _on_timer_timeout() -> void:
	GSignals.ENV_remove_tile_from_wall.emit(pos)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	await tween.finished
	queue_free()

func _increasee_time(p: Vector2i) -> void:
	if p != pos:
		return
	timer.start()
