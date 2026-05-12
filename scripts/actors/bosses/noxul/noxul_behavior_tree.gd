extends Node
class_name NoxulBehaviorTree

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING,
}

enum BossState {
	CHASE,
	SUMMON,
	CHARGE_SHOT,
	RECOVER,
}

@export var boss: Noxul
@export var movement: NoxulMovement
@export var initial_summon_delay: float = 3.0
@export var summon_cooldown: float = 11.0
@export var summon_range: float = 340.0
@export var summon_recovery_time: float = 0.7
@export var initial_shot_delay: float = 1.5
@export var shot_cooldown: float = 4.5
@export var shot_range: float = 460.0
@export var shot_recovery_time: float = 0.35

var current_state := BossState.CHASE
var _summon_cooldown_left := 0.0
var _shot_cooldown_left := 0.0
var _summon_recovery_left := 0.0
var _shot_recovery_left := 0.0
var _summon_animation_started := false
var _shot_started := false


func _ready() -> void:
	_summon_cooldown_left = initial_summon_delay
	_shot_cooldown_left = initial_shot_delay
	if boss == null:
		var script_root := get_parent()
		if script_root != null:
			boss = script_root.get_parent() as Noxul
	if movement == null and is_instance_valid(boss):
		movement = boss.movement


func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.is_dead:
		return
	
	_summon_cooldown_left = max(0.0, _summon_cooldown_left - delta)
	_shot_cooldown_left = max(0.0, _shot_cooldown_left - delta)
	_tick_root_selector(delta)


func clamp_active_cooldowns_to_phase() -> void:
	_summon_cooldown_left = min(_summon_cooldown_left, summon_cooldown)
	_shot_cooldown_left = min(_shot_cooldown_left, shot_cooldown)


func _tick_root_selector(delta: float) -> Status:
	var shot_status := _tick_shot_sequence(delta)
	if shot_status == Status.RUNNING or shot_status == Status.SUCCESS:
		return shot_status
	
	var summon_status := _tick_summon_sequence(delta)
	if summon_status == Status.RUNNING or summon_status == Status.SUCCESS:
		return summon_status
	
	return _tick_chase_action()


func _tick_summon_sequence(delta: float) -> Status:
	if current_state == BossState.CHARGE_SHOT:
		return Status.FAILURE
	
	if current_state == BossState.SUMMON:
		return _tick_active_summon()
	
	if current_state == BossState.RECOVER:
		return _tick_summon_recovery(delta)
	
	if not _can_start_summon():
		return Status.FAILURE
	
	return _start_summon()


func _tick_shot_sequence(delta: float) -> Status:
	if current_state == BossState.SUMMON:
		return Status.FAILURE
	
	if current_state == BossState.CHARGE_SHOT:
		return _tick_active_shot()
	
	if current_state == BossState.RECOVER:
		if _shot_started:
			return _tick_shot_recovery(delta)
		return Status.FAILURE
	
	if not _can_start_shot():
		return Status.FAILURE
	
	return _start_shot()


func _start_summon() -> Status:
	current_state = BossState.SUMMON
	_summon_animation_started = boss.request_scream_summon()
	_summon_cooldown_left = summon_cooldown
	
	if is_instance_valid(movement):
		movement.set_enabled(false)
	
	if not _summon_animation_started:
		current_state = BossState.CHASE
		if is_instance_valid(movement):
			movement.set_enabled(true)
		return Status.FAILURE
	
	return Status.RUNNING


func _tick_active_summon() -> Status:
	if not _summon_animation_started:
		current_state = BossState.RECOVER
		_summon_recovery_left = summon_recovery_time
		return Status.RUNNING
	
	if is_instance_valid(boss.anim) and boss.anim.is_playing() and boss.anim.current_animation == "scream":
		return Status.RUNNING
	
	_summon_animation_started = false
	current_state = BossState.RECOVER
	_summon_recovery_left = summon_recovery_time
	boss.finish_scream_summon()
	return Status.RUNNING


func _tick_summon_recovery(delta: float) -> Status:
	_summon_recovery_left = max(0.0, _summon_recovery_left - delta)
	if _summon_recovery_left > 0.0:
		return Status.RUNNING
	
	current_state = BossState.CHASE
	if is_instance_valid(movement):
		movement.set_enabled(true)
	return Status.SUCCESS


func _start_shot() -> Status:
	current_state = BossState.CHARGE_SHOT
	_shot_started = boss.request_charge_shot()
	_shot_cooldown_left = shot_cooldown
	
	if is_instance_valid(movement):
		movement.set_enabled(false)
	
	if not _shot_started:
		current_state = BossState.CHASE
		if is_instance_valid(movement):
			movement.set_enabled(true)
		return Status.FAILURE
	
	return Status.RUNNING


func _tick_active_shot() -> Status:
	if boss.is_charge_shot_active():
		return Status.RUNNING
	
	current_state = BossState.RECOVER
	_shot_recovery_left = shot_recovery_time
	return Status.RUNNING


func _tick_shot_recovery(delta: float) -> Status:
	_shot_recovery_left = max(0.0, _shot_recovery_left - delta)
	if _shot_recovery_left > 0.0:
		return Status.RUNNING
	
	_shot_started = false
	current_state = BossState.CHASE
	if is_instance_valid(movement):
		movement.set_enabled(true)
	return Status.SUCCESS


func _tick_chase_action() -> Status:
	current_state = BossState.CHASE
	if is_instance_valid(movement):
		movement.set_enabled(true)
	return Status.RUNNING


func _can_start_summon() -> bool:
	if _summon_cooldown_left > 0.0:
		return false
	if not boss.can_summon_voidlings():
		return false
	if not _has_player_target():
		return false
	
	var target := _get_closest_player_position()
	return boss.global_position.distance_to(target) <= summon_range


func _can_start_shot() -> bool:
	if _shot_cooldown_left > 0.0:
		return false
	if boss.projectile_scene == null:
		return false
	
	var target := boss.get_closest_combat_target()
	if not is_instance_valid(target):
		return false
	
	return boss.global_position.distance_to(target.global_position) <= shot_range


func _has_player_target() -> bool:
	for player_res: PlayerResource in GlobalGame.Players:
		if is_instance_valid(player_res.player):
			return true
	return false


func _get_closest_player_position() -> Vector2:
	var closest_pos := boss.global_position
	var closest_dist := INF
	
	for player_res: PlayerResource in GlobalGame.Players:
		if not is_instance_valid(player_res.player):
			continue
		
		var dist := boss.global_position.distance_to(player_res.player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_pos = player_res.player.global_position
	
	return closest_pos
