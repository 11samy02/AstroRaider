extends PerkBuild

## Passive: increases projectile damage
func activate_perk() -> void:
	super()
	stats.added_projectile_damage = get_value()

func _reset_stats() -> void:
	stats.added_projectile_damage = 0
