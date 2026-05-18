extends Node

signal active_slot_changed(slot_id: int)
signal save_loaded(slot_id: int)
signal save_saved(slot_id: int)
signal suit_progress_changed(suit_key: SuitData.SuitKeys, current_level: int, current_exp: int, levels_gained: int)

const MAX_SAVE_SLOTS := 5
const DEFAULT_SLOT := 1
const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const SAVE_FILE_PREFIX := "save_slot_"
const SAVE_FILE_EXTENSION := ".cfg"

const META_SECTION := "meta"
const META_VERSION := "version"
const META_CREATED_AT := "created_at"
const META_UPDATED_AT := "updated_at"
const META_SELECTED_SUIT := "selected_suit"

const SUIT_LEVEL := "current_level"
const SUIT_EXP := "current_exp"
const SUIT_UNLOCKED := "has_unlocked"

const SAVE_PASSWORD := "AstroRaider_v7Qm9Lx2KpR4sT8nY6bH3zW1aF5dG0uJ"

var active_slot := DEFAULT_SLOT
var config := ConfigFile.new()
var _loaded := false


func _ready() -> void:
	load_slot(active_slot)


func is_valid_slot(slot_id: int) -> bool:
	return slot_id >= 1 and slot_id <= MAX_SAVE_SLOTS


func get_save_path(slot_id: int = -1) -> String:
	var safe_slot := active_slot if slot_id == -1 else clampi(slot_id, 1, MAX_SAVE_SLOTS)
	return SAVE_DIR.path_join("%s%s%s" % [SAVE_FILE_PREFIX, safe_slot, SAVE_FILE_EXTENSION])


func get_player_builds_path(slot_id: int = -1) -> String:
	var safe_slot := active_slot if slot_id == -1 else clampi(slot_id, 1, MAX_SAVE_SLOTS)
	return SAVE_DIR.path_join("slot_%s_character_builds.res" % safe_slot)


func save_exists(slot_id: int) -> bool:
	if not is_valid_slot(slot_id):
		return false

	return FileAccess.file_exists(get_save_path(slot_id))


func list_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []

	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		var slot_data := {
			"slot_id": slot_id,
			"exists": save_exists(slot_id),
			"created_at": "",
			"updated_at": "",
			"selected_suit": int(SuitData.SuitKeys.Trailblazer),
		}

		if slot_data["exists"]:
			var slot_config := ConfigFile.new()
			if slot_config.load_encrypted_pass(get_save_path(slot_id), SAVE_PASSWORD) == OK:
				slot_data["created_at"] = str(slot_config.get_value(META_SECTION, META_CREATED_AT, ""))
				slot_data["updated_at"] = str(slot_config.get_value(META_SECTION, META_UPDATED_AT, ""))
				slot_data["selected_suit"] = int(slot_config.get_value(META_SECTION, META_SELECTED_SUIT, int(SuitData.SuitKeys.Trailblazer)))

		slots.append(slot_data)

	return slots


func load_slot(slot_id: int) -> bool:
	if not is_valid_slot(slot_id):
		push_warning("Invalid save slot: " + str(slot_id))
		return false

	_ensure_save_dir()

	config = ConfigFile.new()
	var error := config.load_encrypted_pass(get_save_path(slot_id), SAVE_PASSWORD)

	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_warning("Could not load save slot %s. Creating a fresh save. Error: %s" % [slot_id, error])
		_set_default_save_data()
	else:
		_migrate_save_data()

	active_slot = slot_id
	_loaded = true
	save_current_slot()
	active_slot_changed.emit(active_slot)
	save_loaded.emit(active_slot)
	return true


func new_game(slot_id: int) -> bool:
	if not is_valid_slot(slot_id):
		push_warning("Invalid save slot: " + str(slot_id))
		return false

	_ensure_save_dir()
	active_slot = slot_id
	config = ConfigFile.new()
	_set_default_save_data()
	_loaded = true
	var saved := save_current_slot()
	active_slot_changed.emit(active_slot)
	save_loaded.emit(active_slot)
	return saved


