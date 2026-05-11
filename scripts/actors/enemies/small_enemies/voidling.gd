extends EnemyBaseTemplate
class_name Voidling

static var kill_count: int = 0

## Increments kill count and triggers base death logic
func death() -> void:
	kill_count += 1
	super()
