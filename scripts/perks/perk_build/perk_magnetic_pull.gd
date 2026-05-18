extends PerkBuild

var _previous_value := -1


## Passive: increases pickup radius for all collectables.
func activate_perk() -> void:
	super()
	
	if not selected_in_run:
		return
	
	if _previous_value == get_value():
		return
	
	_previous_value = get_value()
	GSignals.PERK_magnetic_pull_changed.emit()


func _reset_stats() -> void:
	if _previous_value == -1:
		return
	
	_previous_value = -1
	GSignals.PERK_magnetic_pull_changed.emit()
