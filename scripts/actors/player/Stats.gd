extends Resource
class_name Stats


#region Default Stats

@export_group("Default")
## Base gravity acceleration before modifiers.
@export var gravity_strength := 200.0

## Counter-force used by movement to slow gravity influence.
@export var gravity_break := 2.0

## Base movement speed before modifiers.
@export var max_speed := 250.0

## Base energy pool used by slowness mechanics.
@export var slowness_energy := 100.0

## Base drill damage before modifiers.
@export var bohrer_damage := 1.0

## Base drill knockback before modifiers.
@export var bohrer_knockback := 3.0

## Base invulnerability duration after the player is hit.
@export var hit_iframe_duration := 1.0

## Playback speed for the player hit animation.
@export var hit_animation_speed := 1.0

## Base aiming rotation speed.
@export var rotation_speed := 10.0

## Base maximum health before modifiers.
@export var max_hp := 100

## Base armor divisor before modifiers.
@export var armor := 1.0

## Base critical hit chance before modifiers.
@export var crit_chance := 0.0

## Base projectile damage bonus before modifiers.
@export var projectile_damage := 0.0

## Base attack cooldown before modifiers.
@export var attack_speed := 0.4

#endregion


#region Modifier Arrays

@export_group("Modifiers")
## Runtime modifiers applied to gravity strength.
@export var gravity_strength_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to gravity break.
@export var gravity_break_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to movement speed.
@export var max_speed_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to slowness energy.
@export var slowness_energy_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to drill damage.
@export var bohrer_damage_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to drill knockback.
@export var bohrer_knockback_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to hit invulnerability duration.
@export var hit_iframe_duration_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to aiming rotation speed.
@export var rotation_speed_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to maximum health.
@export var max_hp_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to armor.
@export var armor_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to critical hit chance.
@export var crit_chance_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to projectile damage.
@export var projectile_damage_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to projectile lives.
@export var projectile_lives_modifiers: Array[StatModifier] = []

## Runtime modifiers applied to attack cooldown.
@export var attack_speed_modifiers: Array[StatModifier] = []

#endregion


#region Perk Runtime Values

@export_group("Perks")
## Base amount of extra projectile hits before modifiers.
@export var projectile_lives := 0.0

## Perks granted by this stat profile or saved player build.
@export var Perks: Array[Perk] = []

## Whether projectiles currently apply stun.
@export var has_stun_active := false

## Active stun strength applied by projectile attacks.
@export var stun_strength := 0.0

#endregion


#region Modifier Helpers

## Adds a new modifier or updates the existing modifier for the given modifier id.
func set_modifier(modifiers: Array[StatModifier], modifier_id: String, new_value: float) -> void:
	if modifier_id == "":
		return

	for modifier in modifiers:
		if not is_instance_valid(modifier):
			continue

		if modifier.modifier_id == modifier_id:
			modifier.value = new_value
			return

	var new_modifier := StatModifier.new()
	new_modifier.modifier_id = modifier_id
	new_modifier.value = new_value
	modifiers.append(new_modifier)


## Removes the modifier entry for the given modifier id.
func remove_modifier(modifiers: Array[StatModifier], modifier_id: String) -> void:
	if modifier_id == "":
		return

	for i in range(modifiers.size() - 1, -1, -1):
		var modifier := modifiers[i]

		if not is_instance_valid(modifier):
			modifiers.remove_at(i)
			continue

		if modifier.modifier_id == modifier_id:
			modifiers.remove_at(i)
			return


## Returns the summed value of all valid modifiers in the given list.
func get_modifier_total(modifiers: Array[StatModifier]) -> float:
	var total := 0.0

	for modifier in modifiers:
		if not is_instance_valid(modifier):
			continue

		total += modifier.value

	return total


## Returns the value of one specific modifier by id.
func get_modifier_value(modifiers: Array[StatModifier], modifier_id: String) -> float:
	if modifier_id == "":
		return 0.0

	for modifier in modifiers:
		if not is_instance_valid(modifier):
			continue

		if modifier.modifier_id == modifier_id:
			return modifier.value

	return 0.0


## Returns true if a modifier with the given id exists.
func has_modifier(modifiers: Array[StatModifier], modifier_id: String) -> bool:
	if modifier_id == "":
		return false

	for modifier in modifiers:
		if not is_instance_valid(modifier):
			continue

		if modifier.modifier_id == modifier_id:
			return true

	return false


## Removes invalid modifier entries from the given list.
func clean_modifiers(modifiers: Array[StatModifier]) -> void:
	for i in range(modifiers.size() - 1, -1, -1):
		if not is_instance_valid(modifiers[i]):
			modifiers.remove_at(i)

#endregion


#region Movement Total Getters

## Returns the final gravity strength including all modifiers.
func get_gravity_strength_total() -> float:
	return gravity_strength + get_modifier_total(gravity_strength_modifiers)


## Returns the final gravity break including all modifiers.
func get_gravity_break_total() -> float:
	return gravity_break + get_modifier_total(gravity_break_modifiers)


## Returns the final movement speed including all modifiers.
func get_max_speed_total() -> float:
	return max_speed + get_modifier_total(max_speed_modifiers)


## Returns the final slowness energy including all modifiers.
func get_slowness_energy_total() -> float:
	return slowness_energy + get_modifier_total(slowness_energy_modifiers)

#endregion


#region Mining Total Getters

## Returns the final drill damage including all modifiers.
func get_bohrer_damage_total() -> float:
	return bohrer_damage + get_modifier_total(bohrer_damage_modifiers)


