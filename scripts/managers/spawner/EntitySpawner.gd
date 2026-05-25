extends Node
class_name EntitySpawner

enum difficulties {
	EASY,
	NORMAL,
	HARD,
	EXTREME
}

## List of normal enemy spawn resources used by this spawner.
@export var ENEMY: Array[EnemySpawnResource]

## Optional special round configs.
## Example: boss rounds, break rounds, special enemy waves, etc.
@export var round_types: Array[RoundType]

## Defines the random enemy spawn count range per wave.
@export var spawn_per_round: SimplefySettingMath = SimplefySettingMath.new()

## Defines the random pause time range before the next wave starts.
@export var time_until_wave_start: SimplefySettingMath = SimplefySettingMath.new()

## Timer used to spawn enemies during an active wave.
@onready var spawn_time: Timer = $spawn_time

## Timer used for the pause between waves.
@onready var wave_time: Timer = $wave_time

## Random number generator used for wave settings and enemy selection.
var rng := RandomNumberGenerator.new()

## Amount of enemies still waiting to be spawned in the current wave.
var wave_spawn_count := 0

## Currently active round type for this wave.
var current_round: RoundType = null

## Prevents wave EXP from being granted multiple times for the same wave.
var was_wave_exp_given := false

## Global/static wave count used by UI and other systems.
static var wave_count := 0

## Current progress inside the break timer.
static var wave_time_to_next := 0.0

## Max wait time of the current break timer.
static var wave_time_max_time := 0.0

## True if the break timer is currently stopped.
static var wave_time_stopped := true

## Default pause time.
static var pause_time := 30

## How many wave counts are added when a new wave starts.
static var wave_count_added_per_round: int = 1

## Enemy level increases every X waves.
static var enemy_levels_after: int = 3

static var difficulty : difficulties = difficulties.NORMAL

## Local wave count mirrored into the static wave_count.
@export var local_wave_count := wave_count


## Initializes the spawner, connects tutorial dialog events, and resets wave state.
func _ready() -> void:
	rng.randomize()
	Dialogic.signal_event.connect(dialog_event)
	reset()


## Public entry point used to start the wave system.
func start_wave() -> void:
	start_new_wave()


## Updates static wave timer values for UI/global access.
func _process(delta: float) -> void:
	if not GlobalGame.is_in_tutorial:
		wave_time_max_time = wave_time.wait_time
		wave_time_to_next = wave_time.wait_time - wave_time.time_left
		wave_time_stopped = wave_time.is_stopped()
		wave_count = local_wave_count
	else:
		wave_count = 1
		local_wave_count = 1


## Called when the between-wave timer ends.
## Starts a new wave if there are no active round enemies left.
func _on_wave_time_timeout() -> void:
	if GlobalGame.is_in_tutorial:
		return
	
	if not _has_active_round_entities():
		start_new_wave()


## Called repeatedly by the spawn timer.
## Spawns enemies while there are enemies left to spawn.
## Finishes the current wave once all enemies are spawned and defeated.
func _on_spawn_time_timeout() -> void:
	if current_round != null and current_round.is_break_round():
		return
	
	if wave_spawn_count > 0 and EnemyBaseTemplate.entity_list.size() < EnemyBaseTemplate.max_entitys_on_screen:
		spawn_enemy()
		return
	
	if wave_spawn_count <= 0:
		if not _has_active_round_entities() and wave_time.is_stopped():
			spawn_time.stop()
			_finish_current_round_and_start_break()


## Starts a new wave, selects its round type, calculates spawn count, and starts enemy spawning.
func start_new_wave() -> void:
	if GlobalGame.is_in_tutorial:
		return
	
	GSignals.WAV_wave_endet.emit()
	
	was_wave_exp_given = false
	
	wave_count += wave_count_added_per_round
	local_wave_count = wave_count
	
	current_round = _get_round_type_for_wave(wave_count)
	
	var base_spawn_count := rng.randi_range(
		spawn_per_round.min_value + wave_count + GlobalGame.Players.size(),
		spawn_per_round.max_value + wave_count + GlobalGame.Players.size()
	)
	
	if current_round != null:
		wave_spawn_count = current_round.get_spawn_count(base_spawn_count, wave_count, GlobalGame.Players.size())
		current_round.on_round_started(self)
	else:
		wave_spawn_count = base_spawn_count
	
	if wave_spawn_count > 0 or _has_active_round_entities():
		spawn_time.start()
	else:
		_finish_current_round_and_start_break()


