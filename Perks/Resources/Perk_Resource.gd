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
	set(cos): cost = _validate_array(cos)
	get: return cost

@export var value: Array[int] = [0, 0, 0, 0, 0, 0]:
	set(val): value = _validate_array(val)
	get: return value

@export_multiline var description := ""
@export var type: Type_keys
@export var active_type: Active_type_keys

## Keys of perks that cannot be selected together with this perk
@export var excluded_perks: Array[PerkData.Keys] = []


func get_description(custom_level: int = 1) -> String:
	return description.replace("{{value}}", str(value[custom_level - 1]))

func get_cost() -> int:
	return cost[level - 1]

func _validate_array(new_value: Array[int]) -> Array[int]:
	if new_value.size() == 6:
		return new_value
	return value
