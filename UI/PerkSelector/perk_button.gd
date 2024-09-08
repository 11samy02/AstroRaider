extends TextureButton
class_name PerkButton

@export var key: PerkData.Keys

@onready var perk_image: TextureRect = %perk_image

@export var normal_textrues: Array[Texture2D]
@export var focus_textrues: Array[Texture2D]

var perk: Perk = Perk.new()

signal change_description
signal set_perk_button

static var perk_in_use: Array[PerkData.Keys] = []

func set_rarity() -> void:
	if perk.level <= normal_textrues.size() and perk.level <= focus_textrues.size():
		texture_normal = normal_textrues[perk.level - 1]
		texture_hover = focus_textrues[perk.level - 1]
		texture_focused = focus_textrues[perk.level - 1]
	else:
		if normal_textrues.size() > 0 and focus_textrues.size() > 0:
			texture_normal = normal_textrues[-1]
			texture_hover = focus_textrues[-1]
			texture_focused = focus_textrues[-1]

func send_change_description() -> void:
	change_description.emit(perk)

func load_random_perk() -> void:
	if PerkData.Keys.size() > 0 and perk_in_use.size() < PerkData.Keys.size():
		var available_keys = PerkData.Keys.values().filter(func(k):
			return !perk_in_use.has(k) and k != null
		)

		if available_keys.is_empty():
			queue_free()
			return

		key = available_keys.pick_random()

		if perk_in_use.has(key):
			print("Key is already in use: ", key)
			queue_free()
			return

		perk_in_use.append(key)
		var loaded_perk = PerkData.load_perk_res(key)

		if loaded_perk == null:
			perk_in_use.erase(key)
			queue_free()
			return

		perk = loaded_perk.duplicate()

		if perk.image == null:
			perk_in_use.erase(key)
			queue_free()
			return

		set_image()
		set_rarity()
	else:
		print("No valid perks available or all perks are already in use")
		queue_free()

func set_image() -> void:
	if perk_image != null and perk.image != null:
		perk_image.texture = perk.image

func _on_button_down() -> void:
	set_perk_button.emit()
