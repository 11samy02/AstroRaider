extends PerkBuild

var default_max_speed
var default_gravity_strength

func _enter_tree() -> void:
	default_max_speed = stats.max_speed
	default_gravity_strength = stats.gravity_strength
	super()


func activate_perk() -> void:
	stats.max_speed = default_max_speed + default_max_speed/100 * get_value()
	stats.gravity_strength = default_gravity_strength + default_gravity_strength/100 * get_value()
	print(stats.max_speed)

func _exit_tree() -> void:
	stats.max_speed = default_max_speed
	stats.gravity_strength = default_gravity_strength
