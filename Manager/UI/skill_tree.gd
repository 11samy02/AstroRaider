@tool
extends CanvasLayer
class_name SkillTree

@export var Role : RolesData.Role

@onready var tab_container: TabContainer = %TabContainer


var player_res : PlayerResource

const PERKBUTTON = preload("res://Manager/UI/perk_button.tscn")
@onready var pos: MarginContainer = $Control/MarginContainer/NinePatchRect/pos
@onready var tab_bar: TabBar = $Control/MarginContainer/NinePatchRect/pos/VBoxContainer/TabBar
@onready var title: Label = %Title
@onready var describtion: Label = %Describtion
@onready var cost_2: Label = %cost2
@onready var owned_money: Label = %owned_money


var tap_index := 0
var has_pressed_tap_change_right := false
var has_pressed_tap_change_left := false

@export var skill_list : Array[CharacterSkill] = []
@export var reset_skill_list := false


func _enter_tree() -> void:
	GSignals.PLA_open_skill_tree.connect(open_skill_tree)
	GSignals.UI_reset_skill_tree.connect(reset_perks)
	hide()

func _ready() -> void:
	_add_all_skills_to_list()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if reset_skill_list:
			_add_all_skills_to_list()
			reset_skill_list = false
		return
	
	change_tap()
	close_skill_tree(delta)
	
	if player_res != null:
		owned_money.set_text(str(player_res.crystal_count) + "$")
	





func change_tap():
	if Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_RIGHT_SHOULDER) and !has_pressed_tap_change_right:
		has_pressed_tap_change_right = true
		if tap_index + 1 <= tab_container.get_child_count() -1:
			tap_index += 1
		else:
			tap_index = 0
	elif !Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_RIGHT_SHOULDER) and has_pressed_tap_change_right:
		has_pressed_tap_change_right = false
	
	if Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_LEFT_SHOULDER) and !has_pressed_tap_change_left:
		has_pressed_tap_change_left = true
		if tap_index - 1 >= 0:
			tap_index -= 1
		else:
			tap_index = tab_container.get_child_count() - 1
	elif !Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_LEFT_SHOULDER) and has_pressed_tap_change_left:
		has_pressed_tap_change_left = false
	
	for i in range(1, 5):
		if Input.is_key_pressed(KEY_0 + i):
			tap_index = i - 1
	
	
	tab_container.current_tab = tap_index
	tab_bar.current_tab = tap_index


func open_skill_tree(player: Player) -> void:
	if player == player_res.player:
		PauseMenu.can_pause_on_screen = false
		get_tree().paused = true
		show()
		


var delay := 0.5

func close_skill_tree(delta) -> void:
	if Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_Y) and delay <= 0 or Input.is_action_pressed("interact") and delay <= 0:
		PauseMenu.can_pause_on_screen = true
		get_tree().paused = false
		hide()
	elif Input.is_joy_button_pressed(player_res.player.controller_id, JOY_BUTTON_Y) or Input.is_action_pressed("interact"):
		delay -= delta
	else:
		delay = 0.5
	


func _on_tab_bar_tab_button_pressed(tab: int) -> void:
	tap_index = tab


func _add_all_skills_to_list():
	skill_list = []
	for tab in tab_container.get_children():
		for pos in tab.get_children():
			for button in pos.get_children():
				if button is PerkButton:
					if !Engine.is_editor_hint():
						button.skill.player_res = player_res
						button.change_description.connect(change_description)
					skill_list.append(button.skill)


func change_description(perk: Perk) -> void:
	title.set_text(perk.perk_name)
	describtion.set_text(perk.get_description())
	cost_2.set_text(str(perk.get_cost()) + "$")


func _on_visibility_changed() -> void:
	reset_perks()

func reset_perks():
	if is_instance_valid(tab_container):
		for tab in tab_container.get_children():
			for pos in tab.get_children():
				for button in pos.get_children():
					if button is PerkButton:
						button.set_icon()
