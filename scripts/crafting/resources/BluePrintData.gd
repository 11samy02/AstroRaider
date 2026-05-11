extends Node

enum Keys {
	Generator,
	Torrent,
	MetalGround,
	RepairDroneStation,
	BarrierShieldGenerator,
}

const building_tres = {
	Keys.Generator: "res://scenes/objects/objects/crystal_generator.tscn",
	Keys.Torrent: "res://scenes/objects/buildings/torrent.tscn",
	Keys.MetalGround: "res://scenes/objects/buildings/metal_ground.tscn",
	Keys.RepairDroneStation: "res://scenes/objects/buildings/repair_drone_station.tscn",
	Keys.BarrierShieldGenerator: "res://scenes/objects/buildings/barrier_shield_genrator.tscn",
}

const building_res = {
	Keys.Generator: "res://resources/crafting/blueprints/Generator.tres",
	Keys.Torrent: "res://resources/crafting/blueprints/Torrent.tres",
	Keys.MetalGround: "res://resources/crafting/blueprints/MetalGround.tres",
	Keys.RepairDroneStation: "res://resources/crafting/blueprints/RepairDroneStation.tres",
	Keys.BarrierShieldGenerator: "res://resources/crafting/blueprints/BarrierShieldGenerator.tres",
}

static var _tres_cache := {}
static var _res_cache := {}

static func load_Building_tres(key: Keys) -> PackedScene:
	if _tres_cache.has(key):
		return _tres_cache[key]
	var path = building_tres.get(key)
	if path == null:
		return null
	var ps: PackedScene = load(path)
	_tres_cache[key] = ps
	return ps

static func load_Building_res(key: Keys) -> BluePrintResource:
	if _res_cache.has(key):
		return _res_cache[key]
	var path = building_res.get(key)
	if path == null:
		return null
	var res: BluePrintResource = load(path)
	_res_cache[key] = res
	return res
