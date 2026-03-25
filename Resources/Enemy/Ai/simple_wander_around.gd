extends Entity_Ai

@onready var change_dir_time: Timer = $change_dir_time

@export var max_speed: float = 120.0
@export var accel: float = 400.0

var _dir: Vector2 = Vector2.ZERO


func _ready() -> void:
	_pick_random_dir()


func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	parent.velocity = parent.velocity.move_toward(_dir * max_speed, accel * delta)
	parent.move_and_slide()


## Picks a new random direction and randomizes next interval
func _on_change_dir_time_timeout() -> void:
	_pick_random_dir()
	change_dir_time.wait_time = randf_range(0.5, 1.0)
	change_dir_time.start()


func _pick_random_dir() -> void:
	var angle := randf() * TAU
	_dir = Vector2(cos(angle), sin(angle))
