extends Node
class_name RolesData


enum Role {
	Trailblazer,
}

const Role_tree = {
	Role.Trailblazer: "res://Manager/UI/skill_tree.tscn"
}

const Role_res = {
	Role.Trailblazer: "res://Resources/Characters/Roles/Role_Trailblazer.tres"
}

static func load_Role_res(key : Role) -> CharacterRole:
	return load(Role_res.get(key))

static func load_Skill_Tree_scene(key : Role) -> PackedScene:
	return load(Role_tree.get(key))

static func get_all_skills_in_skill_tree(key : Role) -> Array[CharacterSkill]:
	var skill_tree = load_Skill_Tree_scene(key).instantiate()
	if skill_tree is SkillTree:
		return skill_tree.skill_list
	return []
