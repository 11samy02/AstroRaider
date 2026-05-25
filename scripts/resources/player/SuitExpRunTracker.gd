extends Node

## Emitted whenever the total EXP collected during the current run changes.
signal run_exp_changed(current_run_exp: int)

## Emitted whenever EXP is added from a specific source.
signal exp_source_added(source_name: String, amount: int)

## Emitted whenever EXP is added from an enemy kill.
signal kill_exp_added(enemy_type: String, amount: int, kill_count: int)

## Emitted whenever EXP is added from a boss kill.
signal boss_exp_added(boss_name: String, sup_title: String, amount: int, kill_count: int)

## Emitted whenever the current run EXP is fully reset.
signal run_exp_reset()

## Emitted after the collected run EXP was applied to a SuitData resource.
signal run_exp_applied(total_exp_applied: int, gained_levels: int)


## EXP source used for enemy kills.
const SOURCE_KILLS := "kills"

## EXP source used for mining/resource related actions.
const SOURCE_MINING := "mining"

## EXP source used for crystals that can no longer be spent on perks.
const SOURCE_OVERFLOW_CRYSTALS := "overflow_crystals"

## EXP source used for completed waves.
const SOURCE_WAVES := "waves"

## EXP source used for boss rewards.
const SOURCE_BOSS := "boss"

## EXP source used for generator defense rewards.
const SOURCE_GENERATOR_DEFENSE := "generator_defense"

## Fallback EXP source used when no valid source name was provided.
const SOURCE_MISC := "misc"


## Order used when showing the main EXP source summary.
const SOURCE_DISPLAY_ORDER := [
	SOURCE_BOSS,
	SOURCE_WAVES,
	SOURCE_KILLS,
	SOURCE_MINING,
	SOURCE_OVERFLOW_CRYSTALS,
	SOURCE_GENERATOR_DEFENSE,
	SOURCE_MISC,
]

## How many destroyed mining tiles are needed for 1 Mining EXP.
const MINING_TILES_PER_EXP := 10

## How many useless/overflow crystals are needed for 1 Suit EXP.
const OVERFLOW_CRYSTALS_PER_EXP := 1

## Total EXP collected during the current run.
## This is temporary and should only be applied to the selected suit at the end of the run.
var current_run_exp := 0

## Stores leftover destroyed mining tiles that were not enough for EXP yet.
var pending_mining_tiles := 0

## Stores leftover overflow crystals that were not enough for EXP yet.
var pending_overflow_crystals := 0

## Stores how much EXP each source contributed during the current run.
## Useful for the endscreen summary.
var exp_breakdown := {
	SOURCE_KILLS: 0,
	SOURCE_MINING: 0,
	SOURCE_WAVES: 0,
	SOURCE_BOSS: 0,
	SOURCE_OVERFLOW_CRYSTALS: 0,
	SOURCE_GENERATOR_DEFENSE: 0,
	SOURCE_MISC: 0,
}


## Stores how many enemies of each type were killed and how much EXP they gave.
## Example:
## {
##     "Bat": {
##         "kills": 12,
##         "exp": 12
##     }
## }
var enemy_kill_breakdown := {}


## Stores defeated bosses and how much EXP they gave.
## Example:
## {
##     "Noxul - The Void Parasite": {
##         "kills": 1,
##         "exp": 500
##     }
## }
var boss_breakdown := {}



## Adds EXP to the current run from a custom source.
## Use this if you want to add EXP from a source that does not have a helper function yet.
func add_exp(source_name: String, amount: int) -> void:
	if amount <= 0:
		return
	
	var safe_source_name := source_name.strip_edges()
	
	if safe_source_name == "":
		safe_source_name = SOURCE_MISC
	
	current_run_exp += amount
	
	if not exp_breakdown.has(safe_source_name):
		exp_breakdown[safe_source_name] = 0
	
	exp_breakdown[safe_source_name] += amount
	
	exp_source_added.emit(safe_source_name, amount)
	run_exp_changed.emit(current_run_exp)


