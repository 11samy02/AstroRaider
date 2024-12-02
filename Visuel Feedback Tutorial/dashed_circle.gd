extends Line2D
class_name DashedCircle

@export var radius: float = 60.0
@export var segments: int = 128
var dash_length: float = 10.0
var dash_gap: float = 5.0

func _ready():
	scale = Vector2(0.1,0.1)
	draw_dashed_circle()

func draw_dashed_circle():
	clear_points()
	var total_length = dash_length + dash_gap
	var segment_angle = TAU / segments
	var current_angle = 0.0

	while current_angle < TAU:
		var start_point = Vector2(cos(current_angle), sin(current_angle)) * radius
		current_angle += dash_length / (radius * TAU)
		var end_point = Vector2(cos(current_angle), sin(current_angle)) * radius
		add_point(start_point)
		add_point(end_point)
		current_angle += dash_gap / (radius * TAU)
	
	var tween = create_tween()
	tween.TRANS_ELASTIC
	tween.EASE_IN
	tween.tween_property(self,"scale", Vector2(1,1), 0.3)
	if randi_range(0,1) == 0:
		tween.parallel().tween_property(self, "rotation_degrees", 180, 0.5)
	else:
		tween.parallel().tween_property(self, "rotation_degrees", -180, 0.5)
