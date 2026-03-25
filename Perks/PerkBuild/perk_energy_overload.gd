extends PerkBuild

var _cooldown := 0.0
var _is_active := false

## Activation: temporarily boosts stats for a duration based on perk value
func _process(delta: float) -> void:
	super(delta)
	if _cooldown > 0:
		_cooldown -= delta

func activate_perk() -> void:
	if !has_unlocked:
		return
	if _cooldown > 0:
		return
	_apply_boost()
	return true

func _apply_boost() -> void:
	stats.added_bohrer_damage = 5
	stats.added_max_speed = 50
	_cooldown = 120.0
	await get_tree().create_timer(float(get_value())).timeout
	_remove_boost()

func _remove_boost() -> void:
	stats.added_bohrer_damage = 0
	stats.added_max_speed = 0