## Adds EXP from an enemy kill and tracks the killed enemy type.
## Call this from EnemyBaseTemplate when an enemy dies and was killed by the player.
func add_kill_exp(enemy_type: String, amount: int) -> void:
	if amount <= 0:
		return

	var safe_enemy_type := enemy_type.strip_edges()

	if safe_enemy_type == "":
		safe_enemy_type = "Unknown Enemy"

	add_exp(SOURCE_KILLS, amount)

	if not enemy_kill_breakdown.has(safe_enemy_type):
		enemy_kill_breakdown[safe_enemy_type] = {
			"kills": 0,
			"exp": 0,
		}

	enemy_kill_breakdown[safe_enemy_type]["kills"] += 1
	enemy_kill_breakdown[safe_enemy_type]["exp"] += amount

	kill_exp_added.emit(
		safe_enemy_type,
		amount,
		int(enemy_kill_breakdown[safe_enemy_type]["kills"])
	)


## Adds EXP from mining, tile destruction, resource collection, or resource related actions.
func add_mining_exp(amount: int) -> void:
	add_exp(SOURCE_MINING, amount)


## Adds EXP from completing or surviving a wave.
func add_wave_exp(amount: int) -> void:
	add_exp(SOURCE_WAVES, amount)


## Adds EXP from defeating a boss and tracks the defeated boss name and subtitle.
## Call this from BossEntity.die().
func add_boss_exp(boss_name: String, sup_title: String, amount: int) -> void:
	if amount <= 0:
		return

	var safe_boss_name := boss_name.strip_edges()
	var safe_sup_title := sup_title.strip_edges()

	if safe_boss_name == "":
		safe_boss_name = "Unknown Boss"

	if safe_sup_title == "":
		safe_sup_title = "Unknown Title"

	add_exp(SOURCE_BOSS, amount)

	if not boss_breakdown.has(safe_boss_name):
		boss_breakdown[safe_boss_name] = {
			"sup_title": safe_sup_title,
			"kills": 0,
			"exp": 0,
		}

	boss_breakdown[safe_boss_name]["sup_title"] = safe_sup_title
	boss_breakdown[safe_boss_name]["kills"] += 1
	boss_breakdown[safe_boss_name]["exp"] += amount

	boss_exp_added.emit(
		safe_boss_name,
		safe_sup_title,
		amount,
		int(boss_breakdown[safe_boss_name]["kills"])
	)

## Adds EXP from generator defense related rewards.
## Example: generator survived a wave, generator kept above certain HP, etc.
func add_generator_defense_exp(amount: int) -> void:
	add_exp(SOURCE_GENERATOR_DEFENSE, amount)


## Resets all temporary run EXP.
## Call this at the start of every new run.
func reset_run_exp() -> void:
	current_run_exp = 0
	pending_mining_tiles = 0
	pending_overflow_crystals = 0
	
	for key in exp_breakdown.keys():
		exp_breakdown[key] = 0
	
	enemy_kill_breakdown.clear()
	boss_breakdown.clear()
	
	run_exp_changed.emit(current_run_exp)
	run_exp_reset.emit()


## Applies all collected run EXP to the given suit without any multiplier.
## Returns how many levels the suit gained.
func apply_to_suit(suit_data: SuitData) -> int:
	return apply_to_suit_with_multiplier(suit_data, 1.0)


## Applies all collected run EXP to the given suit using a multiplier.
## Example:
## Death: 0.75
## Victory: 1.25
## Normal: 1.0
##
## Returns how many levels the suit gained.
func apply_to_suit_with_multiplier(suit_data: SuitData, multiplier: float) -> int:
	if not is_instance_valid(suit_data):
		return 0

	if current_run_exp <= 0:
		run_exp_applied.emit(0, 0)
		reset_run_exp()
		return 0

	var safe_multiplier := maxf(multiplier, 0.0)
	var final_exp := int(round(float(current_run_exp) * safe_multiplier))

	if final_exp <= 0:
		run_exp_applied.emit(0, 0)
		reset_run_exp()
		return 0

	var applied_exp := final_exp
	var gained_levels := 0
	var game_saver := _get_game_saver()

	if game_saver != null and game_saver.has_method("add_suit_exp"):
		var result: Dictionary = game_saver.add_suit_exp(suit_data.Key, final_exp)
		applied_exp = int(result.get("applied_exp", final_exp))

		if bool(result.get("saved", false)):
			gained_levels = int(result.get("levels_gained", 0))
			_apply_saved_progress_result_to_suit(suit_data, result)
		else:
			gained_levels = suit_data.add_exp(final_exp)
	else:
		gained_levels = suit_data.add_exp(final_exp)

	run_exp_applied.emit(applied_exp, gained_levels)
	reset_run_exp()

	return gained_levels


