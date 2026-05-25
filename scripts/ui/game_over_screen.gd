extends CanvasLayer

@onready var options: Button = $button/TextureRect/HBoxContainer/options
@onready var titelscreen: Button = $button/TextureRect/HBoxContainer/Titelscreen
@onready var exit: Button = $button/TextureRect/HBoxContainer/Exit

@onready var waves: Label = $MarginContainer/VBoxContainer/waves

var new_scene: PackedScene = preload("res://scenes/title/start_loading.tscn")

var is_showing := false


func _ready() -> void:
	visible = false
	$button.hide()


func game_over() -> void:
	if is_showing:
		return

	is_showing = true
	visible = true
	Menu.can_pause_on_screen = false

	waves.text = "Rounds Survived:  %s" % str(EntitySpawner.wave_count)
	$AnimationPlayer.play("Show")

	$button.show()
	titelscreen.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return

	if event.is_action_pressed("ui_accept"):
		if options.has_focus():
			_on_options_pressed()
		elif titelscreen.has_focus():
			_on_titelscreen_pressed()
		elif exit.has_focus():
			_on_exit_pressed()


func pause_game() -> void:
	get_tree().paused = true


func _on_titelscreen_pressed() -> void:
	visible = false
	is_showing = false
	$button.hide()
	ScreenTransition.change_scene_to(new_scene)
	get_tree().paused = false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	# TODO: Options-Logik
	pass
