extends Node

var Players: Array[PlayerResource] = []

var camera: MainCam

func _process(delta: float) -> void:
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
