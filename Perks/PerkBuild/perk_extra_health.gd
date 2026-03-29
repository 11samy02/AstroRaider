extends PerkBuild

var _previous_value := -1

## Passive: increases maximum health
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.max_hp_modifiers, Key, float(get_value()))

	if _previous_value != get_value():
		GSignals.PERK_Extra_health.emit()
		_previous_value = get_value()

## Removes the maximum health bonus applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.max_hp_modifiers, Key)
	_previous_value = -1
