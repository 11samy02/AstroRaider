extends CanvasLayer

@onready var continue_button: Button = %Continue
@onready var options_button: Button = %Options
@onready var return_to_title_button: Button = %Return_to_title
@onready var exit_game_button: Button = %Exit_game


@export var color_rect: ColorRect

var can_pause_on_screen := true

var has_pressed_pause := false

var new_szene : PackedScene = preload("res://Titel/start_loading.tscn")


func _ready() -> void:
	hide()
	color_rect.modulate.a = 1
	connect_signals()

func connect_signals() -> void:
	continue_button.connect("pressed", continue_pressed)
	options_button.connect("pressed", options_pressed)
	return_to_title_button.connect("pressed", titelscreen_pressed)
	exit_game_button.connect("pressed", exit_the_game)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Paused"):
		check_for_paused()

func check_for_paused() -> void:
	if can_pause_on_screen:
		if get_tree().paused:
			get_tree().paused = false
			hide()
		else:
			get_tree().paused = true
			show()
			continue_button.grab_focus()



func continue_pressed() -> void:
	check_for_paused()
	print("continue")

func options_pressed() -> void:
	pass 

func titelscreen_pressed() -> void:
	check_for_paused()
	can_pause_on_screen = false
	ScreenTransition.change_scene_to(new_szene)

func exit_the_game() -> void:
	get_tree().quit()
