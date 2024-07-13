extends PerkBuild

var default_bohrer_damage

func _enter_tree() -> void:
	super()
	default_bohrer_damage = stats.bohrer_damage


func activate_perk() -> void:
	stats.bohrer_damage = default_bohrer_damage + Level
