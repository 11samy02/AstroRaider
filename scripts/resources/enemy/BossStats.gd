extends Resource
class_name BossStats

@export_group("Details")
@export var Boss_Name: String
@export var Sup_Title: String
@export_multiline var Description: String
@export_multiline var Short_Description: String
@export var radar_icon: Texture2D

@export_group("Stats")
@export var Max_HP: int = 1000
var current_hp: int = Max_HP

@export var Max_Shield: int = 100
var current_Shield: int = Max_Shield

@export var max_speed := 300.0
@export var attack: AttackResource = AttackResource.new()

@export_group("Rewards")
@export var boss_exp_reward: int = 500

@export_group("Perks Disadventage")
@export var stun_resistence := 5.0
@export var stunCD := 5.0
@export var default_crit_chance: float = 5.00

var is_stunned := false


func reset_runtime_stats() -> void:
	current_hp = Max_HP
	current_Shield = Max_Shield
	is_stunned = false
