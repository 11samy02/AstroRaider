extends Node

enum Keys {
	Generator,
	Torrent,
	MetalGround,
	RepairDroneStation,
	BarrierShieldGenerator,
}

const building_tres = {
	Keys.Generator: "res://Objects/Objects/crystal_generator.tscn",
	Keys.Torrent: "res://Objects/Buildings/torrent.tscn",
	Keys.MetalGround: "res://Objects/Buildings/metal_ground.tscn",
	Keys.RepairDroneStation: "res://Objects/Buildings/repair_drone_station.tscn",
	Keys.BarrierShieldGenerator: "res://Objects/Buildings/barrier_shield_genrator.tscn",
}

const building_res = {
	Keys.Generator: "res://Crafting/Resources/BluePrints/Generator.tres",
	Keys.Torrent: "res://Crafting/Resources/BluePrints/Torrent.tres",
	Keys.MetalGround: "res://Crafting/Resources/BluePrints/MetalGround.tres",
	Keys.RepairDroneStation: "res://Crafting/Resources/BluePrints/RepairDroneStation.tres",
	Keys.BarrierShieldGenerator: "res://Crafting/Resources/BluePrints/BarrierShieldGenerator.tres",
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
