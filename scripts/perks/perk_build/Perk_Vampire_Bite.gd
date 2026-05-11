extends PerkBuild

## Connects to the enemy kill signal
func _enter_tree() -> void:
	GSignals.ENE_killed_by.connect(_on_enemy_killed)


## Disconnects the enemy kill signal
func _exit_tree() -> void:
	if GSignals.ENE_killed_by.is_connected(_on_enemy_killed):
		GSignals.ENE_killed_by.disconnect(_on_enemy_killed)


## Heals the player when they kill an enemy
func _on_enemy_killed(killed_by: Player) -> void:
	if !selected_in_run :
		return
	if killed_by == player:
		GSignals.HIT_take_heal.emit(player, get_value())
