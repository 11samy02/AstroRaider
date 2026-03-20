extends Node

@export var enviroment : Enviroment
@export var key_labels : Array[Label]
@export var wasd_tutorial : CanvasLayer

var s_wait_for_movement := false
var wait_for_movement := false
var required_inputs = {
	"ui_up": false,
	"ui_down": false,
	"ui_left": false,
	"ui_right": false
}

func _ready() -> void:
	if !GlobalGame.is_in_tutorial:
		queue_free()
	connect_signals()

func connect_signals() -> void:
	enviroment.map_was_created.connect(start_dialogic)
	Dialogic.signal_event.connect(dialog_event)


func _process(delta: float) -> void:
	wait_for_movement_handler()

##Put as a Parameter the name of the Dialogic Timeline to start it
func start_dialogic(dialog_name : String = "Waking UP") -> void:
	Dialogic.start(dialog_name)

func dialog_event(argument : String) -> void:
	if argument == "wait_for_wasd_input":
		s_wait_for_movement = true
		wasd_tutorial.show()

func wait_for_movement_handler() -> void:
	if s_wait_for_movement and !wait_for_movement:
		
		if Input.is_action_just_pressed("ui_up"):
			required_inputs["ui_up"] = true
			key_labels[0].hide()
	
		if Input.is_action_just_pressed("ui_down"):
			required_inputs["ui_down"] = true
			key_labels[1].hide()
	
		if Input.is_action_just_pressed("ui_left"):
			required_inputs["ui_left"] = true
			key_labels[2].hide()
	
		if Input.is_action_just_pressed("ui_right"):
			required_inputs["ui_right"] = true
			key_labels[3].hide()
	
		# Check if all true
		if required_inputs.values().count(false) == 0:
			wait_for_movement = true
			wasd_tutorial.hide()
			start_dialogic("Shooting Tutorial")
