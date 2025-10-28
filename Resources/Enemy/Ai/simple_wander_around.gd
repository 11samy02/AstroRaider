extends Entity_Ai

@onready var change_dir_time: Timer = $change_dir_time
var dir: Vector2 = Vector2.ZERO

@export var max_speed: float = 120.0
@export var accel: float = 400.0

func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	var target_v := dir * max_speed
	parent.velocity = parent.velocity.move_toward(target_v, accel * delta)
	parent.move_and_slide()

func _on_change_dir_time_timeout() -> void:
	var a := randf() * TAU
	dir = Vector2(cos(a), sin(a))
	change_dir_time.wait_time = randf_range(0.5, 1.0)
	change_dir_time.start()
