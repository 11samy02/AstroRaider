extends Node

var Player_count: int = 3
var Players: Array[PlayerResource] = []

var Enemies: Array[EnemyBaseTemplate] = []
var Buildings: Array[CrystalGenerator]

var camera: MainCam

func _process(delta: float) -> void:
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
