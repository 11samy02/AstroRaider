extends Node


enum Keys {
	Speed_It_Up,
	Construction_Expert,
	Coin_Master,
	Slow_It_Down,
	Vampire_Bite,
	Each_Round_Heal,
	Not_So_Fast,
	Barrier_Shield,
	#Aim_Bot,
}





const Keys_scene = {
	Keys.Speed_It_Up:  "res://Perks/PerkBuild/Perk_speed_it_up.tscn",
	Keys.Construction_Expert: "res://Perks/PerkBuild/Perk_construction_expert.tscn",
	Keys.Coin_Master: "res://Perks/PerkBuild/Perk_CoinMaster.tscn",
	Keys.Slow_It_Down: "res://Perks/PerkBuild/Perk_SlowItDown.tscn",
	Keys.Vampire_Bite: "res://Perks/PerkBuild/Perk_Vampire_Bite.tscn",
	Keys.Each_Round_Heal: "res://Perks/PerkBuild/Perk_Each_Round_Heal.tscn",
	Keys.Not_So_Fast: "res://Perks/PerkBuild/Perk_Not_So_Fast.tscn",
	Keys.Barrier_Shield: "res://Perks/PerkBuild/Perk_Barrier_Shield.tscn",
	#Keys.Aim_Bot: "",
}

const Keys_res = {
	Keys.Speed_It_Up: "res://Perks/Resources/Perk_Speed_it_up.tres",
	Keys.Construction_Expert: "res://Perks/Resources/Perk_Construction_expert.tres",
	Keys.Coin_Master: "res://Perks/Resources/Perk_Coin_Master.tres",
	Keys.Slow_It_Down: "res://Perks/Resources/Perk_Slow_it_down.tres",
	Keys.Vampire_Bite: "res://Perks/Resources/Perk_Vampire_Bite.tres",
	Keys.Each_Round_Heal: "res://Perks/Resources/Perk_Each_Round_Heal.tres",
	Keys.Not_So_Fast: "res://Perks/Resources/Perk_Not_So_Fast.tres",
	Keys.Barrier_Shield: "res://Perks/Resources/Perk_Barrier_Shield.tres",
	#Keys.Aim_Bot: "res://Perks/Resources/Perk_Aim_Bot.tres",
}

func _ready() -> void:
	for key in PerkData.Keys.values():
		print("Valid Key: ", key)


static func load_perk_scene(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key))


static func load_perk_res(key: Keys) -> Perk:
	var res_path = Keys_res.get(key)
	print("Loading perk resource for key: ", key, " at path: ", res_path)
	var perk_res = load(res_path)
	if perk_res == null:
		print("Error: Could not load perk resource at path: ", res_path)
	return perk_res
