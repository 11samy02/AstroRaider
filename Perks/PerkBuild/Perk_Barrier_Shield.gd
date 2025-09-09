extends PerkBuild

const BARRIER_SHIELD = preload("res://Objects/Perk Specials/barrier_shield.tscn")

var player_res : PlayerResource

func _enter_tree() -> void:
	GSignals.PERK_barrier_shield_destroyed.connect(on_shield_destroyed)
	GSignals.WAV_wave_endet.connect(reset_shield)

func _ready() -> void:
	super()

func _input(event: InputEvent) -> void:
	if !has_unlocked:
		return
	if Input.is_action_just_pressed("aktivat_perk"):
		activate_perk()

func activate_perk() -> void:
	if !is_instance_valid(player_res):
		for ply_res : PlayerResource in GlobalGame.Players:
			if ply_res.player == player:
				player_res = ply_res
	if !is_instance_valid(player_res):
		printerr("Player Res is empty: ", player_res)
		return
	if !player_res.shield_res.has_shield and !player_res.shield_res.used_shield_in_round:
		player_res.shield_res.has_shield = true
		player_res.shield_res.used_shield_in_round = true
		
		var new_shield = BARRIER_SHIELD.instantiate()
		new_shield.entity = player_res.player
		new_shield.global_position = player_res.player.global_position
		new_shield.Health = get_value() 
		
		player_res.player.get_parent().add_child(new_shield)

func on_shield_destroyed() -> void:
	if !is_instance_valid(player_res):
		return
	player_res.shield_res.has_shield = false

func reset_shield() -> void:
	if !is_instance_valid(player_res):
		return
	player_res.shield_res.used_shield_in_round = false
