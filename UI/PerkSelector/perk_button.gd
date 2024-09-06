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
	# Only set the texture if both normal and focus textures are available and within bounds
	if perk.level <= normal_textrues.size() and perk.level <= focus_textrues.size():
		texture_normal = normal_textrues[perk.level - 1]
		texture_hover = focus_textrues[perk.level - 1]
		texture_focused = focus_textrues[perk.level - 1]
	else:
		# Safety fallback to avoid invalid texture assignment
		if normal_textrues.size() > 0 and focus_textrues.size() > 0:
			texture_normal = normal_textrues[-1]
			texture_hover = focus_textrues[-1]
			texture_focused = focus_textrues[-1]

func send_change_description() -> void:
	change_description.emit(perk)

func load_random_perk() -> void:
	# Check if there are valid Keys available and if any keys are left to use
	if PerkData.Keys.size() > 0 and perk_in_use.size() < PerkData.Keys.size():

		# Create a list of available Keys that are not in use and are valid
		var available_keys = PerkData.Keys.values().filter(func(k):
			return !perk_in_use.has(k) and k != null and k != 0  # Ensure no invalid Key (like 0) is used
		)

		# If no Keys are available, exit
		if available_keys.size() == 0:
			queue_free()  # Safely remove the button if no more keys are available
			return

		# Pick a random available Key
		key = available_keys.pick_random()

		# Load the perk based on the randomly chosen key
		perk_in_use.append(key)
		var loaded_perk = PerkData.load_perk_res(key)

		# Check if the perk was loaded successfully
		if loaded_perk == null:
			perk_in_use.erase(key)  # Remove the key from usage if loading failed
			queue_free()
			return

		perk = loaded_perk.duplicate()

		# Check if the perk has a valid image before setting it
		if perk.image == null:
			perk_in_use.erase(key)  # Remove the key from usage if the image is invalid
			queue_free()
			return

		set_image()
		set_rarity()
	else:
		# Exit safely if no valid perks are available
		queue_free()

func set_image() -> void:
	# Ensure both perk_image and perk.image are valid before assigning
	if perk_image != null and perk.image != null:
		perk_image.texture = perk.image

func _on_button_down() -> void:
	set_perk_button.emit()
