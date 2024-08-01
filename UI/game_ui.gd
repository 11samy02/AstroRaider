extends CanvasLayer

@onready var label: Label = %Label
@onready var label_anim: AnimationPlayer = %label_anim

var last_wave_num:String

func _ready() -> void:
	last_wave_num = str(EntitySpawner.wave_count)

func _process(delta: float) -> void:
	label.set_text(str(EntitySpawner.wave_count))
	if last_wave_num != label.text:
		last_wave_num = label.text
		label_anim.play("wave effect")
