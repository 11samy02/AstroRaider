extends Node
class_name PerkBuild


@export var Key: PerkData.Keys
@export var player : Player
@export_range(1,6) var Level := 1
@export var has_unlocked := false
var stats: Stats
var has_pressed := false
var perk_res: Perk

func _ready() -> void:
	if !is_instance_valid(player):
		printerr("Player Must be selected: ", self.name)
	stats = player.stats
	perk_res = PerkData.load_perk_res(Key)

func _process(delta: float) -> void:
	if !is_instance_valid(perk_res):
		return
		
	if perk_res.active_type == perk_res.Active_type_keys.Always:
		activate_perk()
	
	
	if perk_res.active_type == Perk.Active_type_keys.Activation:
		if Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) and !has_pressed or Input.is_action_just_pressed("aktivat_perk"):
			has_pressed = true
			activate_perk()
		elif !Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_Y) and has_pressed or Input.is_action_just_released("aktivat_perk"):
			has_pressed = false

func activate_perk() -> void:
	if !has_unlocked:
		return

func get_value():
	return PerkData.load_perk_res(Key).value[Level - 1]

func level_up_perk() -> void:
	if !has_unlocked:
		print(self.name, " is on Level: ", Level)
		has_unlocked = true
		return
	if Level >= 6:
		printerr("Perk is already on Max Level: ", self.name)
		return
	Level += 1
	print(self.name, " is on Level: ", Level)
