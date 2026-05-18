extends PerkBuild

var _previous_value := -1


## Passive: increases maximum health by a percentage of the selected suit's scaled max HP.
func activate_perk() -> void:
	super()

	if not has_valid_runtime_refs():
		return

	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return

	var bonus_hp := stats.get_suit_scaled_max_hp(suit_modifier_id) * get_value_percent()

	stats.set_modifier(stats.max_hp_modifiers, get_perk_modifier_id(), bonus_hp)

	if _previous_value != get_value():
		_previous_value = get_value()
		GSignals.PERK_Extra_health.emit()


## Removes the maximum health bonus applied by this perk.
func _reset_stats() -> void:
	if is_instance_valid(stats):
		stats.remove_modifier(stats.max_hp_modifiers, get_perk_modifier_id())
	
	_previous_value = -1
