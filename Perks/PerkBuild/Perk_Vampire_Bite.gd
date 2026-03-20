extends PerkBuild

## Passive: heals player when they kill an enemy
func _enter_tree() -> void:
	GSignals.ENE_killed_by.connect(_on_enemy_killed)

func _on_enemy_killed(killed_by: Player) -> void:
	if !has_unlocked:
		return
	if killed_by == player:
		GSignals.HIT_take_heal.emit(player, get_value())
