extends PerkBuild

## Passive: increases critical hit chance
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.crit_chance_modifiers, Key, float(get_value()))

## Removes the critical hit chance bonus applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.crit_chance_modifiers, Key)
