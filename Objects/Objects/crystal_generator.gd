extends Area2D
class_name CrystalGenerator

@onready var collect_crystal: AudioStreamPlayer2D = $Sounds/CollectCrystal

var Ores: Dictionary = {}

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
