extends PerkBuild

## Passive: increases critical hit chance
func activate_perk() -> void:
	super()
	stats.added_crit_chance = get_value()

func _reset_stats() -> void:
	stats.added_crit_chance = 0.0
