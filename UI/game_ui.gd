extends CanvasLayer

@onready var label: Label = %Label
@onready var label_anim: AnimationPlayer = %label_anim
@onready var fps_label: Label = %fps_label
@onready var wave_progress: TextureProgressBar = %wave_progress


var last_wave_num:String

func _ready() -> void:
	last_wave_num = str(EntitySpawner.wave_count)

func _process(delta: float) -> void:
	fps_label.set_text("fps: " + str(Engine.get_frames_per_second()))
	label.set_text(str(EntitySpawner.wave_count))
	if !EntitySpawner.wave_time_stopped:
		wave_progress.show()
	else:
		wave_progress.hide()
	
	wave_progress.max_value = EntitySpawner.wave_time_max_time
	wave_progress.value = EntitySpawner.wave_time_to_next
	
	if last_wave_num != label.text:
		last_wave_num = label.text
		label_anim.play("wave effect")
