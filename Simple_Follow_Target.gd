extends Entity_Ai


func _physics_process(delta: float) -> void:
	move(delta)



func move(delta) -> void:
	match parent.state:
		state:
			parent.velocity += (parent.get_closest_target() - parent.global_position).normalized() * parent.active_stats.speed * delta
			parent.velocity = parent.velocity.clamp(Vector2(-parent.active_stats.speed, -parent.active_stats.speed), Vector2(parent.active_stats.speed, parent.active_stats.speed))
			parent.move_and_slide()

