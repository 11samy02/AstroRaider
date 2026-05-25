extends Node

enum TutorialStep {
	NONE,
	MOVEMENT,
	MINING,
	SHOOTING,
	GENERATOR,
	EXIT_BUILD_MODE,
	DELIVER_CRYSTAL,
	OPEN_BUILD_MODE,
	PLACE_BUILDING,
	SALVAGE_BUILDING,
	COMPLETE,
}

const ITEM_CRYSTAL := preload("res://scenes/collectables/crystal.tscn")
const DEFAULT_OBJECTIVE_SCENE := preload("res://scenes/tutorials/tutorial_objective.tscn")
const BUILD_ORE_AMOUNT := 8
const TUTORIAL_TASKS := {
	TutorialStep.MOVEMENT: preload("res://resources/Task/Tutorial/movement.tres"),
	TutorialStep.GENERATOR: preload("res://resources/Task/Tutorial/generator.tres"),
	TutorialStep.EXIT_BUILD_MODE: preload("res://resources/Task/Tutorial/exit_build_mode.tres"),
	TutorialStep.MINING: preload("res://resources/Task/Tutorial/mining.tres"),
	TutorialStep.DELIVER_CRYSTAL: preload("res://resources/Task/Tutorial/deliver_crystal.tres"),
	TutorialStep.SHOOTING: preload("res://resources/Task/Tutorial/shooting.tres"),
	TutorialStep.OPEN_BUILD_MODE: preload("res://resources/Task/Tutorial/open_build_mode.tres"),
	TutorialStep.PLACE_BUILDING: preload("res://resources/Task/Tutorial/place_building.tres"),
	TutorialStep.SALVAGE_BUILDING: preload("res://resources/Task/Tutorial/salvage_building.tres"),
	TutorialStep.COMPLETE: preload("res://resources/Task/Tutorial/complete.tres"),
}

const TIMELINE_WAKE := "Waking UP"
const TIMELINE_MINING := "Tutorial Mining"
const TIMELINE_SHOOTING := "Shooting Tutorial"
const TIMELINE_GENERATOR := "Tutorial Generator"
const TIMELINE_EXIT_BUILD := "Tutorial Exit Build Mode"
const TIMELINE_DELIVER := "Tutorial Deliver Crystal"
const TIMELINE_BUILDING := "Tutorial Building"
const TIMELINE_PLACE := "Tutorial Place Building"
const TIMELINE_SALVAGE := "Tutorial Salvage Building"
const TIMELINE_COMPLETE := "Tutorial Complete"
const MOVEMENT_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right"]
const TUTORIAL_BAT_KILLS_REQUIRED := 3
const ACTION_MOVEMENT := "movement"
const ACTION_MINING := "mining"
const ACTION_SHOOTING := "shooting"
const ACTION_BUILD_MODE := "build_mode"
const ACTION_BUILD_CURSOR := "build_cursor"
const ACTION_SELECT_GENERATOR := "select_generator"
const ACTION_PLACE_GENERATOR := "place_generator"
const ACTION_COLLECT_CRYSTAL := "collect_crystal"
const ACTION_DELIVER_CRYSTAL := "deliver_crystal"
const ACTION_SELECT_BUILDING := "select_building"
const ACTION_PLACE_BUILDING := "place_building"
const ACTION_SALVAGE_BUILDING := "salvage_building"

@export var enviroment: Enviroment
@export var key_labels: Array[Label]
@export var wasd_tutorial: CanvasLayer
@export var objective_scene: PackedScene = DEFAULT_OBJECTIVE_SCENE

var player_res: PlayerResource
var player: Player
var current_step := TutorialStep.NONE
var step_active := false
var tutorial_active := false

var movement_done: Dictionary = {}
var mined_tiles := 0
var tutorial_bats_killed := 0
var delivered_crystals_at_step_start := 0
var generator: CrystalGenerator = null
var tutorial_crystal: ItemCrystal = null
var spawned_tutorial_enemies: Array[EnemyBaseTemplate] = []
var placed_tutorial_building := false
var salvaged_tutorial_building := false
var spawn_tutorial_crystal_when_dialog_closes := false

