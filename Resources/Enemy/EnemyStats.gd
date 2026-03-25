@tool
extends Resource
class_name EnemyStats

@export_group("Default Stats")
@export var max_health: int = 10
@export var max_Random_health_edit: int = 0
@export var attack: AttackResource = AttackResource.new()
@export var speed := 150.0
@export var max_speed := 300.0
@export var projectile: PackedScene
@export var ranged_attack: AttackResource = AttackResource.new()
@export var default_crit_chance: float = 20.00

@export_group("Perks Disadvantage")
@export var stun_resistence := 1.0

@export_group("Behavior")
@export var ai_type_keys: Array[AiTypeKeys]
@export var follow_distance: float = 200.0
@export var attack_distance: float = 50.0
@export var can_wander: bool = true
@export var can_ranged_attack: bool = false
@export var ranged_min_distance: float = 100.0
@export var ranged_max_distance: float = 200.0
@export var ranged_chance: int = 2
@export var orbit_radius: float = 150.0
@export var orbit_speed: float = 2.0

@export_group("")
@export_tool_button("Refresh Inspector", "FlipWinding") var _refresh_btn = _refresh

var current_health: int
var is_stunned := false

func _refresh() -> void:
	_sync_ai_flags()
	notify_property_list_changed()

## Returns true if any entry in ai_type_keys has the given state
func _has_state(s: AiEnemyData.state_mashine) -> bool:
	if not ai_type_keys:
		return false
	for entry: AiTypeKeys in ai_type_keys:
		if entry and entry.state == s:
			return true
	return false

## Returns true if any entry in ai_type_keys has orbit in its key name
func _has_orbit() -> bool:
	if not ai_type_keys:
		return false
	for entry: AiTypeKeys in ai_type_keys:
		if entry and entry.key == AiEnemyData.Keys.Simple_Orbit_Target:
			return true
	return false

## Syncs behavior flags automatically based on ai_type_keys content
func _sync_ai_flags() -> void:
	can_wander = _has_state(AiEnemyData.state_mashine.Wander)
	can_ranged_attack = _has_state(AiEnemyData.state_mashine.Ranged_Attack)

## Hides or shows properties in inspector based on ai_type_keys states
func _validate_property(property: Dictionary) -> void:
	if property.name in ["can_wander", "can_ranged_attack"]:
		property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR
	if property.name in ["ranged_min_distance", "ranged_max_distance", "ranged_chance", "projectile", "ranged_attack"]:
		if not _has_state(AiEnemyData.state_mashine.Ranged_Attack):
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["orbit_radius", "orbit_speed"]:
		if not _has_orbit():
			property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "refresh_inspector":
		property.hint_string = "Refresh"

## Updates stats based on upgrade resource and current level
func update_stats(upgrades: EnemyStatsUpgrade, level: int) -> void:
	max_health += upgrades.max_health * level
	speed = clamp(speed + upgrades.speed * level, 0, max_speed)
	attack.damage += upgrades.attack_damage * level
	attack.knockback += upgrades.attack_knockback * level
	attack.crit_chance += upgrades.attack_crit_chance * level
	ranged_attack.damage += upgrades.ranged_damage * level
	default_crit_chance += upgrades.default_crit_chance * level
