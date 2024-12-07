extends Resource
class_name DestroyableTileResource


@export var health := 64
@export var pos : Vector2i
var key : DropData.Keys
var drop_count := SimplefySettingMath.new()
