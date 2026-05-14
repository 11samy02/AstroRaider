extends Resource
class_name Stats

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
@export var hit_iframe_duration: float = 1.0
## Playback speed for the player hit animation.
@export var hit_animation_speed: float = 1.0
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

@export_group("Perks")
## Base amount of extra projectile hits before modifiers.
@export var projectile_lives := 0.0
## Perks granted by this stat profile or saved player build.
@export var Perks: Array[Perk] = []
## Whether projectiles currently apply stun.
@export var has_stun_active := false
## Active stun strength applied by projectile attacks.
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

## Returns the final hit invulnerability duration including all modifiers
func get_hit_iframe_duration_total() -> float:
	return maxf(0.05, hit_iframe_duration + get_modifier_total(hit_iframe_duration_modifiers))

## Returns the configured hit animation speed
func get_hit_animation_speed() -> float:
	return maxf(0.05, hit_animation_speed)

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
