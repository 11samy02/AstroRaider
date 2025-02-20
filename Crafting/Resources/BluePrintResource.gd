extends Resource
class_name BluePrintResource

@export var Key : BluePrintData.Keys = BluePrintData.Keys.Generator
@export var cost : Array[BluePrintCostResource]
@export var size : Vector2i
@export var texture : Texture2D
@export var can_build_fast : bool = false



func can_buy_building(player_res: PlayerResource) -> bool:
	return true
