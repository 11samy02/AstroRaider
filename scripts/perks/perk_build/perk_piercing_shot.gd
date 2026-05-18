extends PerkBuild

## Passive: projectiles pierce through additional enemies
func activate_perk() -> void:
	super()
	stats.set_modifier(stats.projectile_lives_modifiers, "perk_%s" % str(Key), float(get_value()))

## Removes the projectile pierce bonus applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.projectile_lives_modifiers, "perk_%s" % str(Key))
