extends PerkBuild

## Passive: increases bohrer (drill) damage
func activate_perk() -> void:
	super()
	stats.added_bohrer_damage = get_value()

func _reset_stats() -> void:
	stats.added_bohrer_damage = 0.0