func save_current_slot() -> bool:
	if not _loaded:
		return false
	
	_ensure_save_dir()
	config.set_value(META_SECTION, META_UPDATED_AT, Time.get_datetime_string_from_system())
	
	var error := config.save_encrypted_pass(get_save_path(active_slot), SAVE_PASSWORD)
	
	if error == OK:
		save_saved.emit(active_slot)
		return true

	push_warning("Could not save slot %s. Error: %s" % [active_slot, error])
	return false


func delete_slot(slot_id: int) -> bool:
	if not is_valid_slot(slot_id) or not save_exists(slot_id):
		return false

	var error := DirAccess.remove_absolute(get_save_path(slot_id))

	if error != OK:
		push_warning("Could not delete save slot %s. Error: %s" % [slot_id, error])
		return false

	var builds_path := get_player_builds_path(slot_id)

	if FileAccess.file_exists(builds_path):
		DirAccess.remove_absolute(builds_path)

	if slot_id == active_slot:
		load_slot(DEFAULT_SLOT)

	return true


func ensure_loaded() -> void:
	if not _loaded:
		load_slot(active_slot)


func set_selected_suit(suit_key: SuitData.SuitKeys) -> void:
	ensure_loaded()
	config.set_value(META_SECTION, META_SELECTED_SUIT, int(suit_key))
	save_current_slot()


func get_selected_suit() -> SuitData.SuitKeys:
	ensure_loaded()
	return int(config.get_value(META_SECTION, META_SELECTED_SUIT, int(SuitData.SuitKeys.Trailblazer)))


func get_suit_progress(suit_key: SuitData.SuitKeys) -> Dictionary:
	ensure_loaded()
	_ensure_suit_progress(suit_key)

	var section := _get_suit_section(suit_key)

	return {
		"current_level": int(config.get_value(section, SUIT_LEVEL, 1)),
		"current_exp": int(config.get_value(section, SUIT_EXP, 0)),
		"has_unlocked": bool(config.get_value(section, SUIT_UNLOCKED, false)),
	}


func apply_saved_suit_progress(suit_data: SuitData) -> void:
	if not is_instance_valid(suit_data):
		return

	var progress := get_suit_progress(suit_data.Key)
	suit_data.current_level = clampi(int(progress.get("current_level", suit_data.current_level)), 1, suit_data.max_level)
	suit_data.current_exp = max(0, int(progress.get("current_exp", suit_data.current_exp)))
	suit_data.has_unlocked = bool(progress.get("has_unlocked", suit_data.has_unlocked))

	if suit_data.is_max_level():
		suit_data.current_exp = 0


func save_suit_progress(suit_data: SuitData) -> bool:
	if not is_instance_valid(suit_data):
		return false

	ensure_loaded()
	_write_suit_progress(
		suit_data.Key,
		suit_data.current_level,
		suit_data.current_exp,
		suit_data.has_unlocked,
		suit_data.max_level
	)

	return save_current_slot()


func unlock_suit(suit_key: SuitData.SuitKeys, should_save := true) -> void:
	ensure_loaded()
	_ensure_suit_progress(suit_key)
	config.set_value(_get_suit_section(suit_key), SUIT_UNLOCKED, true)

	if should_save:
		save_current_slot()


func add_suit_exp(suit_key: SuitData.SuitKeys, amount: int, multiplier: float = 1.0) -> Dictionary:
	ensure_loaded()

	var result := {
		"saved": false,
		"applied_exp": 0,
		"levels_gained": 0,
		"current_level": 1,
		"current_exp": 0,
		"exp_to_next": 0,
		"has_unlocked": false,
	}

	if amount <= 0:
		return result

	var suit_data := SuitData.load_base_suit_res(suit_key)

	if not is_instance_valid(suit_data):
		push_warning("Cannot add EXP to missing suit: " + str(suit_key))
		return result

	apply_saved_suit_progress(suit_data)

	var final_exp := int(round(float(amount) * maxf(multiplier, 0.0)))

	if final_exp <= 0:
		return result

	var levels_gained := suit_data.add_exp(final_exp)
	var saved := save_suit_progress(suit_data)

	result["saved"] = saved
	result["applied_exp"] = final_exp
	result["levels_gained"] = levels_gained
	result["current_level"] = suit_data.current_level
	result["current_exp"] = suit_data.current_exp
	result["exp_to_next"] = suit_data.get_exp_to_next_level()
	result["has_unlocked"] = suit_data.has_unlocked

	if saved:
		suit_progress_changed.emit(suit_key, suit_data.current_level, suit_data.current_exp, levels_gained)

	return result


