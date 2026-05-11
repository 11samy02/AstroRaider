extends Node

enum Keys {
	Crystal,
	Iron,
	Gold,
	Copper,
	Bomb_key,
}

const drop_szene = {
	Keys.Crystal: "res://scenes/collectables/crystal.tscn",
	Keys.Iron: "res://scenes/collectables/iron_ore.tscn",
	Keys.Gold: "res://scenes/collectables/Gold_ore.tscn",
	Keys.Copper: "res://scenes/collectables/Copper_Ore.tscn",
	Keys.Bomb_key: "res://scenes/actors/enemies/environment/bomb.tscn",
}

const drop_res = {
	Keys.Crystal: "",
	Keys.Iron: "",
	Keys.Gold: "",
	Keys.Copper: "",
	Keys.Bomb_key: "",
}

static var _szene_cache := {}
static var _res_cache := {}

static func load_drop_szene(key: Keys) -> PackedScene:
	var path = drop_szene.get(key)
	if path == null or path == "":
		return null
	if _szene_cache.has(key):
		return _szene_cache[key]
	var scene: PackedScene = load(path)
	_szene_cache[key] = scene
	return scene

static func load_drop_res(key: Keys) -> TileDropResource:
	var path = drop_res.get(key)
	if path == null or path == "":
		return null
	if _res_cache.has(key):
		return _res_cache[key]
	var res: TileDropResource = load(path)
	_res_cache[key] = res
	return res
