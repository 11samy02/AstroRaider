extends Node
class_name PerkBuild


@export var Key: PerkData.Keys
@export var Player_Res : PlayerResource
@export var Level := 1
var stats: Stats = Stats.new()

func _enter_tree() -> void:
	stats = Player_Res.player.stats

func _ready() -> void:
	var perk_res: Perk = PerkData.load_perk_res(Key)
	
	if perk_res.active_type == perk_res.Active_type_keys.Start:
		activate_perk()

func activate_perk() -> void:
	pass


func _exit_tree() -> void:
	print("")
	printerr(" _exit_tree() needs to be overwritten in the Perk: " + self.name)
	print("")

func get_value():
	return PerkData.load_perk_res(Key).value[Level - 1]
