extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var margin_container: MarginContainer = $MarginContainer

@onready var continue_button: Button = $MarginContainer/TextureRect/HBoxContainer/continue
@onready var new_game: Button = $MarginContainer/TextureRect/HBoxContainer/new_game
@onready var options: Button = $MarginContainer/TextureRect/HBoxContainer/options
@onready var perks: Button = $MarginContainer/TextureRect/HBoxContainer/perks



func _ready() -> void:
	PauseMenu.can_pause_on_screen = false
	margin_container.size = margin_container.get_minimum_size()
	new_game.grab_focus()

func _input(event: InputEvent) -> void:
	if Input.is_anything_pressed():
		if animation_player.current_animation == "show_godot_logo":
			animation_player.speed_scale = 10


func new_game_pressed() -> void:
	PauseMenu.can_pause_on_screen = true
	get_tree().change_scene_to_file("res://Game/main_game.tscn")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	continue_button.disabled = false
	new_game.disabled = false
	options.disabled = false
	perks.disabled = false
