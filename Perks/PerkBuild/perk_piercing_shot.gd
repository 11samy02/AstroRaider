extends PerkBuild

## Passive: projectiles pierce through additional enemies
func activate_perk() -> void:
	super()
	stats.added_Projectile_lives = get_value()

func _reset_stats() -> void:
	stats.added_Projectile_lives = 0
