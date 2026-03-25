extends Entity_Ai


func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_move(delta)
	parent.move_and_slide()


## Moves smoothly toward the closest target
func _move(delta: float) -> void:
	var dir := (parent.get_closest_target() - parent.global_position).normalized()
	parent.velocity = parent.velocity.move_toward(
		dir * parent.stats.speed,
		parent.stats.speed * delta * 10
	)
