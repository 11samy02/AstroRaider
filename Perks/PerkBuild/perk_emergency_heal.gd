extends PerkBuild

var rounds_to_wait := 0

var Player_Res : PlayerResource

func _enter_tree() -> void:
	GSignals.WAV_wave_endet.connect(decrease_waiting)

func _ready() -> void:
	super()


func _process(delta: float) -> void:
	if !is_instance_valid(Player_Res):
		for ply_res : PlayerResource in GlobalGame.Players:
			if ply_res.player == player:
				Player_Res = ply_res
	if rounds_to_wait <= 0 and Player_Res.current_health <= Player_Res.max_health / 4:
		GSignals.HIT_take_heal.emit(Player_Res.player, Player_Res.max_health / 100 * get_value())
		rounds_to_wait = 5

func decrease_waiting() -> void:
	rounds_to_wait -= 1
