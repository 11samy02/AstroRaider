extends Node

@export var start_amount := 5
@export var amount_added_per_perk := 10

const PERK_SELECTOR = preload("res://UI/perk_selector.tscn")

func set_player_Stats() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		player_res.crystals_needed = start_amount

func _process(delta: float) -> void:
	check_crystals()

func check_crystals() -> void:
	if GlobalGame.Players.is_empty():
		return
	
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.crystal_count >= player_res.crystals_needed:
			var has_all_perks_on_max_level := false
			var all_perks :Array[Perk] = player_res.player.stats.Perks
			if all_perks.size() < PerkData.Keys.size():
				has_all_perks_on_max_level = false
			else:
				var level_count_perks : Array[int] = []
				for perk:Perk in all_perks:
					level_count_perks.append(perk.level)
				
				for level in level_count_perks:
					if level != 6:
						has_all_perks_on_max_level = true
						break
			# Sicherstellen, dass keine andere Instanz bereits geladen ist
			if get_child_count() == 0 and !has_all_perks_on_max_level:
				PerkButton.perk_in_use.clear()
				player_res.crystal_count -= player_res.crystals_needed
				player_res.crystals_needed += amount_added_per_perk
				
				# Erstelle eine neue Instanz des PerkSelectors
				var perk_selector = PERK_SELECTOR.instantiate()
				
				# Setze die player_id für den jeweiligen Spieler
				perk_selector.player_id = player_res.player.player_id
				
				# Füge den PerkSelector als Kind zu der Szene hinzu
				add_child(perk_selector)
				print("PERK SELECTOR")
				# Initialisiere und setze den Fokus auf den ersten PerkButton nach dem Hinzufügen
				call_deferred("_initialize_and_focus_perk_selector", perk_selector)


# Funktion, um sicherzustellen, dass der PerkSelector korrekt initialisiert wird
func _initialize_and_focus_perk_selector(perk_selector):
	# Hier wird sichergestellt, dass der PerkSelector vollständig initialisiert ist
	perk_selector._reset_focus_to_next_button()

	# Falls der PerkSelector geschlossen oder bestätigt wird, entferne ihn korrekt
	perk_selector.connect("tree_exited", _on_perk_selector_closed)

func _on_perk_selector_closed():
	# Stelle sicher, dass alle alten Instanzen vollständig entfernt werden
	if has_node("PERK_SELECTOR"):
		$PERK_SELECTOR.queue_free()
