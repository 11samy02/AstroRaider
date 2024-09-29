extends PerkBuild

var default_health = 50

func _enter_tree() -> void:
	super()

func activate_perk() -> void:
	stats.max_hp = default_health + get_value()
	GSignals.PERK_Extra_health.emit()

func _exit_tree() -> void:
	pass
