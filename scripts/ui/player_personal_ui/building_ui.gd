extends Control

@export var player: Player

@onready var ores: VBoxContainer = $MarginContainer/Ores


func _ready() -> void:
	for ore_counter: OreCounterLabel in ores.get_children():
		ore_counter.player = player
