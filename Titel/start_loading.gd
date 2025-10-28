@tool
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var margin_container: MarginContainer = $MarginContainer

@onready var continue_button: Button = $MarginContainer/TextureRect/HBoxContainer/continue
@onready var new_game: Button = $MarginContainer/TextureRect/HBoxContainer/new_game
@onready var options: Button = $MarginContainer/TextureRect/HBoxContainer/options
@onready var perks: Button = $MarginContainer/TextureRect/HBoxContainer/perks
@onready var exit: Button = $MarginContainer/TextureRect/HBoxContainer/Exit
@onready var animation_player_2: AnimationPlayer = $AnimationPlayer2

@onready var game_szene = preload("res://Game/main_game.tscn")


func _enter_tree() -> void:
	PauseMenu.can_pause_on_screen = false
	GlobalGame.reset()


func _ready() -> void:
	GlobalGame.Players.clear()
	PauseMenu.can_pause_on_screen = false
	margin_container.size = margin_container.get_minimum_size()
	new_game.grab_focus()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		margin_container.size = margin_container.get_minimum_size()

func _input(event: InputEvent) -> void:
	if Input.is_anything_pressed():
		if animation_player.current_animation == "show_godot_logo":
			animation_player.speed_scale = 10



func new_game_pressed() -> void:
	if animation_player_2.is_playing():
		PauseMenu.can_pause_on_screen = true
		ScreenTransition.change_scene_and_wait(game_szene)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_player_2.play("loop")
	continue_button.disabled = false
	new_game.disabled = false
	options.disabled = false
	perks.disabled = false
	exit.disabled = false


func _on_exit_pressed() -> void:
	get_tree().quit()
