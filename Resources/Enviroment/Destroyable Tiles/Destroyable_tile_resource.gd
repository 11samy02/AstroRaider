extends Resource
class_name DestroyableTileResource


@export var health := 20
@export var pos : Vector2i
var drop_path : String
var drop_count := SimplefySettingMath.new()
