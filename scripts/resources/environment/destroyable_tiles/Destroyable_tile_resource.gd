extends Resource
class_name DestroyableTileResource


@export var health := 128
@export var pos : Vector2i
var key : DropData.Keys
var drop_count := SimplefySettingMath.new()
