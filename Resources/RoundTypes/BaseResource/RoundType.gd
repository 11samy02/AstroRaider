extends Resource
class_name RoundType

@export_group("General")

## Display name of this round type in the Inspector.
@export var round_name: String = "Round"

## Higher priority wins if multiple round types match the same wave.
@export var priority: int = 0


@export_group("Wave Trigger")

## Wave number where this round starts.
## If repeatable is true, this means "every X waves".
@export var wave_start: int = 1

## If false, this round only happens exactly on wave_start.
## If true, this round happens every wave_start waves.
@export var repeatable: bool = false


@export_group("Break / Timing")

## Minimum wait time after this round before the next round starts.
@export var time_until_next_round_min: float = 8.0

## Maximum wait time after this round before the next round starts.
@export var time_until_next_round_max: float = 15.0


@export_group("Spawn Settings")

## Multiplies the normal enemy spawn count for this round.
@export var spawn_count_multiplier: float = 1.0

## Adds or removes enemies after the multiplier was applied.
@export var spawn_count_bonus: int = 0


@export_group("Difficulty")

## Adds extra levels to enemies spawned during this round.
@export var enemy_level_bonus: int = 0


@export_group("Round End")

## If true, finishing this round ends the run.
@export var ends_run: bool = false

## Scene loaded after this round is completed.
@export var scene_after_round: PackedScene

## Returns true if this round type should be used for the given wave.
func matches(wave: int) -> bool:
	if repeatable:
		return wave_start > 0 and wave % wave_start == 0
	
	return wave == wave_start


## Returns true if this round is a break round without enemy spawning.
func is_break_round() -> bool:
	return false


## Returns true if this round starts a boss encounter.
func is_boss_round() -> bool:
	return false


## Calculates the final enemy spawn count for this round.
func get_spawn_count(base_count: int, wave: int, player_count: int) -> int:
	var amount := int(round(float(base_count) * spawn_count_multiplier))
	amount += spawn_count_bonus
	return max(amount, 0)


## Returns the wait time after this round before the next round starts.
func get_wait_time(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(time_until_next_round_min, time_until_next_round_max)


## Picks an enemy scene from the enemy pool using rarity weighting.
func pick_enemy(enemy_pool: Array[EnemySpawnResource], rng: RandomNumberGenerator) -> PackedScene:
	var weighted_enemies: Array[PackedScene] = []
	
	for enemy_res: EnemySpawnResource in enemy_pool:
		if enemy_res == null or enemy_res.Entity == null:
			continue
		
		for i in enemy_res.rarity:
			weighted_enemies.append(enemy_res.Entity)
	
	if weighted_enemies.is_empty():
		return null
	
	return weighted_enemies.pick_random()


## Called once when this round starts.
func on_round_started(spawner: EntitySpawner) -> void:
	pass


## Called once when this round is finished.
func on_round_finished(spawner: EntitySpawner) -> void:
	if ends_run:
		if scene_after_round != null:
			ScreenTransition.change_scene_to(scene_after_round)
