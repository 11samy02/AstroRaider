extends Resource
class_name SuitData

enum SuitKeys {
	NONE,
	Trailblazer,
	Bloodreaver,
}

## Resource paths for every available suit key.
const Keys_res = {
	SuitKeys.Trailblazer: "res://resources/characters/Suit_Trailblazer.tres",
	SuitKeys.Bloodreaver: "res://resources/characters/Suit_Bloodreaver.tres",
}

## In-memory cache for loaded suit resources.
static var _res_cache := {}

@export_category("General")
## Unique key used to load and compare this suit.
@export var Key: SuitKeys = SuitKeys.Trailblazer
## Display name shown for this suit.
@export var suit_name := ""
## Player-facing description of the suit.
@export_multiline var description := ""
## Image for the Suit
@export var image : Texture2D

@export_category("Progress")
## Current meta progression level for this suit.
@export_range(1, 100) var current_level := 1
## Whether this suit is unlocked for player use.
@export var has_unlocked := false

@export_category("Stats")
## Base stats granted while this suit is selected.
@export var stats: Stats = Stats.new()


## Loads a suit resource by key and returns a deep duplicate for runtime use.
static func load_suit_res(key: SuitKeys) -> SuitData:
	var path = Keys_res.get(key)
	if path == null or path == "":
		return null
	if _res_cache.has(key):
		return _res_cache[key].duplicate(true)
	var res: SuitData = load(path)
	if not is_instance_valid(res):
		return null
	_res_cache[key] = res
	return res.duplicate(true)
