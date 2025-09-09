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
	Energy_Overload,
	Emergency_Heal,
	Anti_Mine_Detection,
	Resource_Sharing,
	Group_Momentum, # -> Erhöht die Bewegungsgeschwindigkeit des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
	Rallying_Cry, # -> Erhöht den Schaden des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
	Protective_Aura, # -> mindert den erlitenen Schaden des Teams leicht, wenn sich andere Teammitglieder in der Nähe befinden
	Critical_Edge,
	Power_Shot,
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
	Keys.Jet_Boost: "",
	Keys.Piercing_Shot: "res://Perks/PerkBuild/Perk_Piercing_Shot.tscn",
	Keys.Stun_Grenade: "res://Perks/PerkBuild/Perk_Stun_Grenade.tscn",
	Keys.Energy_Overload: "res://Perks/PerkBuild/Perk_Energy_Overload.tscn",
	Keys.Emergency_Heal: "res://Perks/PerkBuild/Perk_Emergency_Heal.tscn",
	Keys.Anti_Mine_Detection: "res://Perks/PerkBuild/Perk_Anti_Mine_Detection.tscn",
	Keys.Resource_Sharing: "res://Perks/PerkBuild/Perk_Resource_Sharing.tscn",
	Keys.Group_Momentum: "",
	Keys.Rallying_Cry: "",
	Keys.Protective_Aura: "",
	Keys.Critical_Edge: "res://Perks/PerkBuild/Perk_Critical_Edge.tscn",
	Keys.Power_Shot: "res://Perks/PerkBuild/Perk_Power_Shot.tscn",
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
	Keys.Jet_Boost: "",
	Keys.Piercing_Shot: "res://Perks/Resources/Perk_Piercing_Shot.tres",
	Keys.Stun_Grenade: "res://Perks/Resources/Perk_Stun_Grenade.tres",
	Keys.Energy_Overload: "res://Perks/Resources/Perk_Energy_Overload.tres",
	Keys.Emergency_Heal: "res://Perks/Resources/Perk_Emergency_Heal.tres",
	Keys.Anti_Mine_Detection: "res://Perks/Resources/Perk_Anti_Mine_Detection.tres",
	Keys.Resource_Sharing: "res://Perks/Resources/Perk_Resource_Sharing.tres",
	Keys.Group_Momentum: "",
	Keys.Rallying_Cry: "",
	Keys.Protective_Aura: "",
	Keys.Critical_Edge: "res://Perks/Resources/Perk_Critical_Edge.tres",
	Keys.Power_Shot: "res://Perks/Resources/Perk_Power_Shot.tres",
}


static func load_perk_scene(key : Keys) -> PackedScene:
	return load(Keys_scene.get(key)).duplicate()


static func load_perk_res(key: Keys) -> Perk:
	return load(Keys_res.get(key)).duplicate()
