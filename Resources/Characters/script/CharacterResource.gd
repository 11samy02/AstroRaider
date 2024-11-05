extends Resource
class_name CharacterRole

@export var Role_key : RolesData.Role = RolesData.Role.Trailblazer
@export var controller_id := 0
@export_multiline var describtion := ""


func can_buy_skill(skill_id: int) -> bool:
	var player_crystals = GlobalGame.Players[controller_id].crystal_count
	
	var skill_list = RolesData.get_all_skills_in_skill_tree(Role_key)
	
	for skill:CharacterSkill in skill_list:
		if skill.id == skill_id:
			var perk_cost = PerkData.load_perk_res(skill.key).cost[skill.level - 1]
			
			if player_crystals < perk_cost:
				return false
			
			if skill.connection_id == skill.id:
				player_crystals -= PerkData.load_perk_res(skill.key).cost[skill.level - 1]
				return true
			
			for other_skill:CharacterSkill in skill_list:
				if other_skill.id == skill.connection_id and other_skill.is_active:
					player_crystals -= PerkData.load_perk_res(skill.key).cost[skill.level - 1]
					return true
	return false

func unlock_skill(skill_id: int) -> void:
	var skill_tree = RolesData.load_Skill_Tree_scene(Role_key)
	
	if can_buy_skill(skill_id):
		for skill:CharacterSkill in skill_tree.skill_list:
			if skill.id == skill_id:
				skill.is_active = true
				GlobalGame.Players[controller_id].crystal_count -= PerkData.load_perk_res(skill.key).cost[skill.level - 1]
	else:
		print("Kann Skill mit ID ", skill_id, " nicht freischalten. Voraussetzungen nicht erfüllt.")


func set_player(id: int) -> void:
	controller_id = id
