extends PerkBuild

var default_max_speed
var default_gravity_strength
@export var value_for_each_level := 10.0


func _enter_tree() -> void:
	default_max_speed = Player_Res.player.max_speed
	default_gravity_strength = Player_Res.player.gravity_strength

func _ready() -> void:
	activate_perk()

func activate_perk() -> void:
	Player_Res.player.max_speed = default_max_speed + default_max_speed/100 * value_for_each_level * Level
	Player_Res.player.gravity_strength = default_gravity_strength + default_gravity_strength/100 * value_for_each_level * Level
