extends Area2D
class_name CrystalGenerator

@onready var collect_crystal: Audio2D = $Sounds/CollectCrystal

func _on_area_entered(area: Area2D) -> void:
	if area is ItemCrystal:
		area.destroy()
		collect_crystal.play_sound()
