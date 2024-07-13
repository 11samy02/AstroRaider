extends PerkBuild

var default_bohrer_damage

func _enter_tree() -> void:
	default_bohrer_damage = Player_Res.player.bohrer_damage

func _ready() -> void:
	activate_perk()


func activate_perk() -> void:
	print("it worked")
	Player_Res.player.bohrer_damage = default_bohrer_damage + Level
