extends PerkBuild

var default_max_speed
var default_gravity_strength
@export var value_for_each_level := 10

func _enter_tree() -> void:
	default_max_speed = stats.max_speed
	default_gravity_strength = stats.gravity_strength
	print(stats.max_speed, " ", default_max_speed)
	super()


func activate_perk() -> void:
	stats.max_speed = default_max_speed + default_max_speed/100 * value_for_each_level * Level
	stats.gravity_strength = default_gravity_strength + default_gravity_strength/100 * value_for_each_level * Level
