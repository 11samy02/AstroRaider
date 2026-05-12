extends Resource
class_name AttackResource

## Identifies where an attack came from so bosses can react differently to each damage source.
enum SourceType {
	## Damage source was not specified.
	UNKNOWN,
	## Projectile fired directly by a player.
	PLAYER_PROJECTILE,
	## Damage created by a building such as a torrent.
	BUILDING,
	## Damage created by a perk or perk special.
	PERK,
	## Damage created by a support unit such as a drone.
	SUPPORT,
	## Damage created by a boss.
	BOSS,
}

@export_category("Base")
## Base damage before crits, player bonuses, and target resistances are applied.
@export var damage := 1

## Knockback strength applied by this attack.
@export var knockback := 1.0

## Additional crit chance added to the attacker's default crit chance.
@export var crit_chance := 0.00

## Source category of this attack.
@export var source_type: SourceType = SourceType.UNKNOWN

@export_category("Perks Abilities")
## Whether this attack can apply stun.
@export var has_stun := false

## Strength or duration value used by the stun receiver.
@export var stun_strength := 1
