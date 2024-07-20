extends Entity_Ai

var dir: Vector2
@onready var change_dir_time: Timer = $change_dir_time


func _physics_process(delta: float) -> void:
	move(delta)


func move(delta) -> void:
	match parent.state:
		state:
			parent.velocity += dir * parent.stats.speed * delta
			parent.velocity = parent.velocity.clamp(Vector2(-parent.stats.speed, -parent.stats.speed), Vector2(parent.stats.speed, parent.stats.speed))
			parent.move_and_slide()




func _on_change_dir_time_timeout() -> void:
	dir = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
	change_dir_time.set_wait_time(randf_range(0.5,1))
