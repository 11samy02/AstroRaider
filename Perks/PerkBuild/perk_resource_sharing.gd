extends PerkBuild

var _collected_count := 0

## Passive: shares a percentage of collected crystals with teammates
func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(_on_crystal_collected)

func _on_crystal_collected(_pos: Vector2) -> void:
	if !has_unlocked:
		return
	_collected_count += 1
	var share := int(floor(_collected_count / 100.0 * get_value()))
	if share > 0:
		var res := get_player_res()
		for p_res: PlayerResource in GlobalGame.Players:
			if is_instance_valid(res) and p_res.player != res.player:
				p_res.crystal_count += share
