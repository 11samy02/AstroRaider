extends Node

var Players: Array[PlayerResource] = []

var camera: MainCam

var max_entitys_on_screen = 80
var entity_list: Array[EnemyBaseTemplate]

func _process(delta: float) -> void:
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset() -> void:
	entity_list.clear()
	Players.clear()
