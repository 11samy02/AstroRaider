extends CanvasLayer

@export var backgrounds : Array[BackgroundRes]
@onready var texture_rect: TextureRect = $TextureRect
@export var bg_fog: EnviromentBgFog
@export var fg_fog: EnviromentFgFog

@export var background_id := 0

func _ready() -> void:
	await (get_tree().create_timer(0.1).timeout)
	randomize()
	var bg_res : BackgroundRes
	background_id = randi_range(0,backgrounds.size()-1)
	if is_instance_valid(backgrounds[background_id]):
		bg_res = backgrounds[background_id]
	else:
		bg_res = backgrounds.pick_random()
	texture_rect.texture = bg_res.texture
	texture_rect.modulate = bg_res.color
	if is_instance_valid(bg_fog):
		bg_fog.set_shader_color(bg_res.color_ramp_bg)
	if is_instance_valid(fg_fog):
		fg_fog.set_shader_color(bg_res.color_ramp_fg)
