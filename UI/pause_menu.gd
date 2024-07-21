extends CanvasLayer

@onready var continue_button: Button = $button_margin/TextureRect/HBoxContainer/continue
@onready var options: Button = $button_margin/TextureRect/HBoxContainer/options
@onready var titelscreen: Button = $button_margin/TextureRect/HBoxContainer/Titelscreen
@onready var exit: Button = $button_margin/TextureRect/HBoxContainer/Exit

@onready var button_margin: MarginContainer = $button_margin
@onready var color_rect: ColorRect = $ColorRect

var can_pause_on_screen := true

var has_pressed_pause := false

func _ready() -> void:
	hide()
	button_margin.modulate.a = 1
	color_rect.modulate.a = 1

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Paused"):
		check_for_paused()
	
	if Input.is_joy_button_pressed(0,JOY_BUTTON_START) and !has_pressed_pause:
		has_pressed_pause = true
		check_for_paused()
		
	if !Input.is_joy_button_pressed(0,JOY_BUTTON_START):
		has_pressed_pause = false
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and continue_button.has_focus():
		continue_pressed()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and options.has_focus():
		options_pressed()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and titelscreen.has_focus():
		titelscreen_pressed()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and exit.has_focus():
		exit_the_game()

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


func options_pressed() -> void:
	pass 


func titelscreen_pressed() -> void:
	check_for_paused()
	can_pause_on_screen = false
	get_tree().change_scene_to_file("res://Titel/start_loading.tscn")


func exit_the_game() -> void:
	get_tree().quit()
