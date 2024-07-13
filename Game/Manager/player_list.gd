extends Node2D


func _ready() -> void:
	GlobalGame.Players.clear()
	for player in get_children():
		if player is Player:
			var player_res : PlayerResource = PlayerResource.new()
			player_res.player = player
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
		var stats = player_res.player.stats
		for perk: Perk in stats.Perks:
			var perk_szene = PerkData.load_perk(perk.Key).instantiate()
			perk_szene.Player_Res = player_res
			add_child(perk_szene)
			
