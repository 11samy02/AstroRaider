extends CanvasLayer

@onready var options: Button = %options
@onready var titelscreen: Button = %Titelscreen
@onready var exit: Button = %Exit
@onready var username: LineEdit = %username
@onready var enter_username: VBoxContainer = $button/Scoreboard/enterUsername
@onready var scoreboard_list: VBoxContainer = $button/Scoreboard/scoreboardList
@onready var list: VBoxContainer = $button/Scoreboard/scoreboardList/list
@onready var scoreboard: TextureRect = $button/Scoreboard
@onready var menu: TextureRect = $button/menu

@onready var waves: Label = $MarginContainer/VBoxContainer/waves

var is_showing := false


const PLAYER_SCORE = preload("res://UI/Game Over screen/highscore_single.tscn")


func _ready() -> void:
	visible = false
	scoreboard.show()
	menu.hide()
	enter_username.show()
	scoreboard_list.hide()

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


func _on_save_pressed() -> void:
	FirebaseSync.send_highscore(username.text, EntitySpawner.wave_count)
	enter_username.hide()
	FirebaseSync.get_highscores()
	
	for child in list.get_children():
		child.queue_free()
	
	for highscore in FirebaseSync.All_Highscores:
		if list.get_child_count() < 5:
			var score = PLAYER_SCORE.instantiate()
			
			score.get_child(0).text = score.player_name + str(score.wave)
			list.add_child(score)
		else:
			break
	
	scoreboard_list.show()


func _on_continue_pressed() -> void:
	scoreboard.hide()
	menu.show()
