extends Node

@onready var switch_sound_on: Audio2D = $"../../Sounds/switch_sound_on"
@onready var switch_sound_off: Audio2D = $"../../Sounds/switch_sound_off"

@onready var music_on_checkbox: CheckButton = %music_on_checkbox
@onready var sounds_on_checkbox: CheckButton = %sounds_on_checkbox
@onready var ui_on_checkbox: CheckButton = %ui_on_checkbox

@onready var left_device: Button = %left_device
@onready var device_selected_text: Button = %device_selected_text
@onready var right_device: Button = %right_device

@onready var master_volume: MenuSlider = %MasterVolume
@onready var music_volume: MenuSlider = %MusicVolume
@onready var sfx_volume: MenuSlider = %SFXVolume
@onready var ui_volume: MenuSlider = %UIVolume

var devices: PackedStringArray = []


func _ready() -> void:
	devices = AudioServer.get_output_device_list()
	
	SettingsSaver.apply_audio_settings()
	
	set_initial_states()
	connect_signals()
	update_device_text()
	
	call_deferred("refresh_menu_sliders")


func connect_signals() -> void:
	music_on_checkbox.toggled.connect(music_checkbox_pressed)
	sounds_on_checkbox.toggled.connect(sfx_checkbox_pressed)
	ui_on_checkbox.toggled.connect(ui_checkbox_pressed)

	left_device.pressed.connect(change_device.bind(false))
	right_device.pressed.connect(change_device.bind(true))


func music_checkbox_pressed(toggle_on: bool) -> void:
	set_bus_enabled("Music", toggle_on)


func sfx_checkbox_pressed(toggle_on: bool) -> void:
	set_bus_enabled("Sfx", toggle_on)


func ui_checkbox_pressed(toggle_on: bool) -> void:
	set_bus_enabled("ui", toggle_on)


func set_bus_enabled(bus_name: String, enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	AudioServer.set_bus_mute(bus_index, not enabled)
	SettingsSaver.save_audio_bus_enabled(bus_name, enabled)

	if enabled:
		switch_sound_on.play_sound()
	else:
		switch_sound_off.play_sound()


func set_initial_states() -> void:
	music_on_checkbox.set_block_signals(true)
	sounds_on_checkbox.set_block_signals(true)
	ui_on_checkbox.set_block_signals(true)

	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("Sfx")
	var ui_bus := AudioServer.get_bus_index("ui")

	if music_bus != -1:
		music_on_checkbox.button_pressed = not AudioServer.is_bus_mute(music_bus)

	if sfx_bus != -1:
		sounds_on_checkbox.button_pressed = not AudioServer.is_bus_mute(sfx_bus)

	if ui_bus != -1:
		ui_on_checkbox.button_pressed = not AudioServer.is_bus_mute(ui_bus)

	music_on_checkbox.set_block_signals(false)
	sounds_on_checkbox.set_block_signals(false)
	ui_on_checkbox.set_block_signals(false)


func change_device(goes_forward: bool) -> void:
	if devices.is_empty():
		return

	var current_device := AudioServer.get_output_device()
	var current_index := devices.find(current_device)

	if current_index == -1:
		current_index = 0

	var next_index := current_index

	if goes_forward:
		next_index += 1

		if next_index >= devices.size():
			next_index = 0
	else:
		next_index -= 1

		if next_index < 0:
			next_index = devices.size() - 1

	AudioServer.set_output_device(devices[next_index])
	SettingsSaver.save_output_device(devices[next_index])

	update_device_text()
	switch_sound_on.play_sound()


func update_device_text() -> void:
	var current_device := AudioServer.get_output_device()

	if current_device.is_empty():
		current_device = "Default"

	device_selected_text.text = current_device

func refresh_menu_sliders() -> void:
	master_volume.refresh_from_saved_settings()
	music_volume.refresh_from_saved_settings()
	sfx_volume.refresh_from_saved_settings()
	ui_volume.refresh_from_saved_settings()
