extends PerkBuild

func activate_perk() -> void:
	player.stats.added_crit_chance = player.stats.crit_chance + 1 * get_value()
