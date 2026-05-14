extends Node

## Runtime save container for all player builds.
@export var player_saved_res : PlayerSavesResource = PlayerSavesResource.new()

## File path used for player build persistence.
var save_file_path : String = "user://CharacterBuilds.res"

## Loads persisted player builds and creates an empty save file when none exists.
func _ready() -> void:
	player_saved_res = load_file()
	if player_saved_res.saved_builds.is_empty():
		save_file()

## Adds a new build using the selected suit and already unlocked perks.
func add_build(
	name_of_build: String,
	Perks: Array[Perk],
	selected_suit: SuitData.SuitKeys = SuitData.SuitKeys.Trailblazer
) -> void:
	var character_build : PlayerCharacterBuild = PlayerCharacterBuild.new()
	
	character_build.build_name = name_of_build
	character_build.selected_suit = selected_suit
	
	for perk: Perk in Perks:
		if is_instance_valid(perk):
			var perk_copy := perk.duplicate(true)
			if perk_copy is Perk:
				character_build.unlocked_perks.append(perk_copy)
	
	player_saved_res.saved_builds.append(character_build)
	save_file()


## Persists all saved builds to disk.
func save_file() -> void:
	var error = ResourceSaver.save(player_saved_res, save_file_path)
	if error == OK:
		print("Resourcen erfolgreich gespeichert.")
	else:
		print("Fehler beim Speichern der Ressourcen: ", error)


## Loads saved player builds from disk.
func load_file() -> PlayerSavesResource:
	var loaded_file = ResourceLoader.load(save_file_path)
	
	if loaded_file and loaded_file is PlayerSavesResource :
		print("Resource erfolgreich geladen")
		return loaded_file
	else:
		print("Fehler: Geladene Datei konnte nicht gelesen werden")
		return PlayerSavesResource.new()

## Deletes a saved build by index.
func delete_build(id) -> void:
	if player_saved_res.saved_builds.size() > id:
		player_saved_res.saved_builds.remove_at(id)
		save_file()
