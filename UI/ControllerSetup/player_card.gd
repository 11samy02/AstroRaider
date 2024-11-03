extends NinePatchRect
class_name ControllerCard

@onready var icon: TextureRect = $MarginContainer/icon
@onready var label: Label = $MarginContainer/Label

var connected := false
var assigned_controller := -1

func assign_controller(controller: int) -> void:
	connected = true
	assigned_controller = controller
	label.text = Input.get_joy_name(controller)
	icon.texture = load("res://Sprites/UI/ControllerSelect/controller.png")

func clear_controller() -> void:
	connected = false
	assigned_controller = -1
	label.text = "Press Start"
	icon.texture = load("res://Sprites/UI/ControllerSelect/controller_inaktiv.png")
