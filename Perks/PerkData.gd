extends Node


enum Keys {
	Speed_It_Up,
	Construction_Expert,
}




const Keys_res = {
	Keys.Speed_It_Up: "res://Perks/Resources/Speed_it_up.tres",
	Keys.Construction_Expert: "res://Perks/Resources/Construction_expert.tres",
}


const Keys_szene = {
	Keys.Speed_It_Up:  "res://Perks/PerkBuild/speed_it_up.tscn",
	Keys.Construction_Expert: "res://Perks/PerkBuild/construction_expert.tscn",
}


static func load_perk(key : Keys) -> PackedScene:
	return load(Keys_szene.get(key))

