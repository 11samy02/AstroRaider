extends PerkBuild

var _duration_timer: Timer = null
var _is_active := false
var _dash_direction := Vector2.ZERO
var _dash_speed := 0.0
var _already_hit: Array[int] = []
var _kills_during_dash := 0

## Initializes dash timer and connects kill signal
func _ready() -> void:
	super()
	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_on_dash_finished)
	add_child(_duration_timer)
	GSignals.ENE_killed_by.connect(_on_enemy_killed)

## Moves player during dash and checks hits each frame
func _process(delta: float) -> void:
	super(delta)
	if !_is_active or !is_instance_valid(player):
		return
	var collision := player.move_and_collide(_dash_direction * _dash_speed * delta)
	if collision:
		_is_active = false
		player.can_take_damage = true
		_duration_timer.stop()
		var reduction := get_cooldown() * 0.25 * float(_kills_during_dash)
		var final_cooldown = max(get_cooldown() - reduction, 0.0)
		_kills_during_dash = 0
		cooldown_started.emit(final_cooldown)
	_check_hits()

## Activates the dash in the current input direction
func activate_perk() -> void:
	if !has_unlocked or _is_active or is_on_cooldown():
		return
	if !is_instance_valid(player):
		return
	var dir := _get_input_direction()
	if dir == Vector2.ZERO:
		return
	_dash_direction = dir
	_dash_speed = float(get_value()) / max(get_duration(), 0.01)
	_already_hit.clear()
	_kills_during_dash = 0
	_is_active = true
	player.can_take_damage = false
	_duration_timer.start(get_duration())
	if is_instance_valid(ability_slot_ref):
		ability_slot_ref.show_active(get_cooldown())

## Ends dash and starts cooldown with kill reduction
func _on_dash_finished() -> void:
	_is_active = false
	player.can_take_damage = true
	var reduction := get_cooldown() * 0.25 * float(_kills_during_dash)
	var final_cooldown = max(get_cooldown() - reduction, 0.0)
	_kills_during_dash = 0
	cooldown_started.emit(final_cooldown)

## Resets dash state
func _reset_stats() -> void:
	_is_active = false
	_already_hit.clear()
	_kills_during_dash = 0
	if is_instance_valid(player):
		player.can_take_damage = true

## Checks for enemy collisions during dash and applies bohrer damage
func _check_hits() -> void:
	for enemy: EnemyBaseTemplate in GlobalGame.Enemies:
		if !is_instance_valid(enemy):
			continue
		var id := enemy.get_instance_id()
		if _already_hit.has(id):
			continue
		var dist := player.global_position.distance_to(enemy.global_position)
		if dist > 20.0:
			continue
		_already_hit.append(id)
		GSignals.HIT_take_Damage.emit(enemy, stats.get_bohrer_damage_total(), 0.0)

## Tracks kills during dash for cooldown reduction
func _on_enemy_killed(killer: CharacterBody2D) -> void:
	if killer != player or !_is_active:
		return
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
	if Input.is_action_pressed("move_left"): dir.x -= 1.0
	if Input.is_action_pressed("move_right"): dir.x += 1.0
	if Input.is_action_pressed("move_up"): dir.y -= 1.0
	if Input.is_action_pressed("move_down"): dir.y += 1.0
	if dir != Vector2.ZERO:
		return dir.normalized()
	return player.movement.last_move_direction
