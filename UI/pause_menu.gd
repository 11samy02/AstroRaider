extends CanvasLayer

@onready var continue_button: Button = $button_margin/TextureRect/HBoxContainer/continue
@onready var options: Button = $button_margin/TextureRect/HBoxContainer/options
@onready var titelscreen: Button = $button_margin/TextureRect/HBoxContainer/Titelscreen
@onready var exit: Button = $button_margin/TextureRect/HBoxContainer/Exit

@onready var button_margin: MarginContainer = $button_margin
@onready var color_rect: ColorRect = $ColorRect

var can_pause_on_screen := true

func _ready() -> void:
	hide()
	button_margin.modulate.a = 1
	color_rect.modulate.a = 1

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Paused"):
		check_for_paused()
	
	
	for player_id in range(0, GlobalGame.Players.size() - 1):
		if Input.is_joy_button_pressed(player_id,JOY_BUTTON_START):
			check_for_paused()
			break

func check_for_paused() -> void:
	if can_pause_on_screen:
		if get_tree().paused:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true
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
