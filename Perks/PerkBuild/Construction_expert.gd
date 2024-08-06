extends PerkBuild

var default_bohrer_damage

func _enter_tree() -> void:
	default_bohrer_damage = stats.bohrer_damage
	super()


func activate_perk() -> void:
	stats.bohrer_damage = default_bohrer_damage + get_value()
	print(get_value())
