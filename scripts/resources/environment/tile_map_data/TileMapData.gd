extends Resource
class_name TileMapData

@export var seed: int = 0
@export var map_size: Vector2i = Vector2i(0, 0)
@export var terrain_set_id: int = 0
@export var terrain_id: int = 0

@export var positions_x: PackedInt32Array = []
@export var positions_y: PackedInt32Array = []
@export var source_ids: PackedByteArray = []
@export var atlas_x: PackedInt32Array = []
@export var atlas_y: PackedInt32Array = []
@export var alternatives: PackedInt32Array = []
