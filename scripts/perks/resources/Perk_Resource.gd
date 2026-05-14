@tool
extends Resource
class_name Perk

enum Active_type_keys {
	Start,
	OneTime,
	TimeDelay,
	Always,
	Custom_Condition,
	Activation,
	Ult,
}

enum Type_keys {
	Movement,
	Defens,
	Offens,
	Team,
	Mining,
}

enum Tag_keys {
	Aggro,
	Sniper,
	Tank,
	Miner,
	Controller,
	Mobility,
	Sustain,
}

enum Mechanic_keys {
	Projectile,
	Melee,
	Crit,
	Heal,
	Dash,
	Shield,
	Crystal,
	Mining,
	Stun,
}

enum UnlockType {
	FREE,
	SHOP,
	SUIT_LEVEL,
	ACHIEVEMENT,
}

## Editor button that resizes all scaling arrays to the current max level count.
@export_tool_button("Sync Array Sizes") var _sync_btn = _sync_arrays
@export_category("General")
## Icon shown in perk UI.
@export var image: Texture2D
## Unique perk key used to load scenes and resources.
@export var Key: PerkData.Keys
## Display name shown in perk UI.
@export var perk_name := ""
## Description text shown in perk UI. Supports {{value}}, {{cooldown}}, and {{duration}} placeholders.
@export_multiline var description := ""
## Main gameplay category used for filtering and frame styling.
@export var type: Type_keys
## Activation behavior used by selection and runtime perk logic.
@export var active_type: Active_type_keys:
	set(val):
		active_type = val
		notify_property_list_changed()

## Current resource level used for previews and saved perk builds.
@export_range(1, 6) var level := 1

@export_category("Classification")
## Tags used to bias future weighted perk offers.
@export var tags: Array[Tag_keys] = []
## Mechanics used to classify what this perk affects.
@export var mechanics: Array[Mechanic_keys] = []
## Perks that must already be selected in the run before this perk can appear.
@export var required_perks: Array[PerkData.Keys] = []
## Perks that cannot appear once this perk has been selected.
@export var excluded_perks: Array[PerkData.Keys] = []

@export_category("Scaling")
## Weighted offer chance per level.
@export var rarity: Array[float] = [10.0, 8.0, 6.0, 4.0, 2.0, 1.0]:
	set(val): rarity = _validate_array(val, rarity, _max_levels())
	get: return rarity

## Main numeric value per level.
@export var value: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(val): value = _validate_array_int(val, value, _max_levels())
	get: return value

## Cooldown duration per level.
@export var cooldown: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): cooldown = _validate_array(val, cooldown, _max_levels())
	get: return cooldown

## Effect duration per level.
@export var duration: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): duration = _validate_array(val, duration, _max_levels())
	get: return duration

@export_category("Meta Unlock")
## Meta progression source required before this perk can appear.
@export var unlock_type: UnlockType = UnlockType.FREE
## Future shop price used when unlock_type is SHOP.
@export var shop_price: int = 0
## Optional required suit. NONE means any unlocked selected suit can satisfy the level requirement.
@export var required_suit: SuitData.SuitKeys = SuitData.SuitKeys.NONE
## Required level on the selected suit when unlock_type is SUIT_LEVEL.
@export_range(1, 100) var required_suit_level: int = 1
## Whether this perk is available before any meta unlock checks.
@export var starts_unlocked := true

## Returns true if the perk is available in the meta progression layer.
func is_meta_unlocked(player: Player = null) -> bool:
	if starts_unlocked:
		return true

	match unlock_type:
		UnlockType.SUIT_LEVEL:
			return _has_required_suit_level(player)
		_:
			return false


## Returns true when the selected player suit satisfies this perk's suit-level requirement.
func _has_required_suit_level(player: Player = null) -> bool:
	if not is_instance_valid(player):
		return false

	var suit := player.get_selected_suit_data()
	if not is_instance_valid(suit):
		return false
	if not suit.has_unlocked:
		return false
	if required_suit != SuitData.SuitKeys.NONE and suit.Key != required_suit:
		return false
	return suit.current_level >= required_suit_level

## Returns max level count based on active type
func _max_levels() -> int:
	return 3 if active_type == Active_type_keys.Ult else 6

## Returns the formatted description for a given level
func get_description(custom_level: int = 1) -> String:
	var idx := clampi(custom_level - 1, 0, _max_levels() - 1)
	var text := description
	text = text.replace("{{value}}", str(value[idx]))
	text = text.replace("{{cooldown}}", _format_number(cooldown[idx]))
	text = text.replace("{{duration}}", _format_number(duration[idx]))
	return text

## Returns the rarity weight for a given level
func get_rarity(custom_level: int = 1) -> float:
	return rarity[clampi(custom_level - 1, 0, _max_levels() - 1)]

## Returns the main value for a given level
func get_value(custom_level: int = 1) -> int:
	return value[clampi(custom_level - 1, 0, _max_levels() - 1)]

## Returns the cooldown for a given level
func get_cooldown(custom_level: int = 1) -> float:
	return cooldown[clampi(custom_level - 1, 0, _max_levels() - 1)]

## Returns the duration for a given level
func get_duration(custom_level: int = 1) -> float:
	return duration[clampi(custom_level - 1, 0, _max_levels() - 1)]


## Hides irrelevant fields and adjusts level range based on active type
func _validate_property(property: Dictionary) -> void:
	if property.name == "level":
		var max_lvl := _max_levels()
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "1," + str(max_lvl)

## Validates float array to correct size for current type
func _validate_array(new_value: Array[float], current_value: Array[float], expected_size: int) -> Array[float]:
	if new_value.size() == expected_size:
		return new_value
	if new_value.size() > expected_size:
		return new_value.slice(0, expected_size)
	var result := new_value.duplicate()
	while result.size() < expected_size:
		result.append(0.0)
	return result

## Validates int array to correct size for current type
func _validate_array_int(new_value: Array[int], current_value: Array[int], expected_size: int) -> Array[int]:
	if new_value.size() == expected_size:
		return new_value
	if new_value.size() > expected_size:
		return new_value.slice(0, expected_size)
	var result := new_value.duplicate()
	while result.size() < expected_size:
		result.append(0)
	return result

## Formats whole numbers without decimal places
func _format_number(num: float) -> String:
	if is_equal_approx(num, round(num)):
		return str(int(round(num)))
	return str(num)

## Trims or extends all arrays to match current active type
func _sync_arrays() -> void:
	var size := _max_levels()
	rarity = _validate_array(rarity, rarity, size)
	value = _validate_array_int(value, value, size)
	cooldown = _validate_array(cooldown, cooldown, size)
	duration = _validate_array(duration, duration, size)
	notify_property_list_changed()
