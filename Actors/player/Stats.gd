extends Resource
class_name Stats

@export_group("Default")
@export var gravity_strength := 200.0
@export var gravity_break := 2.0
@export var max_speed := 250.0
@export var slowness_energy := 100.0
@export var bohrer_damage := 1.0
@export var bohrer_knockback := 3.0
@export var invincibility_frame : float = 2.00
@export var rotation_speed := 10.0
@export var max_hp := 100
@export var armor := 1.0
@export var crit_chance := 0.0

@export_group("Added")
@export var added_gravity_strength := 0.0
@export var added_gravity_break := 0.0
@export var added_max_speed := 0.0
@export var added_slowness_energy := 0.0
@export var added_bohrer_damage := 0.0
@export var added_bohrer_knockback := 0.0
@export var added_invincibility_frame : float = 0.0
@export var added_rotation_speed := 0.0
@export var added_max_hp := 0.0
@export var added_armor := 0.0
@export var added_crit_chance := 0.0

@export_group("Perks")
@export var Perks : Array[Perk] = []
