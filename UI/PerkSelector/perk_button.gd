extends TextureButton

@export var key: PerkData.Keys

@onready var perk_image: TextureRect = $MarginContainer/perk_image

signal change_description

func _ready() -> void:
	perk_image.texture = PerkData.load_perk_res(key).image
	

func _set_image() -> void:
	perk_image.texture = PerkData.load_perk_res(key).image


func send_change_description() -> void:
	change_description.emit(PerkData.load_perk_res(key))
