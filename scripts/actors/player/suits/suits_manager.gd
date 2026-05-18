extends Node
class_name SuitsManager

@export var player: Player

var _active_suit: SuitMechanics


func _enter_tree() -> void:
	for child in get_children():
		if child is SuitMechanics:
			child.set_active(false)


## Activates the suit mechanics node that matches the player's selected suit.
func _ready() -> void:
	_refresh_active_suit()


## Switches weapon logic to the suit matching the given key.
func set_active_suit(suit_key: SuitData.SuitKeys) -> void:
	if is_instance_valid(_active_suit):
		_active_suit.set_active(false)
		_active_suit = null

	for child in get_children():
		if child is SuitMechanics and child.suit_key == suit_key:
			_active_suit = child
			child.set_active(true)
			return


func _refresh_active_suit() -> void:
	if not is_instance_valid(player):
		return
	set_active_suit(player.selected_suit)
