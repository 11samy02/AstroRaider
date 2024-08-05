extends TextureButton
class_name PerkButton

@export var key: PerkData.Keys

@onready var perk_image: TextureRect = %perk_image

@export var normal_textrues : Array[Texture2D]
@export var focus_textrues : Array[Texture2D]

var perk: Perk = Perk.new()

signal change_description
signal set_perk_button

static var perk_in_use: Array[PerkData.Keys]

func set_image() -> void:
	perk_image.texture = perk.image


func send_change_description() -> void:
	change_description.emit(perk)

func set_rarity() -> void:
	if perk.level <= normal_textrues.size():
		texture_normal = normal_textrues[perk.level - 1]
		texture_hover = focus_textrues[perk.level - 1]
		texture_focused = focus_textrues[perk.level - 1]
	else:
		texture_normal = normal_textrues[-1]
	

func load_random_perk() -> void:
	if perk_in_use.size() <= PerkData.Keys.size():
		while perk_in_use.has(key):
			key = PerkData.Keys.values().pick_random()
		perk_in_use.append(key)
		perk = PerkData.load_perk_res(key).duplicate()
		perk_image.texture = perk.image
		set_image()
		set_rarity()
	else:
		queue_free()

static func reset_perks_in_use() -> void:
	perk_in_use.clear()


func _on_button_down() -> void:
	set_perk_button.emit()
