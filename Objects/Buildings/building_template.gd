extends Area2D
class_name Building

@onready var sprite: AnimatedSprite2D = $sprite

@export var radar_icon: Texture2D

@export_category("Fuel")
@export var has_fuel := false
@export var max_fuel := 100
@export var fuel_used := 1

@export_category("Health")
@export var has_health := false
@export var max_health := 100
@export var current_health := 100


var current_fuel : int = max_fuel

var is_placed := true
var building_owner : Player

func _process(delta: float) -> void:
	if has_fuel:
		fuel_check()
	if has_health:
		check_health()

func fuel_check() -> void:
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


func check_health() -> void:
	if current_health <= 0:
		death()
		set_process(false)

func repair_health(amount: int) -> void:
	if has_health:
		if current_health + amount < max_health:
			current_health += amount
		else:
			current_health = max_health

func _enter_tree() -> void:
	GlobalGame.Buildings.append(self)
	current_health = max_health

func _exit_tree() -> void:
	GlobalGame.Buildings.erase(self)

##has to be overwritten for better deads
func death():
	queue_free()

func get_hit():
	pass
