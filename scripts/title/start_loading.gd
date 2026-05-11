@tool
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var margin_container: MarginContainer = $MarginContainer

@onready var new_game: Button = %new_game
@onready var options: Button = %Options
@onready var exit: Button = %Exit_game

@onready var game_szene = preload("res://scenes/game/main_game.tscn")


func _enter_tree() -> void:
	Menu.can_pause_on_screen = false
	GlobalGame.reset()


func _ready() -> void:
	GlobalGame.Players.clear()
	Menu.can_pause_on_screen = false

func _input(event: InputEvent) -> void:
	if Input.is_anything_pressed():
		if animation_player.current_animation == "show_godot_logo":
			animation_player.speed_scale = 10



func new_game_pressed() -> void:
	Menu.can_pause_on_screen = true
	ScreenTransition.change_scene_and_wait(game_szene)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	new_game.disabled = false
	options.disabled = false
	exit.disabled = false


func _on_exit_pressed() -> void:
	get_tree().quit()
