extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var new_game: Button = %new_game
@onready var options: Button = %Options
@onready var exit: Button = %Exit_game

const GAME_SCENE_PATH := "res://scenes/game/main_game.tscn"


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
	GlobalGame.is_in_tutorial = false
	_start_game_scene()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	new_game.disabled = false
	options.disabled = false
	exit.disabled = false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_tutorial_game_pressed() -> void:
	GlobalGame.is_in_tutorial = true
	Menu.can_pause_on_screen = true
	_start_game_scene()


func _start_game_scene() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		push_error("Failed to load game scene: %s" % GAME_SCENE_PATH)
		return
	
	ScreenTransition.change_scene_and_wait(game_scene)


func _on_delete_saves_pressed() -> void:
	pass # Replace with function body.


func _on_cheat_mode_pressed() -> void:
	pass # Replace with function body.
