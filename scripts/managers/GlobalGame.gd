extends Node

var Player_count: int = 1
var Players: Array[PlayerResource] = []
var Player_Support: Array[Node2D] = []

var Enemies: Array[EnemyBaseTemplate] = []
var Bosses: Array[BossEntity] = []
var Buildings: Array[Building]

var camera: MainCam

var time_played := 0.00

# 0 = tutorial can run, 1 = tutorial is skipped/completed.
var tutorial: int = 0
var is_in_tutorial := true
var player_input_blocked_by_dialogic := false
var tutorial_allowed_actions: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Dialogic.timeline_started.is_connected(_on_dialogic_timeline_started):
		Dialogic.timeline_started.connect(_on_dialogic_timeline_started)
	if not Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)


func _process(_delta: float) -> void:
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_dialogic_timeline_started() -> void:
	player_input_blocked_by_dialogic = true


func _on_dialogic_timeline_ended() -> void:
	player_input_blocked_by_dialogic = false


func are_player_inputs_blocked() -> bool:
	if Dialogic.current_timeline != null:
		player_input_blocked_by_dialogic = true
		return true

	player_input_blocked_by_dialogic = false
	return false


func set_tutorial_allowed_actions(actions: Array[String]) -> void:
	tutorial_allowed_actions.clear()
	for action in actions:
		tutorial_allowed_actions[action] = true


func clear_tutorial_allowed_actions() -> void:
	tutorial_allowed_actions.clear()


func is_tutorial_action_allowed(action: String) -> bool:
	if not is_in_tutorial or tutorial == 1:
		return true

	return tutorial_allowed_actions.has(action)


func reset():
	Players.clear()
	Enemies.clear()
	Bosses.clear()
	Buildings.clear()
	camera = null
	player_input_blocked_by_dialogic = false
	clear_tutorial_allowed_actions()
