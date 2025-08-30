extends Resource
class_name PlayerResource

var player : Player
var player_hand : PlayerHand
var max_health := 150
var current_health := 150

var has_a_path := false

var activation_skills : Array[PerkBuild] = []
var activation_id := 0

var Role : CharacterRole = RolesData.load_Role_res(RolesData.Role.Trailblazer)

var shield_res : HasShieldRes = HasShieldRes.new()
var has_perk_anti_mine_det := false

var crystal_count := 0
var fake_crystal_count := 0
var Ores : Dictionary = {}


func add_activation_skill(perk: Perk) -> void:
	if perk.active_type == perk.Active_type_keys.Activation:
		for perk_in_list in player.stats.Perks:
			if perk.Key == perk_in_list.Key:
				if perk.level < perk_in_list.level:
					if perk.level < 6:
						perk.level += 1
						return
					else:
						break
				else:
					break
		for skill in activation_skills:
			if skill.Key == perk.Key:
				return
		
		var new_perk_build = PerkData.load_perk_scene(perk.Key).instantiate()
		if new_perk_build is PerkBuild:
			new_perk_build.Level = perk.level
			new_perk_build.Player_Res = self
			activation_skills.append(new_perk_build)
