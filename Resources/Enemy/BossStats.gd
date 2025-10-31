extends Resource
class_name BossStats

@export_group("Deatails")
@export var Boss_Name : String
@export_multiline var Description : String

@export_group("Stats")
@export var Max_HP : int = 1000
var current_hp : int = Max_HP
@export var Max_Shield : int = 100
var current_Shield : int = Max_Shield

@export var max_speed := 300.0
@export var attack: AttackResource = AttackResource.new()


@export_group("Perks Disadventage")
@export var stun_resistence := 5.0
@export var stunCD := 5.0
var is_stunned := false
