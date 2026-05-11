extends Resource
class_name CharacterSkill

@export var id := 0
@export var key := PerkData.Keys.Speed_It_Up
@export_range(1,6) var level := 1
@export var connection_id := 0
@export var is_active := false
@export var can_buy := false
@export var player_res : PlayerResource
