extends PerkBuild

var default_crit_chance

func _enter_tree() -> void:
	default_crit_chance = stats.crit_chance
	super()


func activate_perk() -> void:
	stats.crit_chance = default_crit_chance + 1 * get_value()

func _exit_tree() -> void:
	stats.crit_chance = default_crit_chance
