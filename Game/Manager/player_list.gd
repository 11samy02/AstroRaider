extends Node2D


func _ready() -> void:
	GlobalGame.Players.clear()
	for player in get_children():
		if player.is_in_group("Player"):
			var player_res : PlayerResource = PlayerResource.new()
			player_res.player = player
			
			var new_perk = load("res://Perks/Resources/Speed_it_up.tres")
			player_res.perks.append(new_perk)
			
			var new_perk_2 = load("res://Perks/Resources/Construction_expert.tres")
			player_res.perks.append(new_perk_2)
			
			GlobalGame.Players.append(player_res)
			
	spawn_healtbars_to_players()
	add_perks_to_player()


func spawn_healtbars_to_players():
	for player_res: PlayerResource in GlobalGame.Players:
		var healthbar = preload("res://Actors/player/Healthbar.tscn").instantiate()
		healthbar.parent_entity = player_res.player
		healthbar.global_position = player_res.player.global_position
		add_child(healthbar)


func add_perks_to_player():
	for player_res: PlayerResource in GlobalGame.Players:
		for perk: Perk in player_res.perks:
			var perk_szene = PerkData.load_perk(perk.Key).instantiate()
			perk_szene.Player_Res = player_res
			add_child(perk_szene)
			
