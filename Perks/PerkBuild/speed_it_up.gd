extends PerkBuild

## Passive: increases movement speed and gravity strength
func activate_perk() -> void:
	super()
	stats.added_max_speed = stats.max_speed / 100.0 * get_value()
	stats.added_gravity_strength = stats.gravity_strength / 100.0 * get_value()

func _reset_stats() -> void:
	stats.added_max_speed = 0.0
	stats.added_gravity_strength = 0.0
