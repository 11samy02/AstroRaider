extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _input(event: InputEvent) -> void:
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if animation_player.current_animation == "show_godot_logo":
			animation_player.speed_scale = 10


func new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Game/main_game.tscn")
