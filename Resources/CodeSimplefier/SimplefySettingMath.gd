extends Resource
class_name SimplefySettingMath

@export var min_value := 0
@export var max_value := 1


func get_rand_value() -> int:
	randomize()
	return randi_range(min_value, max_value)
