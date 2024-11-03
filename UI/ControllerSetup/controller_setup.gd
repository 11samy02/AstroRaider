extends Control


func _enter_tree() -> void:
	PauseMenu.can_pause_on_screen = false


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		ScreenTransition.change_scene_and_wait(load("res://Game/main_game.tscn"))
