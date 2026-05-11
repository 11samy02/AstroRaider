@tool
extends HBoxContainer
class_name MenuSlider

@export var icon: Texture
@export var text: String
@export_enum("Master", "Music", "Sfx", "ui") var audio_bus: String = "Master"

@onready var texture_rect: TextureRect = $hbox/TextureRect
@onready var text_label: Label = $hbox/text_label
@onready var slider: HSlider = $slider
@onready var count: Label = $count
@onready var audio_2d: Audio2D = $Audio2D


func _ready() -> void:
	update_visuals()
	setup_slider()

	if Engine.is_editor_hint():
		update_from_current_bus()
		return

	if not slider.value_changed.is_connected(_on_value_changed):
		slider.value_changed.connect(_on_value_changed)

	call_deferred("refresh_from_saved_settings")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_visuals()
		update_from_current_bus()


func setup_slider() -> void:
	if not is_instance_valid(slider):
		return

	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0


func refresh_from_saved_settings() -> void:
	if Engine.is_editor_hint():
		return

	if not is_instance_valid(slider):
		return

	if not is_instance_valid(count):
		return

	var saved_percent := SettingsSaver.get_audio_bus_volume_percent(audio_bus, 100.0)
	saved_percent = clamp(saved_percent, 0.0, 100.0)

	slider.set_value_no_signal(saved_percent)
	count.text = str(roundi(saved_percent)) + "%"

	apply_volume(saved_percent)


func _on_value_changed(value: float) -> void:
	value = clamp(value, 0.0, 100.0)

	apply_volume(value)
	SettingsSaver.save_audio_bus_volume_percent(audio_bus, value)

	count.text = str(roundi(value)) + "%"

	if is_instance_valid(audio_2d):
		audio_2d.play_sound()


func apply_volume(value: float) -> void:
	var bus_index := AudioServer.get_bus_index(audio_bus)

	if bus_index == -1:
		push_warning("Audio bus not found: " + audio_bus)
		return

	value = clamp(value, 0.0, 100.0)

	var db := -80.0

	if value > 0.0:
		db = linear_to_db(value / 100.0)

	AudioServer.set_bus_volume_db(bus_index, db)


func update_visuals() -> void:
	if is_instance_valid(texture_rect):
		texture_rect.texture = icon

	if is_instance_valid(text_label):
		text_label.text = text


func update_from_current_bus() -> void:
	if not is_instance_valid(slider):
		return

	if not is_instance_valid(count):
		return

	setup_slider()

	var bus_index := AudioServer.get_bus_index(audio_bus)

	if bus_index == -1:
		return

	var db := AudioServer.get_bus_volume_db(bus_index)
	var percent = clamp(db_to_linear(db) * 100.0, 0.0, 100.0)

	slider.set_value_no_signal(percent)
	count.text = str(roundi(percent)) + "%"
