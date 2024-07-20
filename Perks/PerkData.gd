extends Node


enum Keys {
	Speed_It_Up,
	Construction_Expert,
	Coin_Master,
	Slow_It_Down,
}




const Keys_res = {
	Keys.Speed_It_Up: "res://Perks/Resources/Perk_Speed_it_up.tres",
	Keys.Construction_Expert: "res://Perks/Resources/Perk_Construction_expert.tres",
	Keys.Coin_Master: "res://Perks/Resources/Perk_Coin_Master.tres",
	Keys.Slow_It_Down: "res://Perks/Resources/Perk_Slow_it_down.tres",
}


const Keys_scene = {
	Keys.Speed_It_Up:  "res://Perks/PerkBuild/Perk_speed_it_up.tscn",
	Keys.Construction_Expert: "res://Perks/PerkBuild/Perk_construction_expert.tscn",
	Keys.Coin_Master: "res://Perks/PerkBuild/Perk_CoinMaster.tscn",
	Keys.Slow_It_Down: "res://Perks/PerkBuild/Perk_SlowItDown.tscn",
}


static func load_perk(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key))


static func load_perk_res(key : Keys) -> Perk:
	return load(Keys_res.get(key))
