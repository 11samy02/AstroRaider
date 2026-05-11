extends PerkBuild

## Passive: reduces hit invulnerability duration for faster recovery
func activate_perk() -> void:
	super()
	stats.set_modifier(
		stats.hit_iframe_duration_modifiers,
		Key,
		-get_invincibility_reduction()
	)

## Removes the hit invulnerability reduction applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.hit_iframe_duration_modifiers, Key)

## Returns the reduction amount for hit invulnerability duration
func get_invincibility_reduction() -> float:
	return float(get_value()) / 100.0
