extends Building
class_name CrystalGenerator



@onready var collect_crystal: AudioStreamPlayer2D = $Sounds/CollectCrystal
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interactionn_icon: Sprite2D = $interactionn_icon

var player_list : Array[Player] = []
const VISUEL_PATH = preload("res://scenes/tutorials/visual_feedback/visuel_path.tscn")
const COUNTER_PARTICLE = preload("res://scenes/tutorials/visual_feedback/visuel_counter.tscn")

func _enter_tree() -> void:
	GSignals.PLA_collects_crystal.connect(check_if_player_has_crstal)
	GlobalGame.Buildings.append(self)

func _ready() -> void:
	ensure_all_players_have_all_ores()
	GSignals.BUI_generator_is_placed.emit(self)
	call_deferred("check_if_player_has_crstal")

func ensure_all_players_have_all_ores() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		for ore_name in OreTemplate.Ores.keys():
			if not player_res.Ores.has(ore_name):
				player_res.Ores[ore_name] = 0

func _on_area_entered(area: Area2D) -> void:
	_try_collect_area(area)


func _try_collect_area(area: Area2D) -> void:
	if area is ItemCrystal:
		if not _can_collect_crystal(area):
			return
		if area.is_destroying:
			return

		for player_res: PlayerResource in GlobalGame.Players:
			if player_res.player == area.player_who_collected:
				player_res.crystal_count += area.value
				break
		var counter_part = COUNTER_PARTICLE.instantiate()
		get_parent().add_child(counter_part)
		counter_part.global_position = self.global_position
		counter_part.setup("+" + str(area.value) + "$", Color.GREEN, 1.5, randi_range(30, 50))
		area.destroy()
		collect_crystal.play_sound()

	if area is OreTemplate:
		if area.is_destroying:
			return

		for player_res : PlayerResource in GlobalGame.Players:
			if player_res.player == area.player_who_collected:
				var ore_name = area.Ores.keys()[area.ore_type]
				if player_res.Ores.has(ore_name):
					player_res.Ores[ore_name] += 1
				else:
					player_res.Ores.get_or_add(ore_name, 0)
					player_res.Ores[ore_name] += 1
		area.destroy()
		collect_crystal.play_sound()

func _on_check_player_nearby_body_entered(body: Node2D) -> void:
	if body is Player:
		player_list.append(body)

func _on_check_player_nearby_body_exited(body: Node2D) -> void:
	if body is Player:
		player_list.erase(body)

func _process(delta: float) -> void:
	super(delta)
	for area in get_overlapping_areas():
		if area is ItemCrystal or area is OreTemplate:
			_try_collect_area(area)


func _can_collect_crystal(crystal: ItemCrystal) -> bool:
	if not crystal.is_collected or not is_instance_valid(crystal.player_who_collected):
		return false

	if not GlobalGame.is_in_tutorial or GlobalGame.tutorial == 1:
		return true

	return GlobalGame.is_tutorial_action_allowed("deliver_crystal")

func check_if_player_has_crstal() -> void:
	call_deferred("_spawn_paths_for_crystal_carriers")


func _spawn_paths_for_crystal_carriers() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		var player := player_res.player
		if not is_instance_valid(player):
			continue

		player.clear_collected_null()
		var held_crystal_value := _get_held_crystal_value(player)

		if held_crystal_value <= 0:
			continue

		if _has_active_path_for_player(player):
			player_res.has_a_path = true
			if not player_res.has_shown_first_crystal_path:
				player_res.has_shown_first_crystal_path = true
			continue

		player_res.has_a_path = false

		if not _should_show_path_for_player(player_res, held_crystal_value):
			continue

		var visuel_path = VISUEL_PATH.instantiate()
		visuel_path.from_player = player
		visuel_path.to_obj = self
		get_parent().add_child(visuel_path)
		player_res.has_a_path = true
		player_res.has_shown_first_crystal_path = true


func _should_show_path_for_player(player_res: PlayerResource, held_crystal_value: int) -> bool:
	if not player_res.has_shown_first_crystal_path:
		return true

	return _has_enough_crystals_for_next_perk_select(player_res, held_crystal_value)


func _has_enough_crystals_for_next_perk_select(player_res: PlayerResource, held_crystal_value: int) -> bool:
	if held_crystal_value <= 0:
		return false

	if not is_instance_valid(player_res.player):
		return false

	var perk_manager := player_res.player.perk_manager
	if not is_instance_valid(perk_manager):
		return false

	if not is_instance_valid(perk_manager.selection):
		return false

	if not perk_manager.selection.has_any_selectable_perks():
		return false

	return player_res.crystal_count + held_crystal_value >= perk_manager.needed_coins


func _get_held_crystal_value(player: Player) -> int:
	var total := 0

	for crystal in player.collected_crystals:
		if is_instance_valid(crystal):
			total += crystal.value

	return total


func _has_active_path_for_player(player: Player) -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	for child in parent.get_children():
		if child is VisualPath and child.from_player == player:
			return true

	return false

func death():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.1,0.1), 0.3)
	await(tween.finished)
	queue_free()

func get_hit():
	GSignals.CAM_shake_effect.emit(randf_range(1.0, 4.0),1.5)
	animation_player.play("hit")
	await (animation_player.animation_finished)
