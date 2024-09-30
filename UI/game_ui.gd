extends CanvasLayer

@onready var label: Label = %Label
@onready var label_anim: AnimationPlayer = %label_anim

@onready var texture_progress_bar: TextureProgressBar = $Control/MarginContainer/Label/TextureProgressBar

var last_wave_num:String

func _ready() -> void:
	last_wave_num = str(EntitySpawner.wave_count)

func _process(delta: float) -> void:
	label.set_text(str(EntitySpawner.wave_count))
	if !EntitySpawner.wave_time_stopped:
		texture_progress_bar.show()
	else:
		texture_progress_bar.hide()
	
	texture_progress_bar.max_value = EntitySpawner.wave_time_max_time
	texture_progress_bar.value = EntitySpawner.wave_time_to_next
	
	if last_wave_num != label.text:
		last_wave_num = label.text
		label_anim.play("wave effect")
