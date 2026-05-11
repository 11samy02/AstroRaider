extends Resource
class_name CharacterRole

@export var Role_key : RolesData.Role = RolesData.Role.Trailblazer
@export var controller_id := 0
@export_multiline var describtion := ""

var skill_dict = {}

func _init():
	_build_skill_dict()

func _build_skill_dict():
	var skill_list = RolesData.get_all_skills_in_skill_tree(Role_key)
	for skill in skill_list:
		skill_dict[skill.id] = skill

func can_buy_skill(skill_id: int) -> bool:
	var player_crystals = GlobalGame.Players[controller_id].crystal_count

	if not skill_dict.has(skill_id):
		return false

	var skill = skill_dict[skill_id]
	var perk_cost = PerkData.load_perk_res(skill.key).cost[skill.level - 1]

	if player_crystals < perk_cost:
		return false

	if skill.connection_id == skill.id:
		return true

	if skill_dict.has(skill.connection_id) and skill_dict[skill.connection_id].is_active:
		return true

	return false

func unlock_skill(skill_id: int) -> void:
	if can_buy_skill(skill_id):
		var skill = skill_dict[skill_id]
		skill.is_active = true
		GlobalGame.Players[controller_id].crystal_count -= PerkData.load_perk_res(skill.key).cost[skill.level - 1]
	else:
		print("Kann Skill mit ID ", skill_id, " nicht freischalten. Voraussetzungen nicht erfüllt.")

func set_player(id: int) -> void:
	controller_id = id