## Returns the final drill knockback including all modifiers.
func get_bohrer_knockback_total() -> float:
	return bohrer_knockback + get_modifier_total(bohrer_knockback_modifiers)

#endregion


#region Defense Total Getters

## Returns the final hit invulnerability duration including all modifiers.
func get_hit_iframe_duration_total() -> float:
	return maxf(0.05, hit_iframe_duration + get_modifier_total(hit_iframe_duration_modifiers))


## Returns the configured hit animation speed.
func get_hit_animation_speed() -> float:
	return maxf(0.05, hit_animation_speed)


## Returns the final maximum health including all modifiers.
func get_max_hp_total() -> float:
	return float(max_hp) + round(get_modifier_total(max_hp_modifiers))


## Returns the final armor including all modifiers.
func get_armor_total() -> float:
	return armor + get_modifier_total(armor_modifiers)

#endregion


#region Combat Total Getters

## Returns the final rotation speed including all modifiers.
func get_rotation_speed_total() -> float:
	return rotation_speed + get_modifier_total(rotation_speed_modifiers)


## Returns the final crit chance including all modifiers.
func get_crit_chance_total() -> float:
	return crit_chance + get_modifier_total(crit_chance_modifiers)


## Returns the final projectile damage including all modifiers.
func get_projectile_damage_total() -> float:
	return projectile_damage + get_modifier_total(projectile_damage_modifiers)


## Returns the final projectile lives including all modifiers.
func get_projectile_lives_total() -> float:
	return projectile_lives + get_modifier_total(projectile_lives_modifiers)


## Returns the final attack cooldown including all modifiers.
func get_attack_speed_total() -> float:
	return maxf(0.05, attack_speed + get_modifier_total(attack_speed_modifiers))

#endregion


#region Movement Suit-Scaled Getters

## Returns base gravity strength + the selected suit level gravity strength bonus.
func get_suit_scaled_gravity_strength(suit_modifier_id: String) -> float:
	return gravity_strength + get_modifier_value(gravity_strength_modifiers, suit_modifier_id)


## Returns base gravity break + the selected suit level gravity break bonus.
func get_suit_scaled_gravity_break(suit_modifier_id: String) -> float:
	return gravity_break + get_modifier_value(gravity_break_modifiers, suit_modifier_id)


## Returns base max speed + the selected suit level max speed bonus.
func get_suit_scaled_max_speed(suit_modifier_id: String) -> float:
	return max_speed + get_modifier_value(max_speed_modifiers, suit_modifier_id)


## Returns base slowness energy + the selected suit level slowness energy bonus.
func get_suit_scaled_slowness_energy(suit_modifier_id: String) -> float:
	return slowness_energy + get_modifier_value(slowness_energy_modifiers, suit_modifier_id)

#endregion


#region Mining Suit-Scaled Getters

## Returns base drill damage + the selected suit level drill damage bonus.
func get_suit_scaled_bohrer_damage(suit_modifier_id: String) -> float:
	return bohrer_damage + get_modifier_value(bohrer_damage_modifiers, suit_modifier_id)


## Returns base drill knockback + the selected suit level drill knockback bonus.
func get_suit_scaled_bohrer_knockback(suit_modifier_id: String) -> float:
	return bohrer_knockback + get_modifier_value(bohrer_knockback_modifiers, suit_modifier_id)

#endregion


#region Defense Suit-Scaled Getters

## Returns base hit iframe duration + the selected suit level iframe bonus.
func get_suit_scaled_hit_iframe_duration(suit_modifier_id: String) -> float:
	return maxf(0.05, hit_iframe_duration + get_modifier_value(hit_iframe_duration_modifiers, suit_modifier_id))


## Returns base max HP + the selected suit level max HP bonus.
func get_suit_scaled_max_hp(suit_modifier_id: String) -> float:
	return float(max_hp) + get_modifier_value(max_hp_modifiers, suit_modifier_id)


## Returns base armor + the selected suit level armor bonus.
func get_suit_scaled_armor(suit_modifier_id: String) -> float:
	return armor + get_modifier_value(armor_modifiers, suit_modifier_id)

#endregion


#region Combat Suit-Scaled Getters

## Returns base rotation speed + the selected suit level rotation speed bonus.
func get_suit_scaled_rotation_speed(suit_modifier_id: String) -> float:
	return rotation_speed + get_modifier_value(rotation_speed_modifiers, suit_modifier_id)


## Returns base crit chance + the selected suit level crit chance bonus.
func get_suit_scaled_crit_chance(suit_modifier_id: String) -> float:
	return crit_chance + get_modifier_value(crit_chance_modifiers, suit_modifier_id)


## Returns base projectile damage + the selected suit level projectile damage bonus.
func get_suit_scaled_projectile_damage(suit_modifier_id: String) -> float:
	return projectile_damage + get_modifier_value(projectile_damage_modifiers, suit_modifier_id)


## Returns base projectile lives + the selected suit level projectile lives bonus.
func get_suit_scaled_projectile_lives(suit_modifier_id: String) -> float:
	return projectile_lives + get_modifier_value(projectile_lives_modifiers, suit_modifier_id)


## Returns base attack cooldown + the selected suit level attack cooldown bonus.
func get_suit_scaled_attack_speed(suit_modifier_id: String) -> float:
	return maxf(0.05, attack_speed + get_modifier_value(attack_speed_modifiers, suit_modifier_id))

#endregion
