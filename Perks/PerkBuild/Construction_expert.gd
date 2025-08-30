extends PerkBuild

func activate_perk() -> void:
	super()
	stats.added_bohrer_damage = stats.bohrer_damage + get_value()
