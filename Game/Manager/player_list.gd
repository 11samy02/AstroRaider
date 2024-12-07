extends Node2D
class_name PlayerList

func _enter_tree() -> void:
	GSignals.PERK_reset_perks_from_controller_id.connect(reset_perk_from_player)

func set_players() -> void:
	GlobalGame.Players.clear()
	var id = 0
	for player in get_children():
		if player is Player:
			var player_res : PlayerResource = PlayerResource.new()
			player_res.player = player
			player_res.Role = load("res://Resources/Characters/Roles/Role_Trailblazer.tres")
			GlobalGame.Players.append(player_res)
			
			if !ControllerHolder.registered_controllers.is_empty():
				player_res.player.player_id = ControllerHolder.registered_controllers[id]
				player_res.player.player_id = id
			
			var skill_tree : SkillTree = RolesData.load_Skill_Tree_scene(player_res.Role.Role_key).instantiate()
			skill_tree.player_res = player_res
			skill_tree.Role
			
			add_child(skill_tree)
			
			id += 1
			
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
			if perk_build.Player_Res.player.controller_id == id:
				perk_build.queue_free()
	
	add_perks_to_player(id)

func spawn_detector_to_player() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		var detector = preload("res://Actors/player/detector.tscn").instantiate()
		detector.player = player_res.player
		add_child(detector)
		
		var detector2 = preload("res://Actors/player/detector.tscn").instantiate()
		detector2.player = player_res.player
		detector2.can_destroy = false
		detector2.detector_count = 9
		add_child(detector2)