var objective_ui: ObjectiveTaskUI
var timeline_request_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _can_run_tutorial():
		GlobalGame.is_in_tutorial = false
		queue_free()
		return

	tutorial_active = true
	GlobalGame.clear_tutorial_allowed_actions()
	_create_objective_ui()
	_hide_old_key_prompt()
	_connect_signals()

	if is_instance_valid(enviroment):
		if not enviroment.map_was_created.is_connected(_on_map_was_created):
			enviroment.map_was_created.connect(_on_map_was_created)
		if enviroment.finished_map:
			call_deferred("_on_map_was_created")
	else:
		call_deferred("_start_when_player_is_ready")


func _exit_tree() -> void:
	timeline_request_id += 1
	_disconnect_signals()


func _process(_delta: float) -> void:
	if tutorial_active and not _can_run_tutorial():
		_stop_tutorial_without_completion()
		return

	if Dialogic.current_timeline != null:
		return

	if not tutorial_active or not step_active:
		return

	if is_instance_valid(objective_ui) and not objective_ui.is_objective_visible():
		_show_objective(current_step)

	if not is_instance_valid(player) or not is_instance_valid(player_res):
		_resolve_player()
		if not is_instance_valid(player):
			return

	match current_step:
		TutorialStep.MOVEMENT:
			_update_movement_step()
		TutorialStep.MINING:
			_update_mining_step()
		TutorialStep.SHOOTING:
			_update_shooting_step()
		TutorialStep.GENERATOR:
			_update_generator_step()
		TutorialStep.EXIT_BUILD_MODE:
			_update_exit_build_mode_step()
		TutorialStep.DELIVER_CRYSTAL:
			_update_deliver_crystal_step()
		TutorialStep.OPEN_BUILD_MODE:
			_update_open_build_mode_step()
		TutorialStep.PLACE_BUILDING:
			_update_place_building_step()
		TutorialStep.SALVAGE_BUILDING:
			_update_salvage_building_step()


func _connect_signals() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not GSignals.TUT_tiles_destroyed.is_connected(_on_tiles_destroyed):
		GSignals.TUT_tiles_destroyed.connect(_on_tiles_destroyed)
	if not GSignals.ENE_killed_by.is_connected(_on_enemy_killed):
		GSignals.ENE_killed_by.connect(_on_enemy_killed)
	if not GSignals.BUI_generator_is_placed.is_connected(_on_generator_placed):
		GSignals.BUI_generator_is_placed.connect(_on_generator_placed)
	if not GSignals.TUT_building_placed.is_connected(_on_building_placed):
		GSignals.TUT_building_placed.connect(_on_building_placed)
	if not GSignals.TUT_building_salvaged.is_connected(_on_building_salvaged):
		GSignals.TUT_building_salvaged.connect(_on_building_salvaged)


func _disconnect_signals() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if GSignals.TUT_tiles_destroyed.is_connected(_on_tiles_destroyed):
		GSignals.TUT_tiles_destroyed.disconnect(_on_tiles_destroyed)
	if GSignals.ENE_killed_by.is_connected(_on_enemy_killed):
		GSignals.ENE_killed_by.disconnect(_on_enemy_killed)
	if GSignals.BUI_generator_is_placed.is_connected(_on_generator_placed):
		GSignals.BUI_generator_is_placed.disconnect(_on_generator_placed)
	if GSignals.TUT_building_placed.is_connected(_on_building_placed):
		GSignals.TUT_building_placed.disconnect(_on_building_placed)
	if GSignals.TUT_building_salvaged.is_connected(_on_building_salvaged):
		GSignals.TUT_building_salvaged.disconnect(_on_building_salvaged)


func _on_map_was_created() -> void:
	call_deferred("_start_when_player_is_ready")


func _start_when_player_is_ready() -> void:
	for _i in range(180):
		if not _can_run_tutorial():
			_stop_tutorial_without_completion()
			return

		_resolve_player()
		if is_instance_valid(player) and is_instance_valid(player_res):
			_play_timeline(TIMELINE_WAKE)
			return
		await get_tree().process_frame

	push_warning("TutorialManager: No player was found for the tutorial.")
	queue_free()


