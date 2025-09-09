extends PerkBuild

var default_value := 2.00



func activate_perk() -> void:
	await (get_tree().create_timer(0.1).timeout)
	stats.added_invincibility_frame = clampf(stats.invincibility_frame - get_value()/100,0.01, stats.invincibility_frame)
