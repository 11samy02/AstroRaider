extends PerkBuild

var rounds_to_wait := 0


func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(decrease_waiting)


func _process(delta: float) -> void:
	if rounds_to_wait <= 0 and Player_Res.current_health <= Player_Res.max_health / 4:
		GSignals.HIT_take_heal.emit(Player_Res.player, Player_Res.max_health / 100 * get_value())
		rounds_to_wait = 5

func decrease_waiting() -> void:
	rounds_to_wait -= 1

func _exit_tree() -> void:
	pass
