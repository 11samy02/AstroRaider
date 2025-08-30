@tool
extends CanvasLayer
class_name SkillTree

@export var Role : RolesData.Role


var player_res : PlayerResource

const PERKBUTTON = preload("res://Manager/UI/perk_button.tscn")
@onready var title: Label = %Title
@onready var describtion: Label = %Describtion
@onready var cost_2: Label = %cost2
@onready var owned_money: Label = %owned_money


var tap_index := 0
var has_pressed_tap_change_right := false
var has_pressed_tap_change_left := false

@export var skill_list : Array[CharacterSkill] = []
@export var skill_list_count := 0

func _enter_tree() -> void:
	GSignals.PLA_open_skill_tree.connect(open_skill_tree)
	GSignals.UI_reset_skill_tree.connect(reset_perks)
	hide()

func _ready() -> void:
	_add_all_skills_to_list()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		skill_list_count = get_tree().get_nodes_in_group("PerkButton").size()
		if skill_list.size() != skill_list_count:
			_add_all_skills_to_list()
		return
	
	close_skill_tree(delta)
	if player_res != null:
		owned_money.set_text(str(player_res.fake_crystal_count) + "$")
	else:
		queue_free()
	



func open_skill_tree(player: Player) -> void:
	if player == player_res.player:
		PauseMenu.can_pause_on_screen = false
		get_tree().paused = true
		show()
		player_res.fake_crystal_count = player_res.crystal_count
		for button:PerkButton in get_tree().get_nodes_in_group("PerkButton"):
			button.skill.player_res = player_res
			if !button.change_description.is_connected(change_description):
				button.change_description.connect(change_description)
			if !button.button_down.is_connected(reset_perks):
				button.button_down.connect(reset_perks)
			
			button.set_icon()
		
		var first_button : PerkButton = null
		
		for button:PerkButton in get_tree().get_nodes_in_group("PerkButton"):
			if is_instance_valid(first_button):
				if button.skill.id < first_button.skill.id and !button.skill.is_active:
					first_button = button
			else:
				first_button = button
		if is_instance_valid(first_button):
			first_button.grab_focus()
		


var delay := 0.2

func close_skill_tree(delta) -> void:
	if Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_Y) and delay <= 0 or Input.is_action_pressed("interact") and delay <= 0:
		PauseMenu.can_pause_on_screen = true
		get_tree().paused = false
		hide()
	elif Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_Y) or Input.is_action_pressed("interact"):
		delay -= delta
	else:
		delay = 0.2
	



func _add_all_skills_to_list():
	skill_list = []
	for button:PerkButton in get_tree().get_nodes_in_group("PerkButton"):
		skill_list.append(button.skill)


func change_description(perk: Perk) -> void:
	title.set_text(perk.perk_name)
	describtion.set_text(perk.get_description())
	cost_2.set_text(str(perk.get_cost()) + "$")


func _on_visibility_changed() -> void:
	reset_perks()

func reset_perks():
	if visible:
		for button:PerkButton in get_tree().get_nodes_in_group("PerkButton"):
			button.skill.player_res = player_res
			button.set_icon()
		change_money()

func change_money() -> void:
	if player_res.fake_crystal_count != player_res.crystal_count:
		var tween = create_tween()
		tween.tween_property(player_res,"fake_crystal_count", player_res.crystal_count, 1)
		await (tween.finished)
