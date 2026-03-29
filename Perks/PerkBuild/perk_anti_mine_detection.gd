extends PerkBuild

var _previous_value := -1


## Passive: reveals items hidden behind walls
func activate_perk() -> void:
	super()

	if _previous_value != get_value():
		GSignals.PERK_add_vision_behind_wall.emit(player, get_value())
		_previous_value = get_value()

	var res := get_player_res()
	if is_instance_valid(res) and has_unlocked:
		res.has_perk_anti_mine_det = true


## Resets the perk effects when disabled
func _reset_stats() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.has_perk_anti_mine_det = false


## Ensures the flag is set when leveling up
func level_up_perk() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.has_perk_anti_mine_det = true
	super()
