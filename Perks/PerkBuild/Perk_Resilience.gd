extends PerkBuild

## Passive: reduces invincibility frame duration (faster recovery)
func activate_perk() -> void:
	super()
	stats.added_invincibility_frame = clampf(
		stats.invincibility_frame - get_value() / 100.0,
		0.01,
		stats.invincibility_frame
	)

func _reset_stats() -> void:
	stats.added_invincibility_frame = 0.0
