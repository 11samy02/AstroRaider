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

@export_tool_button("Sync Array Sizes") var _sync_btn = _sync_arrays
@export_category("General")
@export var image: Texture2D
@export var Key: PerkData.Keys
@export var perk_name := ""
@export_multiline var description := ""
@export var type: Type_keys
@export var active_type: Active_type_keys:
	set(val):
		active_type = val
		notify_property_list_changed()

@export_range(1, 6) var level := 1

@export_category("Classification")
@export var tags: Array[Tag_keys] = []
@export var mechanics: Array[Mechanic_keys] = []
@export var required_perks: Array[PerkData.Keys] = []
@export var excluded_perks: Array[PerkData.Keys] = []

@export_category("Scaling")
@export var rarity: Array[float] = [10.0, 8.0, 6.0, 4.0, 2.0, 1.0]:
	set(val): rarity = _validate_array(val, rarity, _max_levels())
	get: return rarity

@export var value: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(val): value = _validate_array_int(val, value, _max_levels())
	get: return value

@export var cooldown: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): cooldown = _validate_array(val, cooldown, _max_levels())
	get: return cooldown

@export var duration: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): duration = _validate_array(val, duration, _max_levels())
	get: return duration

@export_category("Economy")
@export var cost: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(val): cost = _validate_array_int(val, cost, _max_levels())
	get: return cost

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

## Returns the cost for a given level
func get_cost(custom_level: int = 1) -> int:
	return cost[clampi(custom_level - 1, 0, _max_levels() - 1)]

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
	cost = _validate_array_int(cost, cost, size)
	notify_property_list_changed()
