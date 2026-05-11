extends RoundType
class_name RoundTypeBreak

@export var break_time: float = 30.0


func is_break_round() -> bool:
	return true


func get_spawn_count(base_count: int, wave: int, player_count: int) -> int:
	return 0


func get_wait_time(rng: RandomNumberGenerator) -> float:
	return break_time
