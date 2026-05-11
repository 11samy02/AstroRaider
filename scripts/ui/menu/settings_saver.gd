extends Node

const SETTINGS_PATH := "user://settings.cfg"

var config := ConfigFile.new()


func _ready() -> void:
	load_settings()
	apply_all_settings()


func load_settings() -> void:
	var error := config.load(SETTINGS_PATH)

	if error != OK:
		set_default_settings()
		save_settings()


func save_settings() -> void:
	config.save(SETTINGS_PATH)


func set_default_settings() -> void:
	config.set_value("audio", "Music_enabled", true)
	config.set_value("audio", "Sfx_enabled", true)
	config.set_value("audio", "ui_enabled", true)

	config.set_value("audio_volume", "Master", 100.0)
	config.set_value("audio_volume", "Music", 100.0)
	config.set_value("audio_volume", "Sfx", 100.0)
	config.set_value("audio_volume", "ui", 100.0)

	config.set_value("audio", "output_device", "")

	config.set_value("video", "display_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	config.set_value("video", "resolution_x", 1280)
	config.set_value("video", "resolution_y", 720)
	config.set_value("video", "monitor", 0)
	config.set_value("video", "max_fps", 0)
	config.set_value("video", "vsync_enabled", true)


func get_setting(section: String, key: String, default_value: Variant) -> Variant:
	return config.get_value(section, key, default_value)


func set_setting(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	save_settings()


# --------------------------------------------------
# Audio Checkbox Save
# --------------------------------------------------

func save_audio_bus_enabled(bus_name: String, enabled: bool) -> void:
	set_setting("audio", bus_name + "_enabled", enabled)


func get_audio_bus_enabled(bus_name: String) -> bool:
	return get_setting("audio", bus_name + "_enabled", true)


func apply_bus_enabled(bus_name: String, enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	AudioServer.set_bus_mute(bus_index, not enabled)


# --------------------------------------------------
# Audio Volume Save für MenuSlider
# --------------------------------------------------

func save_audio_bus_volume_percent(bus_name: String, percent: float) -> void:
	percent = clamp(percent, 0.0, 100.0)
	config.set_value("audio_volume", bus_name, percent)
	save_settings()


func get_audio_bus_volume_percent(bus_name: String, default_percent: float = 100.0) -> float:
	return config.get_value("audio_volume", bus_name, default_percent)


func apply_audio_bus_volume_percent(bus_name: String, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	percent = clamp(percent, 0.0, 100.0)

	var db := -80.0

	if percent > 0.0:
		db = linear_to_db(percent / 100.0)

	AudioServer.set_bus_volume_db(bus_index, db)


# --------------------------------------------------
# Audio Device
# --------------------------------------------------

func save_output_device(device_name: String) -> void:
	set_setting("audio", "output_device", device_name)


func get_output_device() -> String:
	return get_setting("audio", "output_device", "")


func apply_output_device() -> void:
	var saved_device := get_output_device()

	if saved_device.is_empty():
		return

	var devices := AudioServer.get_output_device_list()

	if devices.has(saved_device):
		AudioServer.set_output_device(saved_device)


# --------------------------------------------------
# Apply Audio
# --------------------------------------------------

func apply_audio_settings() -> void:
	apply_bus_enabled("Music", get_audio_bus_enabled("Music"))
	apply_bus_enabled("Sfx", get_audio_bus_enabled("Sfx"))
	apply_bus_enabled("ui", get_audio_bus_enabled("ui"))

	apply_audio_bus_volume_percent("Master", get_audio_bus_volume_percent("Master", 100.0))
	apply_audio_bus_volume_percent("Music", get_audio_bus_volume_percent("Music", 100.0))
	apply_audio_bus_volume_percent("Sfx", get_audio_bus_volume_percent("Sfx", 100.0))
	apply_audio_bus_volume_percent("ui", get_audio_bus_volume_percent("ui", 100.0))

	apply_output_device()


# --------------------------------------------------
# Video Save
# --------------------------------------------------

func save_display_mode(mode: int) -> void:
	set_setting("video", "display_mode", mode)


func save_resolution(size: Vector2i) -> void:
	config.set_value("video", "resolution_x", size.x)
	config.set_value("video", "resolution_y", size.y)
	save_settings()


func save_monitor(monitor_index: int) -> void:
	set_setting("video", "monitor", monitor_index)


func save_fps_limit(fps: int) -> void:
	set_setting("video", "max_fps", fps)


func save_vsync_enabled(enabled: bool) -> void:
	set_setting("video", "vsync_enabled", enabled)


func get_saved_monitor() -> int:
	return get_setting("video", "monitor", 0)


func apply_video_settings() -> void:
	var screen_count := DisplayServer.get_screen_count()
	var monitor_index: int = get_setting("video", "monitor", 0)

	if screen_count > 0:
		monitor_index = clamp(monitor_index, 0, screen_count - 1)
		DisplayServer.window_set_current_screen(monitor_index)

	var display_mode: int = get_setting("video", "display_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_mode(display_mode)

	var resolution := Vector2i(
		get_setting("video", "resolution_x", 1280),
		get_setting("video", "resolution_y", 720)
	)

	if display_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)
		center_window_on_monitor(monitor_index)

	var fps: int = get_setting("video", "max_fps", 0)
	Engine.max_fps = fps

	var vsync_enabled: bool = get_setting("video", "vsync_enabled", true)

	if vsync_enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func center_window_on_monitor(monitor_index: int) -> void:
	var screen_count := DisplayServer.get_screen_count()

	if screen_count <= 0:
		return

	monitor_index = clamp(monitor_index, 0, screen_count - 1)

	var screen_pos := DisplayServer.screen_get_position(monitor_index)
	var screen_size := DisplayServer.screen_get_size(monitor_index)
	var window_size := DisplayServer.window_get_size()

	DisplayServer.window_set_position(screen_pos + ((screen_size - window_size) / 2))


func apply_all_settings() -> void:
	apply_audio_settings()
	apply_video_settings()
