extends PerkBuild

@export var reveal: PlayerRevealDetection

var _previous_value := -1


func activate_perk() -> void:
	super()
	
	var res := get_player_res()
	if is_instance_valid(res) and selected_in_run :
		res.has_perk_anti_mine_det = true
	
	var current_value := get_value()
	if current_value != _previous_value:
		if is_instance_valid(reveal):
			reveal.set_reveal_radius(current_value)
		_previous_value = current_value


func _reset_stats() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.has_perk_anti_mine_det = false
	
	if is_instance_valid(reveal):
		reveal.set_reveal_radius(0)
	
	_previous_value = -1


func level_up_perk() -> void:
	super()
	
	var res := get_player_res()
	if is_instance_valid(res):
		res.has_perk_anti_mine_det = true
	
	var current_value := get_value()
	if is_instance_valid(reveal):
		reveal.set_reveal_radius(current_value)
	
	_previous_value = current_value
