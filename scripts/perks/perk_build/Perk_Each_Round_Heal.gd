extends PerkBuild


## Connects to the wave end signal.
func _enter_tree() -> void:
	if not GSignals.WAV_wave_endet.is_connected(_on_wave_ended):
		GSignals.WAV_wave_endet.connect(_on_wave_ended)


## Disconnects the wave end signal.
func _exit_tree() -> void:
	if GSignals.WAV_wave_endet.is_connected(_on_wave_ended):
		GSignals.WAV_wave_endet.disconnect(_on_wave_ended)


## Heals the player at the end of each wave.
func _on_wave_ended() -> void:
	if not selected_in_run:
		return

	if not has_valid_runtime_refs():
		return

	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return

	var suit_scaled_max_hp := stats.get_suit_scaled_max_hp(suit_modifier_id)
	var heal_amount := float(round(suit_scaled_max_hp * get_value_percent()))

	GSignals.HIT_take_heal.emit(player, heal_amount)
