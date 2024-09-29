extends Node


enum Keys {
	Speed_It_Up,
	Construction_Expert,
	Coin_Master,
	Vampire_Bite,
	Each_Round_Heal,
	Not_So_Fast,
	Barrier_Shield,
	Aim_Bot,
	Extra_Health,
}





const Keys_scene = {
	Keys.Speed_It_Up:  "res://Perks/PerkBuild/Perk_speed_it_up.tscn",
	Keys.Construction_Expert: "res://Perks/PerkBuild/Perk_construction_expert.tscn",
	Keys.Coin_Master: "res://Perks/PerkBuild/Perk_CoinMaster.tscn",
	Keys.Vampire_Bite: "res://Perks/PerkBuild/Perk_Vampire_Bite.tscn",
	Keys.Each_Round_Heal: "res://Perks/PerkBuild/Perk_Each_Round_Heal.tscn",
	Keys.Not_So_Fast: "res://Perks/PerkBuild/Perk_Not_So_Fast.tscn",
	Keys.Barrier_Shield: "res://Perks/PerkBuild/Perk_Barrier_Shield.tscn",
	Keys.Aim_Bot: "res://Perks/PerkBuild/Perk_Aim_Bot.tscn",
	Keys.Extra_Health: "res://Perks/PerkBuild/Perk_Extra_Health.tscn",
}

const Keys_res = {
	Keys.Speed_It_Up: "res://Perks/Resources/Perk_Speed_it_up.tres",
	Keys.Construction_Expert: "res://Perks/Resources/Perk_Construction_expert.tres",
	Keys.Coin_Master: "res://Perks/Resources/Perk_Coin_Master.tres",
	Keys.Vampire_Bite: "res://Perks/Resources/Perk_Vampire_Bite.tres",
	Keys.Each_Round_Heal: "res://Perks/Resources/Perk_Each_Round_Heal.tres",
	Keys.Not_So_Fast: "res://Perks/Resources/Perk_Not_So_Fast.tres",
	Keys.Barrier_Shield: "res://Perks/Resources/Perk_Barrier_Shield.tres",
	Keys.Aim_Bot: "res://Perks/Resources/Perk_Aim_Bot.tres",
	Keys.Extra_Health: "res://Perks/Resources/Perk_Extra_Health.tres",
}

func _ready() -> void:
	for key in PerkData.Keys.values():
		print("Valid Key: ", key)


static func load_perk_scene(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key))


static func load_perk_res(key: Keys) -> Perk:
	return load(Keys_res.get(key))
