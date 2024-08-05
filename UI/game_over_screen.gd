extends CanvasLayer

@onready var options: Button = $button/TextureRect/HBoxContainer/options
@onready var titelscreen: Button = $button/TextureRect/HBoxContainer/Titelscreen
@onready var exit: Button = $button/TextureRect/HBoxContainer/Exit

@onready var waves: Label = $MarginContainer/VBoxContainer/waves

var is_showing := false

func _ready() -> void:
	visible = false

func game_over():
	if !is_showing:
		is_showing = true
		visible = true
		PauseMenu.can_pause_on_screen = false
		waves.set_text("Rounds Survived:  " + str(EntitySpawner.wave_count))
		titelscreen.grab_focus()
		$AnimationPlayer.play("Show")

func _input(event: InputEvent) -> void:
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and options.has_focus():
		_on_options_pressed()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and titelscreen.has_focus():
		_on_titelscreen_pressed()
	
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) and exit.has_focus():
		_on_exit_pressed()

func pause_game():
	get_tree().paused = true
	


func _on_titelscreen_pressed() -> void:
	visible = false
	is_showing = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Titel/start_loading.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	pass # Replace with function body.
