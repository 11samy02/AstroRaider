extends Node

@export var player_saved_res : PlayerSavesResource = PlayerSavesResource.new()

var save_file_path : String = "user://CharacterBuilds.res"

func _ready() -> void:
	var perks : Array[Perk] = []
	perks.append(PerkData.load_perk_scene_res(PerkData.Keys.Vampire_Bite))
	perks.append(PerkData.load_perk_scene_res(PerkData.Keys.Speed_It_Up))
	perks.append(PerkData.load_perk_scene_res(PerkData.Keys.Construction_Expert))
	perks.append(PerkData.load_perk_scene_res(PerkData.Keys.Coin_Master))
	perks.append(PerkData.load_perk_scene_res(PerkData.Keys.Slow_It_Down))
	add_build("default", perks)
	save_file()
	player_saved_res = load_file()

func add_build(name_of_build: String, Perks: Array[Perk]) -> void:
	var character_build : PlayerCharacterBuild = PlayerCharacterBuild.new()
	
	character_build.build_name = name_of_build
	
	var keys = PerkData.Keys
	
	for perk: Perk in Perks:
		character_build.stats.Perks.append(perk)
	
	player_saved_res.saved_builds.append(character_build)
	save_file()


func save_file() -> void:
	var error = ResourceSaver.save(player_saved_res, save_file_path)
	if error == OK:
		print("Resourcen erfolgreich gespeichert.")
	else:
		print("Fehler beim Speichern der Ressourcen: ", error)


func load_file() -> PlayerSavesResource:
	var loaded_file = ResourceLoader.load(save_file_path)
	
	if loaded_file and loaded_file is PlayerSavesResource :
		print("Resource erfolgreich geladen")
		return loaded_file
	else:
		print("Fehler: Geladene Datei konnte nicht gelesen werden")
		return PlayerSavesResource.new()

func delete_build(id) -> void:
	if player_saved_res.saved_builds.size() > id:
		player_saved_res.saved_builds.remove_at(id)
		save_file()
