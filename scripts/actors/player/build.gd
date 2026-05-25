extends Node

@export var player: Player
@onready var building_ui: Control = %"Building UI"


## Connects signals for leaving build mode when the perk selector is shown
func _ready() -> void:
	GSignals.UI_show_only_PerkSelector.connect(remove_building_state)


## Toggles build mode on input release
func _physics_process(_delta: float) -> void:
	if GlobalGame.are_player_inputs_blocked():
		return
	if not GlobalGame.is_tutorial_action_allowed("build_mode"):
		return

	if Input.is_action_just_released("aktivate_building_mode"):
		if player.current_state == player.states.Default:
			player.current_state = player.states.Build
			building_ui.show()
			GSignals.TUT_build_mode_changed.emit(player, true)
		else:
			player.current_state = player.states.Default
			building_ui.hide()
			GSignals.TUT_build_mode_changed.emit(player, false)


## Forces the player back into the default state and hides the build UI
func remove_building_state() -> void:
	player.current_state = player.states.Default
	building_ui.hide()
	GSignals.TUT_build_mode_changed.emit(player, false)
