extends Node


enum Keys {
	Speed_It_Up,
	Construction_Expert,
	Coin_Master,
	Vampire_Bite,
	Each_Round_Heal,
	Resilience,
	Barrier_Shield,
	Aim_Bot,
	Extra_Health,
	Jet_Boost, # -> gibt die möglichkeit einen Art Dash in einer richtung zu machen
	Piercing_Shot, # -> ermöglicht schüsse die gegner zu durchdringen
	Stun_Grenade, # -> gegner werden beim treffer kurzeitig betäubt
	Energy_Overload, # -> erhöht für eine gewissen zeitraum verschiedene stats
	Emergency_Heal, # -> hielt dich im Notfall
	Anti_Mine_Detection, # -> signalisiert das sich in der nähe eine Bombe befindet
	Resource_Sharing, # -> beim einsammeln von Kristallen erhält das team auch einen Kleinen Bonus der Kristalle
	Group_Momentum, # -> Erhöht die Bewegungsgeschwindigkeit des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
	Rallying_Cry, # -> Erhöht den Schaden des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
	Protective_Aura, # -> mindert den erlitenen Schaden des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
}





const Keys_scene = {
	Keys.Speed_It_Up:  "res://Perks/PerkBuild/Perk_speed_it_up.tscn",
	Keys.Construction_Expert: "res://Perks/PerkBuild/Perk_construction_expert.tscn",
	Keys.Coin_Master: "res://Perks/PerkBuild/Perk_CoinMaster.tscn",
	Keys.Vampire_Bite: "res://Perks/PerkBuild/Perk_Vampire_Bite.tscn",
	Keys.Each_Round_Heal: "res://Perks/PerkBuild/Perk_Each_Round_Heal.tscn",
	Keys.Resilience: "res://Perks/PerkBuild/Perk_Resilience.tscn",
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
	Keys.Resilience: "res://Perks/Resources/Perk_Resilience.tres",
	Keys.Barrier_Shield: "res://Perks/Resources/Perk_Barrier_Shield.tres",
	Keys.Aim_Bot: "res://Perks/Resources/Perk_Aim_Bot.tres",
	Keys.Extra_Health: "res://Perks/Resources/Perk_Extra_Health.tres",
}


static func load_perk_scene(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key))


static func load_perk_res(key: Keys) -> Perk:
	return load(Keys_res.get(key))
