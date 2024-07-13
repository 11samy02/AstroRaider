extends Node

var saved_builds : Array[PlayerCharacterBuild]

func _ready() -> void:
	add_build()

func add_build() -> void:
	var character_build : PlayerCharacterBuild = PlayerCharacterBuild.new()
	
	character_build.build_name = "Default"
	
	var keys = PerkData.Keys
	
	var perk : Perk = PerkData.load_perk_res(keys.Speed_It_Up)
	var perk2 : Perk = PerkData.load_perk_res(keys.Construction_Expert)
	
	character_build.stats.Perks.append(perk)
	character_build.stats.Perks.append(perk2)
	
	saved_builds.append(character_build)
