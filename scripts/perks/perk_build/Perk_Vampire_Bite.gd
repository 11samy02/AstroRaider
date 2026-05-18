extends PerkBuild


## Connects to the enemy kill signal.
func _enter_tree() -> void:
	if not GSignals.ENE_killed_by.is_connected(_on_enemy_killed):
		GSignals.ENE_killed_by.connect(_on_enemy_killed)


## Disconnects the enemy kill signal.
func _exit_tree() -> void:
	if GSignals.ENE_killed_by.is_connected(_on_enemy_killed):
		GSignals.ENE_killed_by.disconnect(_on_enemy_killed)


## Heals the player when they kill an enemy.
func _on_enemy_killed(killed_by: Player) -> void:
	if not selected_in_run:
		return

	if killed_by != player:
		return

	if not has_valid_runtime_refs():
		return

	var heal_percent := float(get_value()) / 1000.0
	var heal_amount := maxf(1.0, round(stats.get_max_hp_total() * heal_percent))

	GSignals.HIT_take_heal.emit(player, heal_amount)
