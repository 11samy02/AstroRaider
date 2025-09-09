extends PerkBuild

func activate_perk() -> void:
	stats.added_max_hp = get_value()
	GSignals.PERK_Extra_health.emit()

func _exit_tree() -> void:
	pass