## Returns the total EXP collected during the current run.
func get_current_run_exp() -> int:
	return current_run_exp


## Returns how much EXP was collected from one specific source.
func get_exp_from_source(source_name: String) -> int:
	if not exp_breakdown.has(source_name):
		return 0

	return int(exp_breakdown[source_name])


## Returns a copy of all run EXP data.
## Use this if you want to build a custom UI instead of using get_full_run_breakdown_text().
func get_full_run_breakdown_data() -> Dictionary:
	return {
		"total_exp": current_run_exp,
		"pending_mining_tiles": pending_mining_tiles,
		"pending_overflow_crystals": pending_overflow_crystals,
		"exp_breakdown": exp_breakdown.duplicate(true),
		"boss_breakdown": boss_breakdown.duplicate(true),
		"enemy_kill_breakdown": enemy_kill_breakdown.duplicate(true),
	}


## Returns true if the player collected any suit EXP during this run.
func has_run_exp() -> bool:
	return current_run_exp > 0


## Returns true if at least one enemy was killed during this run.
func has_enemy_kills() -> bool:
	return enemy_kill_breakdown.size() > 0


## Returns true if at least one boss was defeated during this run.
func has_boss_kills() -> bool:
	return boss_breakdown.size() > 0


## Returns how much EXP would be applied after a multiplier.
## This does not apply the EXP yet.
func get_projected_total_exp(multiplier: float = 1.0) -> int:
	var safe_multiplier := maxf(multiplier, 0.0)
	return int(round(float(current_run_exp) * safe_multiplier))


## Returns one complete formatted run EXP summary.
## This is the main function you should use for your endscreen.
##
## Example:
## Total Suit EXP: 742
## Applied EXP: 928 (x1.25)
##
## EXP Sources
## Boss: +500 EXP
## Waves: +180 EXP
## Kills: +52 EXP
## Mining: +10 EXP
##
## Bosses Defeated
## Noxul - The Void Parasite: +500 EXP
##
## Enemies Defeated
## Bat x24: +24 EXP
## Flying Eye x8: +16 EXP
func get_full_run_breakdown_text(multiplier: float = 1.0, show_projected_exp: bool = false) -> String:
	var lines: Array[String] = []

	lines.append("Total Suit EXP: %s" % current_run_exp)

	if show_projected_exp:
		var projected_exp := get_projected_total_exp(multiplier)
		lines.append("Applied EXP: %s (x%s)" % [projected_exp, _format_float(multiplier)])

	lines.append("")

	_append_source_breakdown_lines(lines)
	_append_boss_breakdown_lines(lines)
	_append_enemy_breakdown_lines(lines)

	return "\n".join(lines).strip_edges()

## Adds destroyed mining tiles and converts them into Mining EXP.
## Example with MINING_TILES_PER_EXP = 10:
## 1 destroyed tile  = stored
## 10 destroyed tiles = +1 Mining EXP
## 25 destroyed tiles = +2 Mining EXP and 5 tiles stored
func add_mining_tiles(destroyed_tiles_count: int) -> void:
	if destroyed_tiles_count <= 0:
		return
	
	pending_mining_tiles += destroyed_tiles_count
	
	var mining_exp := int(floor(float(pending_mining_tiles) / float(MINING_TILES_PER_EXP)))
	
	if mining_exp <= 0:
		return
	
	pending_mining_tiles -= mining_exp * MINING_TILES_PER_EXP
	add_mining_exp(mining_exp)

