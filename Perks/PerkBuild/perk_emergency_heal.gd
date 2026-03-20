extends PerkBuild

var _rounds_to_wait := 0

## Passive: automatically heals when HP drops below 25%
func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(_on_wave_ended)

func _process(delta: float) -> void:
	if !has_unlocked:
		return
	var res := get_player_res()
	if !is_instance_valid(res):
		return
	if _rounds_to_wait <= 0 and res.current_health <= res.max_health / 4.0:
		GSignals.HIT_take_heal.emit(player, res.max_health / 100.0 * get_value())
		_rounds_to_wait = 5

func _on_wave_ended() -> void:
	_rounds_to_wait -= 1
