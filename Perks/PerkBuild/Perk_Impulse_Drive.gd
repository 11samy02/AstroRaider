extends PerkBuild

var _duration_timer: Timer = null
var _kill_window_timer: Timer = null
var _is_active := false
var _in_kill_window := false
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _already_hit: Array[int] = []
var _kills_during_dash := 0

@export var tiles_destroyable_per_level: Array[int] = [1, 2, 3, 4, 5, 6]
var _tiles_destroyed := 0

## Initializes dash and kill window timers and connects kill signal
func _ready() -> void:
	super()
	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_on_dash_finished)
	add_child(_duration_timer)
	
	_kill_window_timer = Timer.new()
	_kill_window_timer.one_shot = true
	_kill_window_timer.timeout.connect(_on_kill_window_ended)
	add_child(_kill_window_timer)
	
	GSignals.ENE_killed_by.connect(_on_enemy_killed)

## Moves player during dash and checks hits each physics frame
func _physics_process(delta: float) -> void:
	if !_is_active or !is_instance_valid(player):
		return
	
	var collision: KinematicCollision2D = player.move_and_collide(_dash_direction * _dash_speed * delta)
	if collision:
		if _tiles_destroyed < get_tiles_destroyable():
			_destroy_tiles_in_front()
			_tiles_destroyed += 1
		else:
			_is_active = false
			player.can_take_damage = true
			_duration_timer.stop()
			_in_kill_window = true
			_kill_window_timer.start(0.3)
	
	_check_hits()

## Activates the dash in the current input direction
func activate_perk() -> void:
	if !has_unlocked or _is_active or is_on_cooldown():
		return
	if !is_instance_valid(player):
		return
	
	var dir: Vector2 = _get_input_direction()
	if dir == Vector2.ZERO:
		return
	
	_dash_direction = dir.normalized()
	_dash_speed = float(get_value()) / max(get_duration(), 0.01)
	_already_hit.clear()
	_kills_during_dash = 0
	_tiles_destroyed = 0
	_is_active = true
	player.can_take_damage = false
	_duration_timer.start(get_duration())
	
	if is_instance_valid(ability_slot_ref):
		ability_slot_ref.show_active(get_cooldown())

## Ends dash and opens kill window for cooldown reduction
func _on_dash_finished() -> void:
	_is_active = false
	player.can_take_damage = true
	_in_kill_window = true
	_kill_window_timer.start(0.3)

## Applies cooldown reduction when kill window ends
func _on_kill_window_ended() -> void:
	_in_kill_window = false
	var reduction: float = get_cooldown() * 0.25 * float(_kills_during_dash)
	var final_cooldown: float = max(get_cooldown() - reduction, 0.0)
	_kills_during_dash = 0
	cooldown_started.emit(final_cooldown)

## Resets dash state
func _reset_stats() -> void:
	_is_active = false
	_in_kill_window = false
	_already_hit.clear()
	_kills_during_dash = 0
	if is_instance_valid(player):
		player.can_take_damage = true

## Checks for enemy collisions during dash and applies bohrer damage
func _check_hits() -> void:
	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		if !is_instance_valid(enemy):
			continue
		var id: int = enemy.get_instance_id()
		if _already_hit.has(id):
			continue
		var dist: float = player.global_position.distance_to(enemy.global_position)
		if dist > 20.0:
			continue
		_already_hit.append(id)
		GSignals.HIT_take_Damage.emit(enemy, stats.get_bohrer_damage_total(), 0.0)

## Tracks kills during dash or kill window for cooldown reduction
func _on_enemy_killed(killer: CharacterBody2D) -> void:
	if killer != player:
		return
	if _is_active or _in_kill_window:
		_kills_during_dash += 1

## Returns true if dash is active or cooldown is running
func is_on_cooldown() -> bool:
	if _is_active:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false

## Returns input direction or falls back to player last move direction
func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		return dir.normalized()
	return player.movement.last_move_direction.normalized()

## Returns max destroyable tiles for current level
func get_tiles_destroyable() -> int:
	if tiles_destroyable_per_level.size() >= Level:
		return tiles_destroyable_per_level[Level - 1]
	return 1

## Destroys multiple tiles in front of the player based on dash direction
func _destroy_tiles_in_front() -> void:
	var dir: Vector2 = _dash_direction.normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var origin: Vector2 = player.global_position
	
	var hit_pos: Array[Vector2] = [
		origin + dir * 10.0,
		origin + dir * 14.0,
		origin + dir * 18.0,
		origin + dir * 10.0 + perp * 6.0,
		origin + dir * 10.0 - perp * 6.0,
		origin + dir * 14.0 + perp * 6.0,
		origin + dir * 14.0 - perp * 6.0
	]
	
	GSignals.ENV_destroy_tile.emit(hit_pos, 999)

## Destroys tile at collision position via environment signal
func _destroy_tile_at_collision(world_pos: Vector2) -> void:
	for env in get_tree().get_nodes_in_group("environment"):
		if env.has_method("get_node"):
			var tiles_node = env.get_node_or_null("EnvironmentTiles")
			if tiles_node and tiles_node.has_method("destroy_tile_at"):
				var pos_arr: Array[Vector2] = [world_pos]
				tiles_node.destroy_tile_at(pos_arr, 999)
				return
