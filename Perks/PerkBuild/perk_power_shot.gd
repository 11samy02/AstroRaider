extends PerkBuild

func activate_perk() -> void:
	super()
	stats.added_projectile_damage = get_value()
