extends PerkBuild

func activate_perk() -> void:
	super()
	stats.added_max_speed = stats.max_speed/100 * get_value()
	stats.added_gravity_strength = stats.gravity_strength /100 * get_value()
