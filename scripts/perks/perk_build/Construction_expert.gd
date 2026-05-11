extends PerkBuild

## Passive: increases bohrer (drill) damage
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.bohrer_damage_modifiers, Key, float(get_value()))

## Removes the drill damage bonus applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.bohrer_damage_modifiers, Key)
