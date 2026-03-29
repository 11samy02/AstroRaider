extends PerkBuild

## Passive: increases projectile damage
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.projectile_damage_modifiers, Key, float(get_value()))

## Removes the projectile damage bonus applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.projectile_damage_modifiers, Key)
