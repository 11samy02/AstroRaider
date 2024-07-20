extends Node


enum state_mashine {
	Follow,
	Attack,
	Wander,
	Avoid,
}


enum Keys {
	Simple_Follow_Target,
	Simple_Attack_Dash,
	Simple_Wander_Around,
}


const Keys_scene = {
	Keys.Simple_Follow_Target: "res://Resources/Enemy/Ai/simple_follow_target.tscn",
	Keys.Simple_Attack_Dash: "res://Resources/Enemy/Ai/simple_attack_dash.tscn",
	Keys.Simple_Wander_Around: "res://Resources/Enemy/Ai/simple_wander_around.tscn",
}


static func load_ai(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key))
