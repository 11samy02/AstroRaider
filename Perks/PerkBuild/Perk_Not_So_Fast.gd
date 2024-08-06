extends PerkBuild

var default_value

func _enter_tree() -> void:
	default_value = stats.invincibility_frame
	super()


func activate_perk() -> void:
	stats.invincibility_frame = default_value - get_value()/100

func _exit_tree() -> void:
	stats.invincibility_frame = default_value


