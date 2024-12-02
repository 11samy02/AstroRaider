extends PerkBuild

var collected_count := 0

func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(share_coins)

func share_coins() -> void:
	collected_count += 1
	
	if floor(collected_count / 100 * get_value()) > 0:
		for p_res : PlayerResource in GlobalGame.Players:
			if p_res.player != Player_Res.player:
				p_res.crystal_count += floor(collected_count / 100 * get_value())
				print(p_res.crystal_count)

func _exit_tree() -> void:
	pass
