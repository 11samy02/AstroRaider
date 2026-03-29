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

@export var image: Texture2D
@export var Key: PerkData.Keys
@export var perk_name := ""
@export_range(1, 6) var level := 1

@export var cost: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(cos): cost = _validate_array_int(cos, cost)
	get: return cost

@export var value: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(val): value = _validate_array_int(val, value)
	get: return value

@export var cooldown: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): cooldown = _validate_array_float(val, cooldown)
	get: return cooldown

@export var duration: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]:
	set(val): duration = _validate_array_float(val, duration)
	get: return duration

@export_multiline var description := ""
@export var type: Type_keys
@export var active_type: Active_type_keys
@export var excluded_perks: Array[PerkData.Keys] = []

func get_description(custom_level: int = 1) -> String:
	var idx := clampi(custom_level - 1, 0, 5)
	var text := description
	text = text.replace("{{value}}", str(value[idx]))
	text = text.replace("{{cooldown}}", _format_number(cooldown[idx]))
	text = text.replace("{{duration}}", _format_number(duration[idx]))
	return text

func get_cost() -> int:
	return cost[level - 1]

func get_value(custom_level: int = 1) -> int:
	return value[clampi(custom_level - 1, 0, 5)]

func get_cooldown(custom_level: int = 1) -> float:
	return cooldown[clampi(custom_level - 1, 0, 5)]

func get_duration(custom_level: int = 1) -> float:
	return duration[clampi(custom_level - 1, 0, 5)]

func _validate_array_int(new_value: Array[int], current_value: Array[int]) -> Array[int]:
	if new_value.size() == 6:
		return new_value
	return current_value

func _validate_array_float(new_value: Array[float], current_value: Array[float]) -> Array[float]:
	if new_value.size() == 6:
		return new_value
	return current_value

func _format_number(num: float) -> String:
	if is_equal_approx(num, round(num)):
		return str(int(round(num)))
	return str(num)
