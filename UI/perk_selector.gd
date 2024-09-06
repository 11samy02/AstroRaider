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

func _ready() -> void:
	active = false
	focus_set = false
	add_buttons(3)  # Füge die ersten 3 Buttons hinzu
	call_deferred("_reset_focus_to_next_button")  # Setze den Fokus auf den ersten Button nach der Initialisierung

func _process(delta: float) -> void:
	_check_perk_rarity()
	_clean_null_entries()
	if perk_buttons.size() <= 0:
		queue_free()

	# Sicherstellen, dass immer 3 Buttons vorhanden sind
	if perk_buttons.size() < 3:
		add_buttons(3 - perk_buttons.size())

	if perk_buttons.is_empty():
		get_tree().paused = false
		PauseMenu.can_pause_on_screen = true
		queue_free()

	check_pressed()

func change_description(perk: Perk) -> void:
	description.set_text(perk.get_description())
	perk_name.set_text(perk.perk_name)

# Funktion, um Buttons hinzuzufügen und die Perks zufällig zuzuweisen
func add_buttons(count: int):
	if count <= 0:
		return

	for i in range(0, count):
		# Throttle the creation to avoid overloading
		if perk_buttons.size() >= 3:
			return  # Prevent creating too many buttons

		var perk_button = PERK_BUTTON.instantiate()
		perk_container.add_child(perk_button)

		# Load a random perk and validate
		perk_button.load_random_perk()

		# Ensure the button was successfully created and has a valid key
		if perk_button.key != null and is_instance_valid(perk_button):
			perk_buttons.append(perk_button)
			connect_perk_button(perk_button)
		else:
			perk_button.queue_free()  # Free invalid buttons
	
	_clean_null_entries()
	_check_perk_rarity()
	_reset_focus_to_next_button()
	assume.grab_focus()

# Helper function to connect signals only if not already connected
func connect_perk_button(perk_button):
	var node = perk_button
	
	if not node.is_connected("change_description", Callable(self, "change_description")):
		node.connect("change_description", Callable(self, "change_description"))
	
	if not node.is_connected("set_perk_button", Callable(self, "set_perk_button")):
		node.connect("set_perk_button", Callable(self, "set_perk_button"))
	
	if not node.is_connected("tree_exited", Callable(self, "_on_perk_button_removed")):
		node.connect("tree_exited", Callable(self, "_on_perk_button_removed"))
	

func _clean_null_entries():
	# Remove and free invalid or unused perk buttons
	for i in range(perk_buttons.size() - 1, -1, -1):
		var perk_button = perk_buttons[i]
		if perk_button == null or !is_instance_valid(perk_button):
			if perk_button != null:
				perk_button.queue_free()
			perk_buttons.remove_at(i)

# Funktion, um die Seltenheit für alle Buttons zu setzen
func set_rarity_for_all_buttons():
	for perk_button in perk_buttons:
		perk_button.set_rarity()
		perk_button.set_image()

func _on_perk_button_removed():
	_clean_null_entries()
	call_deferred("_reset_focus_to_next_button")

func _reset_focus_to_next_button():
	if focus_set:
		return
	
	# Setze den Fokus nur, wenn gültige Buttons vorhanden sind
	if perk_buttons.size() > 0:
		for perk_button in perk_buttons:
			if perk_button != null:
				perk_button.grab_focus()
				active_perk_button = perk_button
				active = true
				focus_set = true
				change_description(perk_button.perk)
				return
	else:
		active_perk_button = null
		perk_name.set_text("")
		description.set_text("Keine Auswahl")

	# Sicherheitsprüfung für den Assume-Button
	if active_perk_button == null and perk_buttons.size() > 0:
		perk_buttons[0].grab_focus()
	else:
		assume.grab_focus() if active_perk_button == null else null

func assume_perk() -> void:
	get_tree().paused = false

	# Sicherheitsprüfung, ob der aktive PerkButton gültig ist
	if active_perk_button != null and is_instance_valid(active_perk_button):
		var player_Perks = GlobalGame.Players[player_id].player.stats.Perks
		for perk in player_Perks:
			if perk.Key == active_perk_button.key:
				player_Perks.erase(perk)
		
		player_Perks.append(active_perk_button.perk)
		GSignals.PERK_reset_perks_from_player_id.emit(player_id)
	
	PerkButton.perk_in_use.clear()
	
	queue_free()

func _check_perk_rarity():
	var player_Perks = GlobalGame.Players[player_id].player.stats.Perks
	
	# Überprüfe für jeden Button den Spieler-Perk-Level
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
			
			# Setze Seltenheit und Bild, auch wenn der Perk nicht im Spieler-Set war
			perk_button.set_image()
			perk_button.set_rarity()

func set_perk_button():
	for perk_button in perk_buttons:
		if perk_button != null and perk_button.has_focus():
			active_perk_button = perk_button
			assume.grab_focus()
			change_description(perk_button.perk)
			return

	perk_name.set_text("")
	description.set_text("nothing selectod")

func pause_game():
	get_tree().paused = true

func check_pressed():
	if active:
		if Input.is_joy_button_pressed(player_id, JOY_BUTTON_A):
			for perk_button in perk_buttons:
				if perk_button != null and perk_button.has_focus():
					perk_button._on_button_down()
					has_clicked = true
					return
			if !has_clicked:
				if assume.has_focus():
					assume_perk()
		else:
			has_clicked = false

func _exit_tree() -> void:
	PauseMenu.can_pause_on_screen = true
	get_tree().paused = false
