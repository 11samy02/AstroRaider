extends PerkBuild

func activate_perk() -> void:
	super()
	if has_unlocked:
		stats.added_Projectile_lives = get_value()
	else:
		stats.added_Projectile_lives = 0
