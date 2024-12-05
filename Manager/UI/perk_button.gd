extends TextureButton
class_name PerkButton


@export var skill : CharacterSkill
@onready var icon: TextureRect = $icon
var is_icon_set := false

@export var button_textures: Array[Texture2D] = []


signal change_description

func _ready() -> void:
	skill.is_active = false

func set_icon() -> void:
	if skill.is_active:
		return
	else:
		if !is_icon_set:
			is_icon_set = true
			icon.set_texture(PerkData.load_perk_res(skill.key).image)
		disabled = !skill.player_res.Role.can_buy_skill(skill.id)
		if disabled:
			icon.modulate = Color("#636363")
			texture_focused = button_textures[0]
		else:
			icon.modulate = Color.WHITE
			texture_focused = button_textures[1]

func _on_button_down() -> void:
	if skill.player_res.Role.can_buy_skill(skill.id):
		skill.is_active = true
		var new_perk:Perk = PerkData.load_perk_res(skill.key)
		new_perk.level = skill.level 
		skill.player_res.crystal_count -= new_perk.get_cost()
		GSignals.UI_reset_skill_tree.emit()
		
		var found_similar_perk := false
		for perk in skill.player_res.player.stats.Perks:
			if perk.Key == skill.key:
				perk.level + 1
				found_similar_perk = true
		if !found_similar_perk:
			skill.player_res.player.stats.Perks.append(new_perk)
		GSignals.PERK_reset_perks_from_controller_id.emit(skill.player_res.player.controller_id)
		set_process(false)
		disabled = true
		texture_disabled = button_textures[2]
		texture_focused = button_textures[3]
		icon.modulate = Color.WHITE


func change_descibtion() -> void:
	var perk: Perk = PerkData.load_perk_res(skill.key)
	perk.level = skill.level
	
	change_description.emit(perk)
