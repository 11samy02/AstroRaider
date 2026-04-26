@tool
extends HBoxContainer
class_name MenuSlider

@export var icon: Texture
@export var text: String
var audio_bus: String = "Master"

@onready var texture_rect: TextureRect = $hbox/TextureRect
@onready var text_label: Label = $hbox/text_label
@onready var slider: HSlider = $slider
@onready var count: Label = $count
@onready var audio_2d: Audio2D = $Audio2D

func _ready() -> void:
	update_values()
	slider.value_changed.connect(_on_value_changed)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_values()

func _on_value_changed(value: float) -> void:
	count.text = str(roundi(value)) + "%"
	
	var bus_index := AudioServer.get_bus_index(audio_bus)
	
	var db := -80.0
	if value > 0:
		db = linear_to_db(value / 100.0)
	
	AudioServer.set_bus_volume_db(bus_index, db)
	
	audio_2d.play_sound()

func update_values() -> void:
	texture_rect.texture = icon
	text_label.text = text
	
	var bus_index := AudioServer.get_bus_index(audio_bus)
	var db := AudioServer.get_bus_volume_db(bus_index)
	
	var percent = clamp(db_to_linear(db) * 100.0, 0.0, 100.0)
	
	slider.set_value_no_signal(percent)
	count.text = str(roundi(percent)) + "%"


func _get_property_list() -> Array:
	var properties: Array = []
	
	var bus_names: Array[String] = []
	
	for i in AudioServer.get_bus_count():
		bus_names.append(AudioServer.get_bus_name(i))
	
	properties.append({
		"name": "audio_bus",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(bus_names),
	})
	
	return properties
