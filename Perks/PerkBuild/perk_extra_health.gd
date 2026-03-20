extends PerkBuild

## Passive: increases maximum health
func activate_perk() -> void:
	super()
	stats.added_max_hp = get_value()
	GSignals.PERK_Extra_health.emit()

func _reset_stats() -> void:
	stats.added_max_hp = 0
