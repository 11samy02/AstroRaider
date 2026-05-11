extends RoundType
class_name RoundTypeBoss

@export_group("Boss")

## Scene that will be spawned as the boss for this round.
@export var boss_scene: PackedScene

## If true, the boss spawns outside the camera view.
## If false, the boss spawns at the spawner position.
@export var boss_spawn_position_from_camera: bool = true
@export_range(0.2, 1.0, 0.05) var boss_spawn_distance_scale: float = 0.65
@export var boss_spawn_random_offset: float = 96.0

## If true, all normal enemies are removed before the boss spawns.
@export var clear_normal_enemies_before_boss: bool = true


## Sets useful default values for boss rounds.
func _init() -> void:
	round_name = "Boss Round"
	priority = 100
	spawn_count_multiplier = 0.0


## Returns true because this is a boss round.
func is_boss_round() -> bool:
	return true


## Boss rounds do not spawn normal enemies.
func get_spawn_count(base_count: int, wave: int, player_count: int) -> int:
	return 0


## Spawns the boss and optionally clears normal enemies first.
func on_round_started(spawner: EntitySpawner) -> void:
	if boss_scene == null:
		push_warning("Boss round has no boss_scene assigned.")
		return
	
	if clear_normal_enemies_before_boss:
		for enemy in EnemyBaseTemplate.entity_list:
			if is_instance_valid(enemy):
				enemy.queue_free()
		EnemyBaseTemplate.entity_list.clear()
	
	var boss = boss_scene.instantiate()
	
	if boss_spawn_position_from_camera and GlobalGame.camera != null:
		boss.global_position = GlobalGame.camera.get_spawn_marker_position(
			boss_spawn_distance_scale,
			boss_spawn_random_offset
		)
	else:
		boss.global_position = spawner.global_position
	
	spawner.get_parent().add_child(boss)
	
	if "level" in boss:
		boss.level = floori(EntitySpawner.wave_count / EntitySpawner.enemy_levels_after)
