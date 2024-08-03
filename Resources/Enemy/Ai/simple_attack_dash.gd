extends Entity_Ai

@onready var dash_time: Timer = $dash_time

var has_attacked :bool = false

func _physics_process(delta: float) -> void:
	attack()



func attack() -> void:
	match parent.state:
		state:
			if parent.global_position.distance_to(parent.get_closest_target()) < 5:
				has_attacked = true
			if !has_attacked:
				parent.velocity = (parent.get_closest_target() - parent.global_position).normalized() * parent.active_stats.speed * 2
				if dash_time.is_stopped():
					dash_time.start()
			else:
				parent.velocity = (parent.global_position - parent.get_closest_target()).normalized() * parent.active_stats.speed * 0.75
				if dash_time.is_stopped():
					dash_time.start()
			parent.move_and_slide()



func _on_dash_time_timeout() -> void:
	has_attacked = !has_attacked
