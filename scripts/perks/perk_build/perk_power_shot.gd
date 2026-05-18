extends PerkBuild


## Passive: increases projectile damage.
## Uses hybrid scaling:
## - Always gives at least +1 damage per perk level
## - Later scales with suit-scaled projectile damage
## - Damage bonus stays as a whole number
func activate_perk() -> void:
	super()

	if not has_valid_runtime_refs():
		return

	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return

	var suit_scaled_projectile_damage := stats.get_suit_scaled_projectile_damage(suit_modifier_id)

	var minimum_bonus := float(Level)
	var percent_bonus 	= round(suit_scaled_projectile_damage * get_value_percent())

	var bonus_damage := maxf(minimum_bonus, percent_bonus)

	stats.set_modifier(stats.projectile_damage_modifiers, get_perk_modifier_id(), bonus_damage)


## Removes the projectile damage bonus applied by this perk.
func _reset_stats() -> void:
	if is_instance_valid(stats):
		stats.remove_modifier(stats.projectile_damage_modifiers, get_perk_modifier_id())
