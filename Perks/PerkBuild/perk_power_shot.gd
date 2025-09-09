extends PerkBuild

func activate_perk() -> void:
	super()
	if has_unlocked:
		stats.added_projectile_damage = get_value()
	else:
		stats.added_projectile_damage = 0
