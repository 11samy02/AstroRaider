extends HBoxContainer
class_name ControllerHolder

@export var max_player_count := 4
const PlayerCard := preload("res://UI/ControllerSetup/player_card.tscn")

static var registered_controllers : Array = []
var button_hold_time := {}

func _ready() -> void:
	for i in range(max_player_count):
		var player_card : ControllerCard = PlayerCard.instantiate()
		add_child(player_card)

func _process(delta: float) -> void:
	var controllers = Input.get_connected_joypads()
	GlobalGame.Player_count = registered_controllers.size()

	if controllers.size() > 0:
		for controller in controllers:
			if Input.is_joy_button_pressed(controller, JOY_BUTTON_START) and controller not in registered_controllers:
				for player_card in get_children():
					if player_card is ControllerCard and not player_card.connected:
						player_card.assign_controller(controller)
						registered_controllers.append(controller)
						break
	
	for controller in registered_controllers:
		if Input.is_joy_button_pressed(controller, JOY_BUTTON_B):
			if controller not in button_hold_time:
				button_hold_time[controller] = 0
			button_hold_time[controller] += delta

			if button_hold_time[controller] >= 1:
				for player_card in get_children():
					if player_card is ControllerCard and player_card.assigned_controller == controller:
						player_card.clear_controller()
						break
				registered_controllers.erase(controller)
				button_hold_time.erase(controller)
		else:
			if controller in button_hold_time:
				button_hold_time.erase(controller)
	
	# Aktualisiere den Status der PlayerCards
	for player_card in get_children():
		if player_card is ControllerCard and player_card.assigned_controller != -1:
			if player_card.assigned_controller not in controllers:
				player_card.clear_controller()
				if player_card.assigned_controller in registered_controllers:
					registered_controllers.erase(player_card.assigned_controller)
