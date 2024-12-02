extends PerkBuild

const BARRIER_SHIELD = preload("res://Objects/Perk Specials/barrier_shield.tscn")


func _enter_tree() -> void:
	GSignals.PERK_barrier_shield_destroyed.connect(on_shield_destroyed)
	GSignals.WAV_wave_endet.connect(reset_shield)

func activate_perk() -> void: 
	if !Player_Res.shield_res.has_shield and !Player_Res.shield_res.used_shield_in_round:
		Player_Res.shield_res.has_shield = true
		Player_Res.shield_res.used_shield_in_round = true
		
		var new_shield = BARRIER_SHIELD.instantiate()
		new_shield.entity = Player_Res.player
		new_shield.global_position = Player_Res.player.global_position
		new_shield.Health = get_value() 
		
		Player_Res.player.get_parent().add_child(new_shield)


func on_shield_destroyed() -> void:
	Player_Res.shield_res.has_shield = false

func reset_shield() -> void:
	Player_Res.shield_res.used_shield_in_round = false
