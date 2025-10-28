extends Node

enum state_mashine {
	Follow,
	Attack,
	Wander,
	Avoid,
	Knockback,
	Ranged_Attack
	}

enum Keys {
	Simple_Follow_Target,
	Simple_Attack_Dash,
	Simple_Wander_Around,
	Simple_Stay_and_Shoot }

const Keys_scene := {
	Keys.Simple_Follow_Target: "res://Resources/Enemy/Ai/simple_follow_target.tscn",
	Keys.Simple_Attack_Dash: "res://Resources/Enemy/Ai/simple_attack_dash.tscn",
	Keys.Simple_Wander_Around: "res://Resources/Enemy/Ai/simple_wander_around.tscn",
	Keys.Simple_Stay_and_Shoot: "res://Resources/Enemy/Ai/simple_stay_and_shoot.tscn",
}

static var _ai_cache: = {}

static func load_ai(key: Keys) -> PackedScene:
	var ps: PackedScene = _ai_cache.get(key)
	if ps: 
		return ps
	var path = Keys_scene.get(key)
	ps = load(path)
	_ai_cache[key] = ps
	return ps
