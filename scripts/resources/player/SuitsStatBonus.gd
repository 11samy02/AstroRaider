extends Resource
class_name SuitStatBonus

enum StatKey {
	MAX_HP,
	MAX_SPEED,
	GRAVITY_STRENGTH,
	ROTATION_SPEED,
	PROJECTILE_DAMAGE,
	ATTACK_SPEED,
	CRIT_CHANCE,
	BOHRER_DAMAGE,
	INVINCIBILITY_FRAME,
	PROJECTILE_LIVES,
	STUN_STRENGTH,
	REVEAL_RADIUS_TILES,
}

@export_category("Stat Bonus")
## Stat that receives this bonus.
@export var stat_key: StatKey = StatKey.MAX_HP

## Value added to the selected stat.
@export var value := 0.0


## Returns the stat key used by this bonus.
func get_stat_key() -> StatKey:
	return stat_key


## Returns the value added by this bonus.
func get_value() -> float:
	return value