func _set_default_save_data() -> void:
	var now := Time.get_datetime_string_from_system()
	config.set_value(META_SECTION, META_VERSION, SAVE_VERSION)
	config.set_value(META_SECTION, META_CREATED_AT, now)
	config.set_value(META_SECTION, META_UPDATED_AT, now)
	config.set_value(META_SECTION, META_SELECTED_SUIT, int(SuitData.SuitKeys.Trailblazer))

	for suit_key in SuitData.Keys_res.keys():
		_write_default_suit_progress(suit_key)


func _migrate_save_data() -> void:
	if not config.has_section_key(META_SECTION, META_VERSION):
		config.set_value(META_SECTION, META_VERSION, SAVE_VERSION)

	if not config.has_section_key(META_SECTION, META_CREATED_AT):
		config.set_value(META_SECTION, META_CREATED_AT, Time.get_datetime_string_from_system())

	if not config.has_section_key(META_SECTION, META_SELECTED_SUIT):
		config.set_value(META_SECTION, META_SELECTED_SUIT, int(SuitData.SuitKeys.Trailblazer))

	for suit_key in SuitData.Keys_res.keys():
		_ensure_suit_progress(suit_key)


func _ensure_suit_progress(suit_key: SuitData.SuitKeys) -> void:
	var section := _get_suit_section(suit_key)

	if not config.has_section(section):
		_write_default_suit_progress(suit_key)
		return

	var default_suit := SuitData.load_base_suit_res(suit_key)
	var max_level := 100
	var default_level := 1
	var default_exp := 0
	var default_unlocked := false

	if is_instance_valid(default_suit):
		max_level = default_suit.max_level
		default_level = default_suit.current_level
		default_exp = default_suit.current_exp
		default_unlocked = default_suit.has_unlocked

	var level := clampi(int(config.get_value(section, SUIT_LEVEL, default_level)), 1, max_level)
	var exp = max(0, int(config.get_value(section, SUIT_EXP, default_exp)))

	if level >= max_level:
		exp = 0

	config.set_value(section, SUIT_LEVEL, level)
	config.set_value(section, SUIT_EXP, exp)
	config.set_value(section, SUIT_UNLOCKED, bool(config.get_value(section, SUIT_UNLOCKED, default_unlocked)))


func _write_default_suit_progress(suit_key: SuitData.SuitKeys) -> void:
	var default_suit := SuitData.load_base_suit_res(suit_key)
	var level := 1
	var exp := 0
	var unlocked := false
	var max_level := 100

	if is_instance_valid(default_suit):
		level = default_suit.current_level
		exp = default_suit.current_exp
		unlocked = default_suit.has_unlocked
		max_level = default_suit.max_level

	_write_suit_progress(suit_key, level, exp, unlocked, max_level)


func _write_suit_progress(
	suit_key: SuitData.SuitKeys,
	level: int,
	exp: int,
	unlocked: bool,
	max_level: int
) -> void:
	var section := _get_suit_section(suit_key)
	var safe_level := clampi(level, 1, max_level)
	var safe_exp = max(0, exp)

	if safe_level >= max_level:
		safe_exp = 0

	config.set_value(section, SUIT_LEVEL, safe_level)
	config.set_value(section, SUIT_EXP, safe_exp)
	config.set_value(section, SUIT_UNLOCKED, unlocked)


func _get_suit_section(suit_key: SuitData.SuitKeys) -> String:
	return "suit_%s" % int(suit_key)


func _ensure_save_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return

	var error := DirAccess.make_dir_recursive_absolute(SAVE_DIR)

	if error != OK:
		push_warning("Could not create save directory. Error: " + str(error))
