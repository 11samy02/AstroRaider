extends HBoxContainer
class_name ScreenScaler

@onready var ui_left: SubViewportContainer = $"Ui-Left"
@onready var main_game: SubViewportContainer = $MainGame
@onready var ui_right: SubViewportContainer = $"Ui-Right"

var left_is_visible = false
var right_is_visible = false

func _ready() -> void:
	await (get_tree().create_timer(1).timeout)
	left_is_visible = true
	right_is_visible = true
	scale_down_game()
	await (get_tree().create_timer(1).timeout)
	left_is_visible = false
	right_is_visible = false
	scale_up_game()


func scale_down_game():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	if left_is_visible and right_is_visible:
		tween.tween_property(main_game,"custom_minimum_size", Vector2(960,1080), 0.8)
	elif left_is_visible or right_is_visible:
		tween.tween_property(main_game,"custom_minimum_size", Vector2(1440,1080), 0.8)

func scale_up_game():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	if !left_is_visible and !right_is_visible:
		tween.tween_property(main_game,"custom_minimum_size", Vector2(1920,1080), 0.8)
	elif !left_is_visible or !right_is_visible:
		tween.tween_property(main_game,"custom_minimum_size", Vector2(1440,1080), 0.8)
