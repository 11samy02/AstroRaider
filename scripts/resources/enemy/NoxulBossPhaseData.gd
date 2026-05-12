extends BossPhaseData
class_name NoxulBossPhaseData

@export_group("Projectiles")
## Number of projectiles fired in one charge shot.
@export_range(1, 64, 1) var projectile_count: int = 3

## Half-spread angle in degrees for the projectile fan.
@export_range(0.0, 90.0, 1.0) var projectile_spread_angle: float = 13.0

## Damage used by Noxul's charge projectile in this phase.
@export var charge_damage: int = 10

## Knockback strength used by Noxul's charge projectile in this phase.
@export var charge_knockback: float = 2.0

@export_group("Voidlings")
## Number of voidlings spawned per scream summon.
@export_range(0, 64, 1) var minions_spawn_count: int = 3

## Maximum number of Noxul-spawned voidlings that may be alive at once.
@export_range(0, 128, 1) var max_active_voidlings: int = 6

@export_group("Behavior")
## Chance from 0 to 1 that a charge shot targets a player building instead of a player/support target.
@export_range(0.0, 1.0, 0.01) var building_target_chance: float = 0.25

## Maximum distance from Noxul where buildings can be selected as projectile targets.
@export var building_target_range: float = 620.0

## Time in seconds between summon attempts.
@export var summon_cooldown: float = 11.0

## Maximum distance to the closest player before Noxul is allowed to summon.
@export var summon_range: float = 340.0

## Time in seconds Noxul stays in recovery after a summon.
@export var summon_recovery_time: float = 0.7

## Time in seconds between charge shot attempts.
@export var shot_cooldown: float = 4.5

## Maximum distance to a combat target before Noxul is allowed to shoot.
@export var shot_range: float = 460.0

## Time in seconds Noxul stays in recovery after a charge shot.
@export var shot_recovery_time: float = 0.35

@export_group("Movement")
## Maximum movement speed while chasing or orbiting targets.
@export var move_speed: float = 90.0

## Acceleration used when changing velocity.
@export var acceleration: float = 420.0

## Preferred distance Noxul tries to keep from its target.
@export var hover_distance: float = 140.0

## Amount of sideways orbit movement mixed into the chase direction.
@export_range(0.0, 1.0, 0.05) var orbit_weight: float = 0.45

@export_group("Tentacles")
## Maximum distance from a player where a tentacle can start an attack.
@export var tentacle_attack_range: float = 230.0

## Maximum lunge distance of a tentacle attack.
@export var tentacle_lunge_length: float = 160.0

## Knockback applied to the player when hit by a tentacle.
@export var tentacle_knockback_strength: float = 5.5

## Optional direct damage dealt by a tentacle hit. Set to 0 for knockback only.
@export var tentacle_attack_damage: int = 0

## Minimum random cooldown between tentacle attacks.
@export var tentacle_cooldown_min: float = 2.2

## Maximum random cooldown between tentacle attacks.
@export var tentacle_cooldown_max: float = 4.4

@export_group("Defense")
## Global multiplier applied to all incoming damage in this phase.
@export_range(0.0, 2.0, 0.01) var incoming_damage_multiplier: float = 1.0

## Extra multiplier for damage coming from buildings such as torrents.
@export_range(0.0, 2.0, 0.01) var building_damage_multiplier: float = 0.7

## Extra multiplier for perk damage such as Blood Claw.
@export_range(0.0, 2.0, 0.01) var perk_damage_multiplier: float = 0.8

## Extra multiplier for support damage such as drones.
@export_range(0.0, 2.0, 0.01) var support_damage_multiplier: float = 0.85

## Caps damage per hit after multipliers. Set to 0 to disable the cap.
@export_range(0, 999, 1) var max_damage_per_hit: int = 0
