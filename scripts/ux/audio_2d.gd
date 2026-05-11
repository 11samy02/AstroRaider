extends AudioStreamPlayer2D
class_name Audio2D

@export var min_random_pitch: float = 0.95
@export var max_random_pitch: float = 1.05


func play_sound() -> void:
	var sfx_bus := AudioServer.get_bus_index("Sfx")
	
	if AudioServer.get_bus_index(bus) == sfx_bus:
		pitch_scale = randf_range(min_random_pitch, max_random_pitch)
	else:
		pitch_scale = 1.0
	
	play()
