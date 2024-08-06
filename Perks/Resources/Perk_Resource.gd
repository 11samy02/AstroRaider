@tool
extends Resource
class_name Perk



enum Active_type_keys {
	Start,
	OneTime,
	TimeDelay,
	Always,
	Custom_Condition,
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
@export_range(1,6) var level := 1

@export var value : Array[int] = [0,0,0,0,0,0]:
	set (val):
		value = set_value(val)
	get:
		return value


@export_multiline var description := ""
@export var type : Type_keys
@export var active_type : Active_type_keys

func get_description() -> String:
	return(description.replace("{{value}}", str(value[level-1])))


func set_value(new_value: Array[int]):
	if new_value.size() == value.size():
		return(new_value)
