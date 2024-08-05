extends Node

@export var start_amount := 10
@export var amount_added_per_perk := 20

const PERK_SELECTOR = preload("res://UI/perk_selector.tscn")

func _ready() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		player_res.crystals_needed = start_amount

func _process(delta: float) -> void:
	check_crystals()


func check_crystals() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		if player_res.crystal_count >= player_res.crystals_needed:
			player_res.crystal_count -= player_res.crystals_needed
			player_res.crystals_needed += amount_added_per_perk
			
			var perk_selector = PERK_SELECTOR.instantiate()
			
			perk_selector.player_id = player_res.player.player_id
			
			add_child(perk_selector)
