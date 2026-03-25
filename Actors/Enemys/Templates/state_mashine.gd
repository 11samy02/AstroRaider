extends Node
class_name EnemyStateMachine

@export var enemy: EnemyBaseTemplate
@export var wander_time: Timer
@export var follow_time: Timer
@export var shoot_delay: Timer

## Runs the universal state machine logic based on enemy stats behavior settings
func run() -> void:
	if !enemy.knockback_time.is_stopped():
		enemy.move_and_slide()
		return
	var dist := enemy.global_position.distance_to(enemy.get_closest_target())
	var stats := enemy.stats
	if dist >= stats.follow_distance:
		_set_follow()
	elif stats.can_ranged_attack and dist >= stats.ranged_min_distance and dist <= stats.ranged_max_distance:
		if is_instance_valid(shoot_delay) and shoot_delay.is_stopped():
			var roll := randf() * 100.0
			if roll > stats.ranged_chance:
				_set_follow()
			else:
				_set_ranged_attack()
		else:
			_set_follow()
	elif dist > stats.ranged_max_distance:
		_set_follow()
	elif stats.can_ranged_attack and dist < stats.ranged_min_distance:
		_set_ranged_attack()
	elif dist >= stats.attack_distance:
		if stats.can_wander and _timers_stopped():
			if randi_range(0, 1) == 0:
				_set_follow()
			else:
				_set_wander()
		elif !stats.can_wander:
			_set_follow()
	else:
		if enemy.state != enemy.state_mashine.Wander:
			enemy.state = enemy.state_mashine.Attack

## Sets state to Follow and starts follow timer if available and stopped
func _set_follow() -> void:
	enemy.state = enemy.state_mashine.Follow
	if is_instance_valid(follow_time) and follow_time.is_stopped():
		follow_time.start()

## Sets state to Wander and starts wander timer if available and stopped
func _set_wander() -> void:
	if !enemy.stats.can_wander:
		_set_follow()
		return
	enemy.state = enemy.state_mashine.Wander
	if is_instance_valid(wander_time) and wander_time.is_stopped():
		wander_time.start()

## Sets state to Ranged Attack and starts shoot delay timer
func _set_ranged_attack() -> void:
	enemy.last_state = enemy.state
	enemy.state = enemy.state_mashine.Ranged_Attack
	if is_instance_valid(shoot_delay):
		shoot_delay.start()

## Returns true if both wander and follow timers are stopped or invalid
func _timers_stopped() -> bool:
	var wander_done := !is_instance_valid(wander_time) or wander_time.is_stopped()
	var follow_done := !is_instance_valid(follow_time) or follow_time.is_stopped()
	return wander_done and follow_done

## Resets state to Follow when wander timer ends
func on_wander_timeout() -> void:
	_set_follow()
