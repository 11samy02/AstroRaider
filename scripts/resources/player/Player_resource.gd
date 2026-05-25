extends Resource
class_name PlayerResource

## Runtime player node linked to this resource.
var player : Player
## Runtime player hand node linked to this resource.
var player_hand : PlayerHand
## Cached maximum health for UI/runtime health tracking.
var max_health := 150
## Current runtime health value.
var current_health := 150

## Whether this player currently has a valid navigation path.
var has_a_path := false
## Whether the one-time crystal path hint has already been shown this run.
var has_shown_first_crystal_path := false

## Activation perks currently assigned to this player.
var activation_skills : Array[PerkBuild] = []
## Current activation skill index.
var activation_id := 0

## Runtime shield state shared by shield perks.
var shield_res : HasShieldRes = HasShieldRes.new()
## Whether anti-mine detection is active for this player.
var has_perk_anti_mine_det := false

## Real crystal count used for purchases and perk selection.
var crystal_count := 0
## Animated crystal count used by UI.
var fake_crystal_count := 0
## Collected ore amounts keyed by ore type.
var Ores : Dictionary = {}
