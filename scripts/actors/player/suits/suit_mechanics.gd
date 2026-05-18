extends Node2D
class_name SuitMechanics

@export var suit_key: SuitData.SuitKeys = SuitData.SuitKeys.NONE
@export var player: Player

var is_active := false


## Enables or disables this suit's runtime weapon logic.
func set_active(active: bool) -> void:
	is_active = active
	visible = active
	set_process(active)
	set_process_input(active)
	if not active:
		_on_deactivated()


## Called when this suit is hidden or another suit is selected.
func _on_deactivated() -> void:
	pass


## Returns the suit resource for this mechanics node.
func get_suit_data() -> SuitData:
	if not is_instance_valid(player):
		return null
	if player.get_selected_suit_data().Key == suit_key:
		return player.get_selected_suit_data()
	return SuitData.load_suit_res(suit_key)
