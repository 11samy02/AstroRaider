extends PerkBuild

## Passive: enables stun on hit and sets stun strength
func activate_perk() -> void:
	super()
	stats.has_stun_active = true
	stats.stun_strength = get_value()

func _reset_stats() -> void:
	stats.has_stun_active = false
	stats.stun_strength = 0.0
