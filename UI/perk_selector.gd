extends CanvasLayer

var perk_buttons: Array[PerkButton] = []
var active_perk_button: PerkButton

const PERK_BUTTON = preload("res://UI/PerkSelector/perk_button.tscn")

@onready var perk_name: Label = %perk_name
@onready var description: Label = %description
@onready var perk_container: HBoxContainer = %Perk_container
@onready var assume: Button = $button_margin/TextureRect/MarginContainer/assume

var player_id = 0
var has_clicked := true
var active := false
var focus_set := false
var current_focus_index := -1  # Tracks the currently focused perk index

func _ready() -> void:
	active = false
	focus_set = false
	current_focus_index = -1
	add_buttons(3)
	call_deferred("_reset_focus_to_next_button")

func _process(delta: float) -> void:
	_check_perk_rarity()
	_clean_null_entries()

	if perk_buttons.is_empty():
		queue_free()

	# Ensure there are always 3 buttons (when available)
	if perk_buttons.size() < 3:
		add_buttons(3 - perk_buttons.size())

	check_pressed()

func change_description(perk: Perk) -> void:
	description.set_text(perk.get_description())
	perk_name.set_text(perk.perk_name)

# Add buttons and assign random perks to them
func add_buttons(count: int):
	for _i in range(count):
		if perk_buttons.size() >= 3:
			return  # Prevent creating too many buttons

		var perk_button = PERK_BUTTON.instantiate()
		perk_container.add_child(perk_button)

		# Load a random perk and validate
		perk_button.load_random_perk()

		if perk_button.key != null and is_instance_valid(perk_button) and perk_button.key != 0:
			perk_buttons.append(perk_button)
			connect_perk_button(perk_button)
			print("Perk Button Added: ", perk_button.perk.perk_name, " with key: ", perk_button.key)
		else:
			# Safely remove invalid buttons
			if perk_button.key == 0:
				print("Invalid Perk Key 0 detected, removing button")
			perk_button.queue_free()

	_clean_null_entries()
	_check_perk_rarity()
	call_deferred("_reset_focus_to_next_button")

# Connect signals to perk buttons
func connect_perk_button(perk_button):
	if not perk_button.is_connected("change_description", Callable(self, "change_description")):
		perk_button.connect("change_description", Callable(self, "change_description"))

	if not perk_button.is_connected("focus_entered", Callable(self, "_on_perk_button_focused")):
		perk_button.connect("focus_entered", Callable(self, "_on_perk_button_focused"))

	if not perk_button.is_connected("mouse_entered", Callable(self, "_on_perk_button_hovered")):
		perk_button.connect("mouse_entered", Callable(self, "_on_perk_button_hovered"))

	if not perk_button.is_connected("tree_exited", Callable(self, "_on_perk_button_removed")):
		perk_button.connect("tree_exited", Callable(self, "_on_perk_button_removed"))

# Handle when a perk button is focused (via keyboard/controller)
func _on_perk_button_focused():
	for perk_button in perk_buttons:
		if perk_button != null and is_instance_valid(perk_button) and perk_button.has_focus():
			active_perk_button = perk_button
			change_description(perk_button.perk)
			current_focus_index = perk_buttons.find(perk_button)  # Update focus index
			break

# Handle when a perk button is hovered over (via mouse)
func _on_perk_button_hovered():
	for perk_button in perk_buttons:
		if perk_button != null and is_instance_valid(perk_button) and perk_button.is_hovered():
			active_perk_button = perk_button
			change_description(perk_button.perk)
			break

# Clean up null or invalid entries to prevent referencing freed buttons
func _clean_null_entries():
	for i in range(perk_buttons.size() - 1, -1, -1):
		var perk_button = perk_buttons[i]
		if perk_button == null or !is_instance_valid(perk_button):
			if perk_button != null:
				perk_button.queue_free()
			perk_buttons.remove_at(i)

# Improved focus management when resetting focus
func _reset_focus_to_next_button():
	focus_set = false

	# Ensure focus is properly updated even with only 1 or 2 perks showing
	if perk_buttons.size() == 1:
		if active_perk_button != perk_buttons[0]:
			active_perk_button = perk_buttons[0]
			active_perk_button.grab_focus()
			focus_set = true
			change_description(active_perk_button.perk)

	elif perk_buttons.size() == 2:
		if current_focus_index == -1 or current_focus_index >= perk_buttons.size():
			current_focus_index = 0  # Default to first button if none selected
		active_perk_button = perk_buttons[current_focus_index]
		active_perk_button.grab_focus()
		focus_set = true
		change_description(active_perk_button.perk)

	else:
		for perk_button in perk_buttons:
			if perk_button != null and is_instance_valid(perk_button):
				perk_button.grab_focus()
				active_perk_button = perk_button
				active = true
				focus_set = true
				change_description(perk_button.perk)
				return

	if active_perk_button == null:
		perk_name.set_text("")
		description.set_text("No selection")

# Safely handle assumption of the perk
func assume_perk() -> void:
	if active_perk_button != null and is_instance_valid(active_perk_button):
		print("Assuming Perk: ", active_perk_button.perk.perk_name, " with key: ", active_perk_button.key)
	else:
		print("No active perk button found")
		return

	var player_Perks = GlobalGame.Players[player_id].player.stats.Perks
	if active_perk_button != null and is_instance_valid(active_perk_button):
		for perk in player_Perks:
			if perk.Key == active_perk_button.key:
				player_Perks.erase(perk)

		player_Perks.append(active_perk_button.perk)
		print("Selected Perk: ", active_perk_button.perk.perk_name)

		PerkButton.perk_in_use.clear()

	get_tree().paused = false
	queue_free()

func _check_perk_rarity():
	var player_Perks = GlobalGame.Players[player_id].player.stats.Perks

	for perk_button in perk_buttons:
		if perk_button != null and is_instance_valid(perk_button):
			var perk_found = false
			for perk in player_Perks:
				if perk.Key == perk_button.key:
					perk_found = true
					if perk.level < 6:
						perk_button.perk.level = perk.level + 1
					else:
						PerkButton.perk_in_use.append(perk.Key)
						perk_button.load_random_perk()
					break
			perk_button.set_image()
			perk_button.set_rarity()

func set_perk_button():
	for perk_button in perk_buttons:
		if perk_button != null and is_instance_valid(perk_button) and (perk_button.has_focus() or perk_button.is_hovered()):
			active_perk_button = perk_button
			change_description(perk_button.perk)
			return

	perk_name.set_text("")
	description.set_text("nothing selected")

func pause_game():
	get_tree().paused = true

func check_pressed():
	if active:
		if Input.is_joy_button_pressed(player_id, JOY_BUTTON_A):
			for perk_button in perk_buttons:
				if perk_button != null and is_instance_valid(perk_button) and perk_button.has_focus():
					perk_button._on_button_down()
					has_clicked = true
					return
			if not has_clicked and assume.has_focus():
				assume_perk()
		else:
			has_clicked = false

func _exit_tree() -> void:
	PauseMenu.can_pause_on_screen = true
	get_tree().paused = false
