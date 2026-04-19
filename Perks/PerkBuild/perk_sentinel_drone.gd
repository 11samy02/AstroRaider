extends PerkBuild

const SENTINEL_DRONE_SCENE := preload("res://Objects/Perk Specials/Sentinel_Drone.tscn")
const PROJECTILE := preload("res://Projectiles/Photon_gun_projectile.tscn")

var _active_drones: Array[SentinelDrone] = []
var _is_active := false

@export var hp_per_level: Array[int] = [10, 10, 50, 50, 125, 125]
@export var damage_per_level: Array[int] = [1, 1, 3, 3, 7, 7]
@export var fire_rate_per_level: Array[float] = [1.0, 1.0, 0.5, 0.5, 0.25, 0.25]
@export var explosion_damage_per_level: Array[int] = [5, 5, 10, 10, 25, 25]

func _ready() -> void:
	super()

func activate_perk() -> void:
	if not has_unlocked:
		return
	if _is_active:
		return
	if is_on_cooldown():
		return
	if not is_instance_valid(player):
		return

	_clear_drones(true)
	_spawn_drones()

	if _active_drones.is_empty():
		return

	_is_active = true

	if is_instance_valid(ability_slot_ref):
		ability_slot_ref.show_active(get_cooldown())

func _reset_stats() -> void:
	_is_active = false
	_clear_drones(true)

func is_on_cooldown() -> bool:
	if _is_active:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false

func _spawn_drones() -> void:
	var scene_root := get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var count := get_value()

	for i in range(count):
		var drone := SENTINEL_DRONE_SCENE.instantiate() as SentinelDrone
		if not is_instance_valid(drone):
			continue

		var spawn_angle := (TAU / float(max(1, count))) * float(i)
		var spawn_offset := Vector2.RIGHT.rotated(spawn_angle) * 18.0

		scene_root.add_child(drone)
		drone.global_position = player.global_position + spawn_offset
		drone.create(self, PROJECTILE, spawn_offset)

		drone.died.connect(_on_drone_died)
		drone.tree_exited.connect(_on_drone_tree_exited.bind(drone))
		_active_drones.append(drone)

func _clear_drones(instant: bool) -> void:
	for drone: SentinelDrone in _active_drones:
		if not is_instance_valid(drone):
			continue
		if instant:
			drone.queue_free()
		else:
			drone.die()
	_active_drones.clear()

func _on_drone_died(drone: SentinelDrone) -> void:
	_active_drones.erase(drone)

	if _active_drones.is_empty():
		_is_active = false
		cooldown_started.emit(get_cooldown())

func _on_drone_tree_exited(drone: SentinelDrone) -> void:
	_active_drones.erase(drone)

func get_drone_tier() -> SentinelDrone.DroneTier:
	if Level >= 5:
		return SentinelDrone.DroneTier.HEAVY
	if Level >= 3:
		return SentinelDrone.DroneTier.MEDIUM
	return SentinelDrone.DroneTier.SMALL

func get_drone_hp() -> int:
	return hp_per_level[clampi(Level - 1, 0, hp_per_level.size() - 1)]

func get_drone_damage() -> int:
	return damage_per_level[clampi(Level - 1, 0, damage_per_level.size() - 1)]

func get_drone_fire_rate() -> float:
	return fire_rate_per_level[clampi(Level - 1, 0, fire_rate_per_level.size() - 1)]

func get_drone_explosion_damage() -> int:
	return explosion_damage_per_level[clampi(Level - 1, 0, explosion_damage_per_level.size() - 1)]