## Adds useless/overflow crystals and converts them into Suit EXP.
## Use this when the player brings crystals to the generator but can no longer receive new perks.
##
## Example with OVERFLOW_CRYSTALS_PER_EXP = 1:
## 1 overflow crystal = +1 Suit EXP
## 10 overflow crystals = +10 Suit EXP
func add_overflow_crystals(crystal_count: int) -> void:
	if crystal_count <= 0:
		return
	
	pending_overflow_crystals += crystal_count
	
	var overflow_exp := int(floor(float(pending_overflow_crystals) / float(OVERFLOW_CRYSTALS_PER_EXP)))
	
	if overflow_exp <= 0:
		return
	
	pending_overflow_crystals -= overflow_exp * OVERFLOW_CRYSTALS_PER_EXP
	add_exp(SOURCE_OVERFLOW_CRYSTALS, overflow_exp)

## Adds the main EXP source breakdown to the given line array.
func _append_source_breakdown_lines(lines: Array[String]) -> void:
	var has_any_source := false

	for source_name in SOURCE_DISPLAY_ORDER:
		var amount := get_exp_from_source(source_name)

		if amount <= 0:
			continue

		if not has_any_source:
			lines.append("EXP Sources")
			has_any_source = true

		lines.append("%s: +%s EXP" % [_format_source_name(source_name), amount])

	if has_any_source:
		lines.append("")


## Adds the boss breakdown to the given line array.
func _append_boss_breakdown_lines(lines: Array[String]) -> void:
	if boss_breakdown.is_empty():
		return
	
	lines.append("Bosses Defeated")
	
	for boss_name in boss_breakdown.keys():
		var data: Dictionary = boss_breakdown[boss_name]
		var sup_title := str(data.get("sup_title", "")).strip_edges()
		var kills := int(data.get("kills", 0))
		var exp := int(data.get("exp", 0))
	
		if kills <= 0:
			continue
	
		var display_name := str(boss_name)
	
		if sup_title != "":
			display_name = "%s - %s" % [display_name, sup_title]
	
		if kills == 1:
			lines.append("%s: +%s EXP" % [display_name, exp])
		else:
			lines.append("%s x%s: +%s EXP" % [display_name, kills, exp])
	
	lines.append("")


## Adds the enemy kill breakdown to the given line array.
func _append_enemy_breakdown_lines(lines: Array[String]) -> void:
	if enemy_kill_breakdown.is_empty():
		return

	lines.append("Enemies Defeated")

	for enemy_type in enemy_kill_breakdown.keys():
		var data: Dictionary = enemy_kill_breakdown[enemy_type]
		var kills := int(data.get("kills", 0))
		var exp := int(data.get("exp", 0))

		if kills <= 0:
			continue

		lines.append("%s x%s: +%s EXP" % [str(enemy_type), kills, exp])


## Converts internal source keys into readable names for UI text.
func _format_source_name(source_name: String) -> String:
	match source_name:
		SOURCE_KILLS:
			return "Kills"
		SOURCE_MINING:
			return "Mining"
		SOURCE_WAVES:
			return "Waves"
		SOURCE_BOSS:
			return "Boss"
		SOURCE_OVERFLOW_CRYSTALS:
			return "Overflow Crystals"
		SOURCE_GENERATOR_DEFENSE:
			return "Generator Defense"
		SOURCE_MISC:
			return "Misc"
		_:
			return source_name.capitalize()

## Formats multiplier values for readable UI text.
func _format_float(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))

	var text := "%.2f" % value

	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)

	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)

	return text


func _apply_saved_progress_result_to_suit(suit_data: SuitData, result: Dictionary) -> void:
	if not is_instance_valid(suit_data):
		return

	suit_data.current_level = clampi(int(result.get("current_level", suit_data.current_level)), 1, suit_data.max_level)
	suit_data.current_exp = max(0, int(result.get("current_exp", suit_data.current_exp)))
	suit_data.has_unlocked = bool(result.get("has_unlocked", suit_data.has_unlocked))

	if suit_data.is_max_level():
		suit_data.current_exp = 0


func _get_game_saver() -> Node:
	var main_loop := Engine.get_main_loop()

	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("GameSaver")

	return null
