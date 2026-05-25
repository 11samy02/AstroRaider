extends Control

@export var player: Player

@onready var ores: VBoxContainer = $MarginContainer/Ores
@onready var margin_container: MarginContainer = $MarginContainer
@onready var building_button_row: HBoxContainer = $MarginContainer/HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	building_button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for ore_counter: OreCounterLabel in ores.get_children():
		ore_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ore_counter.player = player