func _resolve_player() -> void:
	for res: PlayerResource in GlobalGame.Players:
		if is_instance_valid(res.player):
			player_res = res
			player = res.player
			return


func _play_timeline(timeline_name: String) -> void:
	if not _can_run_tutorial():
		_stop_tutorial_without_completion()
		return

	step_active = false
	current_step = TutorialStep.NONE
	GlobalGame.clear_tutorial_allowed_actions()
	_hide_objective()

	timeline_request_id += 1
	call_deferred("_start_timeline_when_dialogic_is_idle", timeline_name, timeline_request_id)


func _start_timeline_when_dialogic_is_idle(timeline_name: String, request_id: int) -> void:
	while Dialogic.current_timeline != null:
		await Dialogic.timeline_ended
		await get_tree().process_frame
		if request_id != timeline_request_id or not tutorial_active or not _can_run_tutorial():
			return

	if request_id != timeline_request_id or not tutorial_active or not _can_run_tutorial():
		return

	Dialogic.start(timeline_name)


func _on_dialogic_signal(argument: Variant) -> void:
	if not _can_run_tutorial():
		return

	var signal_name := str(argument)

	match signal_name:
		"wait_for_wasd_input", "wait_for_movement":
			_begin_step(TutorialStep.MOVEMENT)
		"wait_for_mining":
			mined_tiles = 0
			_begin_step(TutorialStep.MINING)
		"spawn_tutorial_enemies":
			_spawn_tutorial_enemies()
		"wait_for_shooting":
			tutorial_bats_killed = 0
			_begin_step(TutorialStep.SHOOTING)
		"wait_for_generator":
			_begin_step(TutorialStep.GENERATOR)
		"wait_for_exit_build_mode":
			_begin_step(TutorialStep.EXIT_BUILD_MODE)
		"spawn_tutorial_crystal":
			spawn_tutorial_crystal_when_dialog_closes = true
		"wait_for_crystal_deliver":
			delivered_crystals_at_step_start = player_res.crystal_count if is_instance_valid(player_res) else 0
			_begin_step(TutorialStep.DELIVER_CRYSTAL)
		"grant_tutorial_resources":
			_grant_tutorial_build_resources()
		"wait_for_build_mode":
			_begin_step(TutorialStep.OPEN_BUILD_MODE)
		"wait_for_place_building":
			placed_tutorial_building = false
			_begin_step(TutorialStep.PLACE_BUILDING)
		"wait_for_salvage_building":
			salvaged_tutorial_building = false
			_begin_step(TutorialStep.SALVAGE_BUILDING)
		"finish_tutorial":
			call_deferred("_finish_tutorial")


func _begin_step(step: int) -> void:
	current_step = step
	step_active = true
	GlobalGame.set_tutorial_allowed_actions(_get_allowed_actions_for_step(step))
	if Dialogic.current_timeline == null:
		_show_objective(step)
	else:
		_hide_objective()

	if step == TutorialStep.MOVEMENT:
		for action in MOVEMENT_ACTIONS:
			movement_done[action] = false


func _update_movement_step() -> void:
	for action in MOVEMENT_ACTIONS:
		if Input.is_action_pressed(action):
			movement_done[action] = true

	for action in MOVEMENT_ACTIONS:
		if not movement_done.get(action, false):
			return

	_play_timeline(TIMELINE_GENERATOR)


func _update_mining_step() -> void:
	if not is_instance_valid(player):
		return

	if spawn_tutorial_crystal_when_dialog_closes:
		_spawn_tutorial_crystal()
		spawn_tutorial_crystal_when_dialog_closes = false

	player.clear_collected_null()
	if mined_tiles >= 1 and not player.collected_crystals.is_empty():
		_play_timeline(TIMELINE_DELIVER)


func _update_shooting_step() -> void:
	if tutorial_bats_killed >= TUTORIAL_BAT_KILLS_REQUIRED:
		_clear_tutorial_enemies()
		_play_timeline(TIMELINE_BUILDING)


func _update_generator_step() -> void:
	if is_instance_valid(generator):
		_play_timeline(TIMELINE_EXIT_BUILD)


func _update_exit_build_mode_step() -> void:
	if is_instance_valid(player) and player.current_state == player.states.Default:
		_play_timeline(TIMELINE_MINING)


