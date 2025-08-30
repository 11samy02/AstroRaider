extends Node

var Player_count: int = 1
var Players: Array[PlayerResource] = []

var Enemies: Array[EnemyBaseTemplate] = []
var Buildings: Array[Building]

var camera: MainCam

var time_played := 0.00



func _process(delta: float) -> void:
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	

func reset():
	Players.clear()
	Enemies.clear()
	Buildings.clear()
	camera = null
