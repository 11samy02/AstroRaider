extends CanvasLayer

var perk_buttons: Array[PerkButton] = []

var active_perk_button: PerkButton

const PERK_BUTTON = preload("res://UI/PerkSelector/perk_button.tscn")

@onready var label: Label = %Label
@onready var perk_container: HBoxContainer = %Perk_container
@onready var assume: Button = $button_margin/TextureRect/MarginContainer/assume

var player_id = 0

func _ready() -> void:
	add_buttons(3)

func _process(delta: float) -> void:
	_check_perk_rarity()
	_clean_null_entries()
	check_pressed()
	
	if perk_buttons.is_empty():
		get_tree().paused = false
		PauseMenu.can_pause_on_screen = true
		queue_free()

func change_description(perk: Perk) -> void:
	label.set_text(perk.get_description())

func add_buttons(count: int):
	for i in range(0, count):
		var perk_button = PERK_BUTTON.instantiate()
		perk_container.add_child(perk_button)
		perk_button.load_random_perk()
		perk_buttons.append(perk_button)
		perk_button.connect("change_description", change_description)
		perk_button.connect("set_perk_button", set_perk_button)
		perk_button.connect("tree_exited", _on_perk_button_removed)
	
	if !perk_buttons.is_empty():
		perk_buttons[0].grab_focus()
		active_perk_button = perk_buttons[0]

func _on_perk_button_removed():
	_clean_null_entries()

func _clean_null_entries():
	# Filtere das Array, um null-Werte zu entfernen
	perk_buttons = perk_buttons.filter(func(perk_button):
		return perk_button != null and is_instance_valid(perk_button)
	)

func assume_perk() -> void:
	get_tree().paused = false
	PerkButton.reset_perks_in_use()
	for perk_button in perk_buttons:
		if perk_button != null and active_perk_button == perk_button:
			var player_Perks = GlobalGame.Players[player_id].player.stats.Perks
			for perk in player_Perks:
				if perk.Key == perk_button.key:
					player_Perks.erase(perk)
				
			player_Perks.append(perk_button.perk)
			GSignals.PERK_reset_perks_from_player_id.emit(player_id)
			break
	queue_free()

func _check_perk_rarity():
	var player_Perks = GlobalGame.Players[player_id].player.stats.Perks
	
	for perk_button in perk_buttons:
		if perk_button != null:
			for perk in player_Perks:
				if perk.Key == perk_button.key:
					if perk.level < 6:
						perk_button.perk.level = perk.level + 1
						break
					else:
						PerkButton.perk_in_use.append(perk.Key)
						perk_button.load_random_perk()
						break
			
			perk_button.set_rarity()
			perk_button.set_image()

func set_perk_button():
	for perk_button in perk_buttons:
		if perk_button != null and perk_button.has_focus():
			active_perk_button = perk_button
			assume.grab_focus()
			break

func pause_game():
	get_tree().paused = true
	

var has_clicked := false

func check_pressed():
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