func _update_deliver_crystal_step() -> void:
	if not is_instance_valid(player_res):
		return

	if player_res.crystal_count > delivered_crystals_at_step_start:
		_play_timeline(TIMELINE_SHOOTING)


func _update_open_build_mode_step() -> void:
	if is_instance_valid(player) and player.current_state == player.states.Build:
		_play_timeline(TIMELINE_PLACE)


func _update_place_building_step() -> void:
	if placed_tutorial_building:
		_play_timeline(TIMELINE_SALVAGE)


func _update_salvage_building_step() -> void:
	if salvaged_tutorial_building:
		_play_timeline(TIMELINE_COMPLETE)


func _on_tiles_destroyed(count: int) -> void:
	if current_step == TutorialStep.MINING:
		mined_tiles += count


func _on_enemy_killed(killed_by: CharacterBody2D) -> void:
	if current_step != TutorialStep.SHOOTING:
		return
	if killed_by != player:
		return

	tutorial_bats_killed = min(tutorial_bats_killed + 1, TUTORIAL_BAT_KILLS_REQUIRED)
	_show_objective(TutorialStep.SHOOTING)


func _on_generator_placed(new_generator: CrystalGenerator) -> void:
	generator = new_generator


func _on_building_placed(placed_player: Player, _building: Building, blueprint_key) -> void:
	if placed_player != player:
		return
	if current_step != TutorialStep.PLACE_BUILDING:
		return
	if blueprint_key == BluePrintData.Keys.Generator:
		return
	placed_tutorial_building = true


func _on_building_salvaged(salvage_player: Player, blueprint_key) -> void:
	if salvage_player != player:
		return
	if current_step != TutorialStep.SALVAGE_BUILDING:
		return
	if blueprint_key == BluePrintData.Keys.Generator:
		return
	salvaged_tutorial_building = true


func _spawn_tutorial_crystal() -> void:
	if not is_instance_valid(player):
		return

	player.clear_collected_null()
	if not player.collected_crystals.is_empty():
		return

	if is_instance_valid(tutorial_crystal):
		if not tutorial_crystal.is_collected:
			tutorial_crystal.global_position = _get_tutorial_crystal_spawn_position()
		return

	tutorial_crystal = ITEM_CRYSTAL.instantiate() as ItemCrystal
	if not is_instance_valid(tutorial_crystal):
		return

	tutorial_crystal.value = 5
	tutorial_crystal.global_position = _get_tutorial_crystal_spawn_position()
	_get_world_root().add_child(tutorial_crystal)


func _get_tutorial_crystal_spawn_position() -> Vector2:
	var away_from_gravity := -player.gravity_dir
	if away_from_gravity == Vector2.ZERO:
		away_from_gravity = Vector2.RIGHT

	var side := away_from_gravity.orthogonal()
	return player.global_position + away_from_gravity * 96.0 + side * 32.0


func _spawn_tutorial_enemies() -> void:
	if not spawned_tutorial_enemies.is_empty():
		return

	var spawner := _get_entity_spawner()
	if not is_instance_valid(spawner):
		return

	spawner.wave_spawn_count = TUTORIAL_BAT_KILLS_REQUIRED
	for _i in TUTORIAL_BAT_KILLS_REQUIRED:
		var enemy := spawner.spawn_enemy(false)
		if not is_instance_valid(enemy):
			continue
		enemy.level = 0
		spawned_tutorial_enemies.append(enemy)


func _clear_tutorial_enemies() -> void:
	for enemy in spawned_tutorial_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_tutorial_enemies.clear()


func _get_entity_spawner() -> EntitySpawner:
	var main_game := get_parent()
	if main_game == null:
		return null

	return main_game.get("entity_spawner") as EntitySpawner


func _grant_tutorial_build_resources() -> void:
	if not is_instance_valid(player_res):
		return

	for ore_name in OreTemplate.Ores.keys():
		var current_amount := 0
		if player_res.Ores.has(ore_name):
			current_amount = player_res.Ores[ore_name]
		player_res.Ores[ore_name] = max(current_amount, BUILD_ORE_AMOUNT)


