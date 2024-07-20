extends Entity_Ai


func _physics_process(delta: float) -> void:
	move(delta)



func move(delta) -> void:
	match parent.state:
		state:
			parent.velocity += (parent.get_closest_target() - parent.global_position).normalized() * parent.stats.speed * delta
			parent.velocity = parent.velocity.clamp(Vector2(-parent.stats.speed, -parent.stats.speed), Vector2(parent.stats.speed, parent.stats.speed))
			parent.move_and_slide()

