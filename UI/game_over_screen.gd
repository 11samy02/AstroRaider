extends CanvasLayer

@onready var options: Button = $button/TextureRect/HBoxContainer/options
@onready var titelscreen: Button = $button/TextureRect/HBoxContainer/Titelscreen
@onready var exit: Button = $button/TextureRect/HBoxContainer/Exit
@onready var username: LineEdit = $UserScore/TextureRect/HBoxContainer/Username


@onready var waves: Label = $MarginContainer/VBoxContainer/waves
@onready var list: VBoxContainer = $Scoreboard/TextureRect/HBoxContainer/List
@onready var user_score: PanelContainer = $"Scoreboard/TextureRect/HBoxContainer/your rank/UserScore"
@onready var save: Button = $UserScore/TextureRect/HBoxContainer/save
@onready var continue_button: Button = $"Scoreboard/TextureRect/HBoxContainer/your rank/Continue"

var is_showing := false

const SCORE_PLAYER = preload("res://UI/score_player.tscn")

func _ready() -> void:
	visible = false
	$button.hide()
	$Scoreboard.hide()
	$UserScore.show()

func game_over():
	if !is_showing:
		is_showing = true
		visible = true
		PauseMenu.can_pause_on_screen = false
		waves.set_text("Rounds Survived:  " + str(EntitySpawner.wave_count))
		titelscreen.grab_focus()
		$AnimationPlayer.play("Show")
		username.grab_focus()

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
	$UserScore.hide()
	$Scoreboard.show()
	$button.hide()
	await (FirebaseSync.request_finished)
	FirebaseSync.get_highscores()
	await (FirebaseSync.request_finished)
	
	var count = 1
	for score in FirebaseSync.All_Highscores:
		if list.get_child_count() < 8:
			var score_label = SCORE_PLAYER.instantiate()
			
			score_label.get_child(0).text = str(count) + ". " + score.player_name + " | " + str(score.wave)
			count += 1
			
			list.add_child(score_label)
		else:
			break
	
	user_score.get_child(0).text = username.text + " | " + str(EntitySpawner.wave_count)
	
	continue_button.grab_focus()


func _process(delta: float) -> void:
	if save.has_focus() and Input.is_joy_button_pressed(0, JOY_BUTTON_A):
		_on_save_pressed()
	
	if continue_button.has_focus() and Input.is_joy_button_pressed(0, JOY_BUTTON_A):
		_on_continue_pressed()


func _on_continue_pressed() -> void:
	$Scoreboard.hide()
	$button.show()
