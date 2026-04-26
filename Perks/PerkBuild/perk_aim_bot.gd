extends PerkBuild

## Connects the shooting signal
func _enter_tree() -> void:
	GSignals.PLA_is_shooting.connect(_on_player_shoot)


## Disconnects the shooting signal
func _exit_tree() -> void:
	if GSignals.PLA_is_shooting.is_connected(_on_player_shoot):
		GSignals.PLA_is_shooting.disconnect(_on_player_shoot)


## Activates aim assist on player projectiles when the player shoots
func _on_player_shoot(ply: Player) -> void:
	if selected_in_run  and ply == player:
		GSignals.PERK_Aim_bot_activate.emit(player, get_value())