## Spawns one enemy outside of the camera.
## If random_enemy is false, the first enemy from the ENEMY list is spawned.
func spawn_enemy(random_enemy: bool = true) -> EnemyBaseTemplate:
	if GlobalGame.camera == null:
		push_warning("EntitySpawner: Cannot spawn enemy without an active camera.")
		return null

	var spawn_pos: Vector2 = GlobalGame.camera.get_pos_out_of_cam()
	var enemy_scene: PackedScene = null
	
	if not random_enemy:
		enemy_scene = _get_first_enemy_scene()
	elif current_round != null:
		enemy_scene = current_round.pick_enemy(ENEMY, rng)
	else:
		enemy_scene = _pick_random_enemy_scene()
	
	if enemy_scene == null:
		push_warning("EntitySpawner: No enemy scene found.")
		return null

	var enemy := enemy_scene.instantiate() as EnemyBaseTemplate
	if enemy == null:
		push_warning("EntitySpawner: Enemy scene is not an EnemyBaseTemplate.")
		return null

	enemy.global_position = spawn_pos
	
	if "level" in enemy:
		var bonus := 0
		
		if current_round != null:
			bonus = current_round.enemy_level_bonus
		
		enemy.level = floori(wave_count / enemy_levels_after) + bonus
	
	get_parent().add_child(enemy)
	EnemyBaseTemplate.entity_list.append(enemy)

	if wave_spawn_count > 0:
		wave_spawn_count -= 1

	return enemy


## Resets all wave/spawn state.
## Call this when a new run starts.
func reset() -> void:
	local_wave_count = 0
	wave_count = 0
	wave_spawn_count = 0
	current_round = null
	was_wave_exp_given = false
	EnemyBaseTemplate.entity_list.clear()
	GlobalGame.Bosses.clear()


## Finishes the current wave, gives wave EXP once, and starts the break timer.
func _finish_current_round_and_start_break() -> void:
	var finished_wave := wave_count
	
	if current_round != null:
		current_round.on_round_finished(self)
	
	_give_wave_exp(finished_wave)
	_give_generator_defense_exp(finished_wave)
	
	if current_round != null and current_round.ends_run:
		return
	
	var wait_time := 0.0
	
	if current_round != null:
		wait_time = current_round.get_wait_time(rng)
	else:
		wait_time = rng.randf_range(time_until_wave_start.min_value, time_until_wave_start.max_value)
	
	wave_time.set_wait_time(wait_time)
	wave_time.start()


## Returns the highest-priority round type matching the given wave.
func _get_round_type_for_wave(wave: int) -> RoundType:
	var selected: RoundType = null
	
	for round_type: RoundType in round_types:
		if round_type == null:
			continue
		
		if not round_type.matches(wave):
			continue
		
		if selected == null or round_type.priority > selected.priority:
			selected = round_type
	
	return selected


## Picks a random enemy scene using the rarity values from ENEMY.
func _pick_random_enemy_scene() -> PackedScene:
	var weighted_enemies: Array[PackedScene] = []
	
	for enemy_res: EnemySpawnResource in ENEMY:
		if enemy_res == null or enemy_res.Entity == null:
			continue
		
		for i in enemy_res.rarity:
			weighted_enemies.append(enemy_res.Entity)
	
	if weighted_enemies.is_empty():
		return null
	
	return weighted_enemies.pick_random()


## Returns the first valid enemy scene from the ENEMY list.
## Used by tutorial/dialog spawning.
func _get_first_enemy_scene() -> PackedScene:
	for enemy_res: EnemySpawnResource in ENEMY:
		if enemy_res != null and enemy_res.Entity != null:
			return enemy_res.Entity
	
	return null


## Returns true if there are active enemies or bosses belonging to the current round.
func _has_active_round_entities() -> bool:
	_prune_inactive_round_entities()
	return not EnemyBaseTemplate.entity_list.is_empty() or not GlobalGame.Bosses.is_empty()


## Removes invalid enemies and bosses from their global tracking lists.
func _prune_inactive_round_entities() -> void:
	for i in range(EnemyBaseTemplate.entity_list.size() - 1, -1, -1):
		if not is_instance_valid(EnemyBaseTemplate.entity_list[i]):
			EnemyBaseTemplate.entity_list.remove_at(i)
	
	for i in range(GlobalGame.Bosses.size() - 1, -1, -1):
		if not is_instance_valid(GlobalGame.Bosses[i]):
			GlobalGame.Bosses.remove_at(i)


## Handles dialog-triggered events.
## Currently used to spawn tutorial enemies.
func dialog_event(argument: String) -> void:
	if argument == "spawn_enemies":
		wave_spawn_count = 3
		
		for i in wave_spawn_count:
			spawn_enemy(false)


## Gives EXP for completing a wave.
## This function is protected by was_wave_exp_given so each wave can only reward EXP once.
func _give_wave_exp(wave_number: int) -> void:
	if was_wave_exp_given:
		return
	
	if wave_number <= 0:
		return
	
	was_wave_exp_given = true
	
	var base_exp := 10
	var exp_per_wave := 2
	var exp_amount := base_exp + wave_number * exp_per_wave
	
	SuitExpRunTracker.add_wave_exp(exp_amount)

func _give_generator_defense_exp(wave_number: int) -> void:
	if wave_number <= 0:
		return
	
	var base_exp := 5
	var exp_per_wave := 1
	var exp_amount := base_exp + wave_number * exp_per_wave
	
	SuitExpRunTracker.add_generator_defense_exp(exp_amount)
