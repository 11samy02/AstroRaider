extends PerkBuild

var default_value := 2.00

func _enter_tree() -> void:
	default_value = stats.invincibility_frame
	super()


func activate_perk() -> void:
	await (get_tree().create_timer(0.1).timeout)
	stats.invincibility_frame = clampf(default_value - get_value()/100,0.01,default_value)

func _exit_tree() -> void:
	stats.invincibility_frame = default_value
