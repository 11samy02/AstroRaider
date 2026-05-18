extends PerkBuild


## Passive: increases movement speed and gravity strength by a percentage of suit-scaled values.
func activate_perk() -> void:
	super()

	if not has_valid_runtime_refs():
		return

	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return

	var percent := get_value_percent()

	stats.set_modifier(
		stats.max_speed_modifiers,
		get_perk_modifier_id(),
		stats.get_suit_scaled_max_speed(suit_modifier_id) * percent
	)

	stats.set_modifier(
		stats.gravity_strength_modifiers,
		get_perk_modifier_id(),
		stats.get_suit_scaled_gravity_strength(suit_modifier_id) * percent
	)


## Removes the movement speed and gravity strength bonuses applied by this perk.
func _reset_stats() -> void:
	if is_instance_valid(stats):
		stats.remove_modifier(stats.max_speed_modifiers, get_perk_modifier_id())
		stats.remove_modifier(stats.gravity_strength_modifiers, get_perk_modifier_id())
