extends PerkBuild

## Passive: increases movement speed and gravity strength
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.max_speed_modifiers, Key, stats.max_speed / 100.0 * get_value())
	stats.set_modifier(stats.gravity_strength_modifiers, Key, stats.gravity_strength / 100.0 * get_value())

## Removes the movement speed and gravity strength bonuses applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.max_speed_modifiers, Key)
	stats.remove_modifier(stats.gravity_strength_modifiers, Key)
