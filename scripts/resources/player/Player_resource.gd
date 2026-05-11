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
