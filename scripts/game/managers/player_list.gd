extends Node2D
class_name PlayerList

const PLAYER_HAND = preload("res://scenes/actors/player/player_hand.tscn")

func _enter_tree() -> void:
	GSignals.PERK_reset_perks_from_controller_id.connect(reset_perk_from_player)


func set_players() -> void:
	GlobalGame.Players.clear()
	var id = 0

	for player in get_children():
		if player is Player:
			var player_res: PlayerResource = PlayerResource.new()
			player_res.player = player
			var start_max_hp := int(player.stats.get_max_hp_total())
			player_res.max_health = start_max_hp
			player_res.current_health = start_max_hp

			var player_hand = PLAYER_HAND.instantiate()
			player_hand.player_res = player_res
			add_child(player_hand)
			player_res.player_hand = player_hand

			GlobalGame.Players.append(player_res)

			if !ControllerHolder.registered_controllers.is_empty():
				player_res.player.player_id = ControllerHolder.registered_controllers[id]
				player_res.player.player_id = id

			id += 1

	for i in range(0, GlobalGame.Players.size()):
		add_perks_to_player(i)


func add_perks_to_player(id: int) -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.player.player_id == id:
			var stats = player_res.player.stats
			for perk: Perk in stats.Perks:
				var perk_scene_res := PerkData.load_perk_scene(perk.Key)
				if not is_instance_valid(perk_scene_res):
					continue
				var perk_szene = perk_scene_res.instantiate()
				if perk_szene is PerkBuild:
					perk_szene.player = player_res.player
					perk_szene.Level = perk.level
					perk_szene.selected_in_run = true
					add_child(perk_szene)


func reset_perk_from_player(id: int) -> void:
	for perk_build in get_children():
		if perk_build is PerkBuild:
			if is_instance_valid(perk_build.player) and perk_build.player.player_id == id:
				perk_build.queue_free()
	
	add_perks_to_player(id)
