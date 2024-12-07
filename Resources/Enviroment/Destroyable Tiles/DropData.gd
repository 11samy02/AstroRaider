extends Node

enum Keys {
	Crystal,
	Iron,
	Gold,
	Copper,
	Bomb_key,
}

const drop_szene = {
	Keys.Crystal: "res://Collectable/crystal.tscn",
	Keys.Iron: "res://Collectable/iron_ore.tscn",
	Keys.Gold: "res://Collectable/Gold_ore.tscn",
	Keys.Copper: "res://Collectable/Copper_Ore.tscn",
	Keys.Bomb_key: "res://Actors/Enemys/Enviroment/bomb.tscn",
}

const drop_res = {
	Keys.Crystal: "",
	Keys.Iron: "",
	Keys.Gold: "",
	Keys.Copper: "",
	Keys.Bomb_key: "",
}

static func load_drop_szene(key: Keys) -> PackedScene:
	return load(drop_szene.get(key))


static func load_drop_res(key: Keys) -> TileDropResource:
	return load(drop_res.get(key))
