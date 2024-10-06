extends Area2D
class_name Building

@onready var sprite: AnimatedSprite2D = $sprite

@export_category("Fuel")
@export var has_fuel := false
@export var max_fuel := 100
@export var fuel_used := 1



var current_fuel : int = max_fuel

var is_placed := true
var building_owner : Player

func _process(delta: float) -> void:
	if has_fuel:
		fuel_check()

func fuel_check():
	if current_fuel >= max_fuel/3:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color.WHITE, 0.5)
		
	elif current_fuel <= max_fuel/3 and current_fuel > 0:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color("#aeaeae"), 0.5)
		
	else:
		var tween = create_tween()
		tween.tween_property(self,"modulate",Color("#df7d7d"), 0.5)

func _collect_fuel(area: Area2D) -> void:
	if has_fuel:
		if area is ItemCrystal:
			if current_fuel <= max_fuel:
				current_fuel += area.value
				area.destroy()
