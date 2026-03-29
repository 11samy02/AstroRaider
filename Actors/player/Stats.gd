extends Resource
class_name Stats

@export_group("Default")
@export var gravity_strength := 200.0
@export var gravity_break := 2.0
@export var max_speed := 250.0
@export var slowness_energy := 100.0
@export var bohrer_damage := 1.0
@export var bohrer_knockback := 3.0
@export var invincibility_frame: float = 2.0
@export var rotation_speed := 10.0
@export var max_hp := 100
@export var armor := 1.0
@export var crit_chance := 0.0
@export var projectile_damage := 0.0
@export var attack_speed := 0.4

@export_group("Modifiers")
@export var gravity_strength_modifiers: Array[StatModifier] = []
@export var gravity_break_modifiers: Array[StatModifier] = []
@export var max_speed_modifiers: Array[StatModifier] = []
@export var slowness_energy_modifiers: Array[StatModifier] = []
@export var bohrer_damage_modifiers: Array[StatModifier] = []
@export var bohrer_knockback_modifiers: Array[StatModifier] = []
@export var invincibility_frame_modifiers: Array[StatModifier] = []
@export var rotation_speed_modifiers: Array[StatModifier] = []
@export var max_hp_modifiers: Array[StatModifier] = []
@export var armor_modifiers: Array[StatModifier] = []
@export var crit_chance_modifiers: Array[StatModifier] = []
@export var projectile_damage_modifiers: Array[StatModifier] = []
@export var projectile_lives_modifiers: Array[StatModifier] = []
@export var attack_speed_modifiers : Array[StatModifier] = []

@export_group("Perks")
@export var projectile_lives := 0.0
@export var Perks: Array[Perk] = []
@export var has_stun_active := false
@export var stun_strength := 0.0


## Adds a new modifier or updates the existing modifier for the given perk key
func set_modifier(modifiers: Array[StatModifier], perk_key: PerkData.Keys, new_value: float) -> void:
	for modifier in modifiers:
		if modifier.perk_key == perk_key:
			modifier.value = new_value
			return

	var new_modifier := StatModifier.new()
	new_modifier.perk_key = perk_key
	new_modifier.value = new_value
	modifiers.append(new_modifier)


## Removes the modifier entry for the given perk key
func remove_modifier(modifiers: Array[StatModifier], perk_key: PerkData.Keys) -> void:
	for i in range(modifiers.size() - 1, -1, -1):
		if modifiers[i].perk_key == perk_key:
			modifiers.remove_at(i)
			return


## Returns the summed value of all modifiers in the given list
func get_modifier_total(modifiers: Array[StatModifier]) -> float:
	var total := 0.0
	for modifier in modifiers:
		total += modifier.value
	return total


## Returns the final gravity strength including all modifiers
func get_gravity_strength_total() -> float:
	return gravity_strength + get_modifier_total(gravity_strength_modifiers)


## Returns the final gravity break including all modifiers
func get_gravity_break_total() -> float:
	return gravity_break + get_modifier_total(gravity_break_modifiers)


## Returns the final movement speed including all modifiers
func get_max_speed_total() -> float:
	return max_speed + get_modifier_total(max_speed_modifiers)


## Returns the final slowness energy including all modifiers
func get_slowness_energy_total() -> float:
	return slowness_energy + get_modifier_total(slowness_energy_modifiers)


## Returns the final drill damage including all modifiers
func get_bohrer_damage_total() -> float:
	return bohrer_damage + get_modifier_total(bohrer_damage_modifiers)


## Returns the final drill knockback including all modifiers
func get_bohrer_knockback_total() -> float:
	return bohrer_knockback + get_modifier_total(bohrer_knockback_modifiers)


## Returns the final invincibility frame duration including all modifiers
func get_invincibility_frame_total() -> float:
	return invincibility_frame + get_modifier_total(invincibility_frame_modifiers)


## Returns the final rotation speed including all modifiers
func get_rotation_speed_total() -> float:
	return rotation_speed + get_modifier_total(rotation_speed_modifiers)


## Returns the final maximum health including all modifiers
func get_max_hp_total() -> float:
	return max_hp + int(round(get_modifier_total(max_hp_modifiers)))


## Returns the final armor including all modifiers
func get_armor_total() -> float:
	return armor + get_modifier_total(armor_modifiers)


## Returns the final crit chance including all modifiers
func get_crit_chance_total() -> float:
	return crit_chance + get_modifier_total(crit_chance_modifiers)


## Returns the final projectile damage including all modifiers
func get_projectile_damage_total() -> float:
	return projectile_damage + get_modifier_total(projectile_damage_modifiers)

## Returns the final projectile lives including all modifiers
func get_projectile_lives_total() -> float:
	return projectile_lives + get_modifier_total(projectile_lives_modifiers)

## Returns the final attack speed including all modifiers
func get_attack_speed_total() -> float:
	return maxf(0.05, attack_speed + get_modifier_total(attack_speed_modifiers))
