extends PerkBuild

func activate_perk() -> void:
	super()
	if has_unlocked:
		stats.has_stun_active = true
		stats.stun_strength = get_value()
