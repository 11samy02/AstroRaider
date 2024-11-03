extends Building
class_name CrystalGenerator

@onready var collect_crystal: AudioStreamPlayer2D = $Sounds/CollectCrystal

var Ores: Dictionary = {}

var player_list : Array[Player] = []

func _on_area_entered(area: Area2D) -> void:
	if area is ItemCrystal:
		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == area.player_who_collected:
				player_res.crystal_count += area.value
				break
		area.destroy()
		collect_crystal.play()
	
	if area is OreTemplate:
		if Ores.has(area.Ore_type):
			Ores[area.Ore_type] += 1
		else:
			Ores.get_or_add(area.Ore_type, 0)
			Ores[area.Ore_type] += 1
		area.destroy()
		collect_crystal.play()


func _on_check_player_nearby_body_entered(body: Node2D) -> void:
	if body is Player:
		player_list.append(body)


func _on_check_player_nearby_body_exited(body: Node2D) -> void:
	if body is Player:
		player_list.erase(body)

func _process(delta: float) -> void:
	check_player_input()


func check_player_input() -> void:
	for player in player_list:
		if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) or Input.is_action_just_pressed("interact"):
			GSignals.PLA_open_skill_tree.emit(player)
