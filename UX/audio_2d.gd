extends AudioStreamPlayer2D
class_name Audio2D

@export_enum("Music","Sound Effect") var type = "Sound Effect"

static var Music_volume := 0.00
static var Music_audio_on := false
static var Sound_volume := 0.00
static var Sound_audio_on := false

@export var min_random_pitch : float = 1.00
@export var max_random_pitch : float = 1.00

func _ready() -> void:
	if autoplay:
		play_sound()

func _physics_process(delta: float) -> void:
	if type == "Music":
		volume_db = Music_volume
	elif type == "Sound Effect":
		volume_db = Sound_volume
	

func play_sound() -> void:
	if (type == "Music" and !Music_audio_on) or (type == "Sound Effect" and !Sound_audio_on):
		stop()
		return
	randomize()
	pitch_scale = randf_range(min_random_pitch, max_random_pitch)
	play()
