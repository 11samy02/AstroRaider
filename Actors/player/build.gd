extends Node

@export var player: Player
@onready var building_ui: Control = %"Building UI"

func _ready() -> void:
	GSignals.UI_show_only_PerkSelector.connect(remove_building_state)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_released("aktivate_building_mode"):
		if player.current_state == player.states.Default:
			player.current_state = player.states.Build
			building_ui.show()
		else:
			player.current_state = player.states.Default
			building_ui.hide()

func remove_building_state() -> void:
	player.current_state = player.states.Default
	building_ui.hide()
