extends Entity_Ai

@onready var charge_timer: Timer = $charge_timer
@onready var cooldown_timer: Timer = $cooldown_timer

@export var charge_speed_mul: float = 4.0
@export var accel: float = 1200.0

var _charging: bool = false
var _on_cooldown: bool = false
var _charge_dir: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if parent.state != state:
		return
	_update(delta)
	parent.move_and_slide()


## Waits then dashes toward target in a straight locked direction
func _update(delta: float) -> void:
	if _on_cooldown:
		parent.velocity = parent.velocity.move_toward(Vector2.ZERO, accel * delta)
		return

	if _charging:
		parent.velocity = parent.velocity.move_toward(
			_charge_dir * parent.stats.get_effective_speed() * charge_speed_mul,
			accel * delta
		)
		return

	if charge_timer.is_stopped():
		_charge_dir = (parent.get_closest_target() - parent.global_position).normalized()
		charge_timer.start()


## Starts the charge dash
func _on_charge_timer_timeout() -> void:
	_charging = true
	await get_tree().create_timer(0.4).timeout
	_charging = false
	_on_cooldown = true
	cooldown_timer.start()


## Ends cooldown and allows next charge
func _on_cooldown_timer_timeout() -> void:
	_on_cooldown = false
