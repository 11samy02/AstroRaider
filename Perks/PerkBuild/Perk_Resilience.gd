extends PerkBuild

## Passive: reduces invincibility frame duration (faster recovery)
func activate_perk() -> void:
	super()
	stats.set_modifier(
		stats.invincibility_frame_modifiers,
		Key,
		-get_invincibility_reduction()
	)

## Removes the invincibility frame reduction applied by this perk
func _reset_stats() -> void:
	stats.remove_modifier(stats.invincibility_frame_modifiers, Key)


## Returns the reduction amount for invincibility frames
func get_invincibility_reduction() -> float:
	return float(get_value()) / 100.0
