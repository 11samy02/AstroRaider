extends Control


func _enter_tree() -> void:
	Menu.can_pause_on_screen = false


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		if GlobalGame.tutorial == 1:
			GlobalGame.is_in_tutorial = false
		ScreenTransition.change_scene_and_wait(load("res://scenes/game/main_game.tscn"))
