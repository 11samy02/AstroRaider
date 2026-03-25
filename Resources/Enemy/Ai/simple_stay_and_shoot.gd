extends Entity_Ai

@export var brake: float = 800.0
@export var stop_threshold: float = 30.0
@export var projectiles_holder: NodePath

var _has_attacked := false


func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_attack(delta)
	parent.move_and_slide()


## Brakes to a stop then fires a projectile toward the target
func _attack(delta: float) -> void:
	if _has_attacked:
		return
	parent.velocity = parent.velocity.move_toward(Vector2.ZERO, brake * delta)
	if parent.velocity.length() >= stop_threshold:
		return
	_has_attacked = true
	_shoot()
	parent.reset_to_last_state()
	_has_attacked = false


## Spawns and aims a projectile at the closest target
func _shoot() -> void:
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
