extends PerkBuild

## Passive: activates aimbot on projectiles when player shoots
func _enter_tree() -> void:
	GSignals.PLA_is_shooting.connect(_on_player_shoot)

func _on_player_shoot(ply: Player) -> void:
	if has_unlocked and ply == player:
		GSignals.PERK_Aim_bot_activate.emit(player, get_value())
