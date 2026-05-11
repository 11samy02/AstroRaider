extends Node2D

@export var player: Player

@onready var building_symbol: Node2D = $Building_Symbol

func _process(delta: float) -> void:
	if player.current_state == player.states.Build:
		building_symbol.show()
	else:
		building_symbol.hide()
