extends Node

const LEGACY_SAVE_FILE_PATH := "user://CharacterBuilds.res"

## Runtime save container for all player builds.
@export var player_saved_res : PlayerSavesResource = PlayerSavesResource.new()

## File path used for player build persistence.
var save_file_path : String = "user://saves/slot_1_character_builds.res"

## Loads persisted player builds and creates an empty save file when none exists.
func _ready() -> void:
	_refresh_save_file_path()
	_connect_game_saver_signals()
	var slot_build_save_exists := FileAccess.file_exists(save_file_path)
	player_saved_res = load_file()
	if player_saved_res.saved_builds.is_empty() or not slot_build_save_exists:
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
	_ensure_save_dir()
	var error = ResourceSaver.save(player_saved_res, save_file_path)
	if error == OK:
		print("Resourcen erfolgreich gespeichert.")
	else:
		print("Fehler beim Speichern der Ressourcen: ", error)


## Loads saved player builds from disk.
func load_file() -> PlayerSavesResource:
	var loaded_file = null

	if FileAccess.file_exists(save_file_path):
		loaded_file = ResourceLoader.load(save_file_path)

	if loaded_file and loaded_file is PlayerSavesResource :
		print("Resource erfolgreich geladen")
		return loaded_file

	if _should_try_legacy_build_save():
		var legacy_file = null

		if FileAccess.file_exists(LEGACY_SAVE_FILE_PATH):
			legacy_file = ResourceLoader.load(LEGACY_SAVE_FILE_PATH)

		if legacy_file and legacy_file is PlayerSavesResource:
			print("Legacy Resource erfolgreich geladen")
			return legacy_file

	print("Fehler: Geladene Datei konnte nicht gelesen werden")
	return PlayerSavesResource.new()

## Deletes a saved build by index.
func delete_build(id) -> void:
	if player_saved_res.saved_builds.size() > id:
		player_saved_res.saved_builds.remove_at(id)
		save_file()


func _on_active_slot_changed(_slot_id: int) -> void:
	_refresh_save_file_path()
	var slot_build_save_exists := FileAccess.file_exists(save_file_path)
	player_saved_res = load_file()
	if player_saved_res.saved_builds.is_empty() or not slot_build_save_exists:
		save_file()


func _refresh_save_file_path() -> void:
	var game_saver := _get_game_saver()

	if game_saver != null and game_saver.has_method("get_player_builds_path"):
		save_file_path = game_saver.get_player_builds_path()


func _connect_game_saver_signals() -> void:
	var game_saver := _get_game_saver()

	if game_saver == null or not game_saver.has_signal("active_slot_changed"):
		return

	var callback := Callable(self, "_on_active_slot_changed")

	if not game_saver.is_connected("active_slot_changed", callback):
		game_saver.connect("active_slot_changed", callback)


func _get_game_saver() -> Node:
	var main_loop := Engine.get_main_loop()

	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("GameSaver")

	return null


func _should_try_legacy_build_save() -> bool:
	var game_saver := _get_game_saver()

	if game_saver == null:
		return true

	return int(game_saver.get("active_slot")) == 1


func _ensure_save_dir() -> void:
	var save_dir := save_file_path.get_base_dir()

	if save_dir == "" or DirAccess.dir_exists_absolute(save_dir):
		return

	var error := DirAccess.make_dir_recursive_absolute(save_dir)

	if error != OK:
		push_warning("Could not create player build save directory. Error: " + str(error))
