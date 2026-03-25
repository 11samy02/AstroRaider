extends Node

enum state_mashine {
	Follow,
	Attack,
	Wander,
	Avoid,
	Knockback,
	Ranged_Attack,
}

enum Keys {
	Simple_Follow_Target,
	Simple_Attack_Dash,
	Simple_Wander_Around,
	Simple_Stay_and_Shoot,
	Simple_Orbit_Target,
	Simple_Charge_and_Stop,
	Simple_Zigzag_Follow,
	Simple_Keep_Distance_and_Shoot,
}

const Keys_scene := {
	Keys.Simple_Follow_Target: "res://Resources/Enemy/Ai/simple_follow_target.tscn",
	Keys.Simple_Attack_Dash: "res://Resources/Enemy/Ai/simple_attack_dash.tscn",
	Keys.Simple_Wander_Around: "res://Resources/Enemy/Ai/simple_wander_around.tscn",
	Keys.Simple_Stay_and_Shoot: "res://Resources/Enemy/Ai/simple_stay_and_shoot.tscn",
	Keys.Simple_Orbit_Target: "res://Resources/Enemy/Ai/simple_orbit_target.tscn",
	Keys.Simple_Charge_and_Stop: "res://Resources/Enemy/Ai/simple_charge_and_stop.tscn",
	Keys.Simple_Zigzag_Follow: "res://Resources/Enemy/Ai/simple_zigzag_follow.tscn",
	Keys.Simple_Keep_Distance_and_Shoot: "res://Resources/Enemy/Ai/simple_keep_distance_and_shoot.tscn",
}

static var _ai_cache := {}


## Loads and caches an AI behavior scene by key
static func load_ai(key: Keys) -> PackedScene:
	var ps: PackedScene = _ai_cache.get(key)
	if ps:
		return ps
	var path: String = Keys_scene.get(key, "")
	if path == "":
		push_error("AiEnemyData: no scene registered for key " + str(key))
		return null
	ps = load(path)
	_ai_cache[key] = ps
	return ps
