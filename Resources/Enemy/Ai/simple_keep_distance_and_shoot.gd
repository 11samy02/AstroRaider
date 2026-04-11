extends Entity_Ai

@onready var shoot_timer: Timer = $shoot_timer
@export var preferred_distance: float = 150.0
@export var accel: float = 600.0
@export var brake: float = 800.0
@export var projectiles_holder: NodePath

## Starts shoot timer on ready
func _ready() -> void:
	shoot_timer.start()

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_move(delta)
	parent.move_and_slide()

## Moves toward or away from target to maintain preferred distance
func _move(delta: float) -> void:
	var to_tgt := parent.get_closest_target() - parent.global_position
	var dist := to_tgt.length()
	var dir := to_tgt.normalized()
	if dist > preferred_distance + 20.0:
		parent.velocity = parent.velocity.move_toward(dir * parent.stats.get_effective_speed(), accel * delta)
	elif dist < preferred_distance - 20.0:
		parent.velocity = parent.velocity.move_toward(-dir * parent.stats.get_effective_speed(), accel * delta)
	else:
		parent.velocity = parent.velocity.move_toward(Vector2.ZERO, brake * delta)

## Fires a projectile toward the target on timer interval
func _on_shoot_timer_timeout() -> void:
	if not is_instance_valid(parent):
		return
	if parent.state != state:
		return
	if not parent.stats.projectile:
		return
	if parent.Shoot_sound:
		parent.Shoot_sound.play_sound()
	var prj := parent.stats.projectile.instantiate()
	if prj is EnemyProjectile:
		prj.dir = (parent.get_closest_target() - parent.global_position).normalized()
		if parent.stats.ranged_attack:
			prj.atk_resource = parent.stats.ranged_attack.duplicate()
		prj.global_position = parent.global_position
		_get_projectile_parent().add_child(prj)

## Returns the node to parent projectiles under
func _get_projectile_parent() -> Node:
	if projectiles_holder != NodePath():
		var n := get_node_or_null(projectiles_holder)
		if n:
			return n
	var root := get_tree().current_scene if get_tree().current_scene else get_tree().root
	return root.get_node_or_null("Projectiles") if root.has_node("Projectiles") else root
