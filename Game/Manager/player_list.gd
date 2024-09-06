extends Node2D
class_name PlayerList


func _enter_tree() -> void:
	GSignals.PERK_reset_perks_from_player_id.connect(reset_perk_from_player)

func _ready() -> void:
	GlobalGame.Players.clear()
	for player in get_children():
		if player is Player:
			var player_res : PlayerResource = PlayerResource.new()
			player_res.player = player
			GlobalGame.Players.append(player_res)
			
	spawn_healtbars_to_players()
	spawn_detector_to_player()
	
	for i in range(0,GlobalGame.Players.size()):
		add_perks_to_player(i)


func spawn_healtbars_to_players():
	for player_res: PlayerResource in GlobalGame.Players:
		var healthbar = preload("res://Actors/player/Healthbar.tscn").instantiate()
		healthbar.parent_entity = player_res.player
		healthbar.global_position = player_res.player.global_position
		add_child(healthbar)


func add_perks_to_player(id:int):
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.player.player_id == id:
			var stats = player_res.player.stats
			for perk: Perk in stats.Perks:
				var perk_szene = PerkData.load_perk_scene(perk.Key).instantiate()
				if perk_szene is PerkBuild:
					perk_szene.Player_Res = player_res
					perk_szene.Level = perk.level
				add_child(perk_szene)
			

func reset_perk_from_player(id:int) -> void:
	for perk_build in get_children():
		if perk_build is PerkBuild:
			if perk_build.Player_Res.player.player_id == id:
				perk_build.queue_free()
	
	add_perks_to_player(id)

func spawn_detector_to_player() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		var detector = preload("res://Actors/player/detector.tscn").instantiate()
		detector.player = player_res.player
		add_child(detector)
