extends PerkBuild

@export var value_break := 2
@export var value_strength := 10

var default_gravity_break
var default_gravity_strength

func _enter_tree() -> void:
	default_gravity_break = stats.gravity_break
	default_gravity_strength = stats.gravity_strength
	super()
	


func activate_perk() -> void:
	stats.gravity_break = default_gravity_break + Level * value_break
	stats.gravity_strength = default_gravity_strength + default_gravity_strength / 100 * value_strength * Level
