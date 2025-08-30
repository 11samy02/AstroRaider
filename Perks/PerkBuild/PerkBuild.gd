extends Node
class_name PerkBuild


@export var Key: PerkData.Keys
@export var player : Player
@export_range(1,6) var Level := 1
@export var has_unlocked := false
var stats: Stats

func _ready() -> void:
	stats = player.stats
	var perk_res: Perk = PerkData.load_perk_res(Key)

func _process(delta: float) -> void:
	var perk_res: Perk = PerkData.load_perk_res(Key)
	if perk_res.active_type == perk_res.Active_type_keys.Always:
		activate_perk()
	
	if Input.is_action_just_pressed("aktivate_building_mode"):
		level_up_perk()


func activate_perk() -> void:
	if !has_unlocked:
		return


func get_value():
	return PerkData.load_perk_res(Key).value[Level - 1]

func level_up_perk() -> void:
	if !has_unlocked:
		has_unlocked = true
		return
	if Level >= 6:
		printerr("Perk is already on Max Level: ", self.name)
		return
	Level += 1
	print(self.name, " is on Level: ", Level)