func _finish_tutorial() -> void:
	tutorial_active = false
	step_active = false
	timeline_request_id += 1
	GlobalGame.tutorial = 1
	GlobalGame.is_in_tutorial = false
	GlobalGame.clear_tutorial_allowed_actions()
	_hide_objective()
	_hide_old_key_prompt()
	_clear_tutorial_enemies()

	if is_instance_valid(player):
		player.current_state = player.states.Default
		var building_ui := player.get_node_or_null("Ui/Building UI")
		if building_ui is CanvasItem:
			building_ui.hide()

	var main_game := get_parent()
	if main_game != null:
		var spawner := main_game.get("entity_spawner") as EntitySpawner
		if is_instance_valid(spawner):
			spawner.reset()
			spawner.start_wave()

	queue_free()


func _stop_tutorial_without_completion() -> void:
	tutorial_active = false
	step_active = false
	timeline_request_id += 1
	GlobalGame.clear_tutorial_allowed_actions()
	_hide_objective()
	_hide_old_key_prompt()
	_clear_tutorial_enemies()
	queue_free()


func _can_run_tutorial() -> bool:
	return GlobalGame.is_in_tutorial and GlobalGame.tutorial != 1


func _get_world_root() -> Node:
	var main_game := get_parent()
	if is_instance_valid(main_game):
		return main_game
	return get_tree().current_scene


func _get_task_for_step(step: int) -> TaskResource:
	return TUTORIAL_TASKS.get(step, null) as TaskResource


func _get_task_values_for_step(step: int) -> Dictionary:
	match step:
		TutorialStep.SHOOTING:
			return {
				"current": tutorial_bats_killed,
				"target": TUTORIAL_BAT_KILLS_REQUIRED,
			}
	return {}


func _get_allowed_actions_for_step(step: int) -> Array[String]:
	match step:
		TutorialStep.MOVEMENT:
			return [ACTION_MOVEMENT]
		TutorialStep.GENERATOR:
			return [
				ACTION_BUILD_MODE,
				ACTION_BUILD_CURSOR,
				ACTION_SELECT_GENERATOR,
				ACTION_PLACE_GENERATOR,
			]
		TutorialStep.EXIT_BUILD_MODE:
			return [ACTION_BUILD_MODE]
		TutorialStep.MINING:
			return [ACTION_MOVEMENT, ACTION_MINING, ACTION_COLLECT_CRYSTAL]
		TutorialStep.DELIVER_CRYSTAL:
			return [ACTION_MOVEMENT, ACTION_COLLECT_CRYSTAL, ACTION_DELIVER_CRYSTAL]
		TutorialStep.SHOOTING:
			return [ACTION_MOVEMENT, ACTION_SHOOTING]
		TutorialStep.OPEN_BUILD_MODE:
			return [ACTION_MOVEMENT, ACTION_BUILD_MODE]
		TutorialStep.PLACE_BUILDING:
			return [
				ACTION_BUILD_MODE,
				ACTION_BUILD_CURSOR,
				ACTION_SELECT_BUILDING,
				ACTION_PLACE_BUILDING,
			]
		TutorialStep.SALVAGE_BUILDING:
			return [
				ACTION_BUILD_MODE,
				ACTION_BUILD_CURSOR,
				ACTION_SALVAGE_BUILDING,
			]
	return []


func _create_objective_ui() -> void:
	if objective_scene == null:
		push_warning("TutorialManager: Objective scene is not assigned.")
		return

	objective_ui = objective_scene.instantiate() as ObjectiveTaskUI
	if not is_instance_valid(objective_ui):
		push_warning("TutorialManager: Objective scene must use ObjectiveTaskUI as root script.")
		return

	add_child(objective_ui)
	objective_ui.hide_objective()


func _show_objective(step: int) -> void:
	if is_instance_valid(objective_ui):
		objective_ui.show_task_resource(_get_task_for_step(step), _get_task_values_for_step(step))


func _hide_objective() -> void:
	if is_instance_valid(objective_ui):
		objective_ui.hide_objective()


func _hide_old_key_prompt() -> void:
	if is_instance_valid(wasd_tutorial):
		wasd_tutorial.hide()
	for label in key_labels:
		if is_instance_valid(label):
			label.hide()
