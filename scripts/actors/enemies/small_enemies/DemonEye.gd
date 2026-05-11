extends EnemyBaseTemplate
class_name DemonEye

static var kill_count: int = 0


## Increments kill count and triggers base death logic
func death() -> void:
	kill_count += 1
	super()
