extends Resource
class_name SuitData

signal exp_changed(current_exp: int, exp_to_next: int)
signal leveled_up(new_level: int)
signal max_level_reached()

enum SuitKeys {
	NONE,
	Trailblazer,
	Bloodreaver,
}

const Keys_res = {
	SuitKeys.Trailblazer: "res://resources/characters/Suit_Trailblazer.tres",
	SuitKeys.Bloodreaver: "res://resources/characters/Suit_Bloodreaver.tres",
}

static var _res_cache := {}

@export_category("General")
## Unique key used to load and compare this suit.
@export var Key: SuitKeys = SuitKeys.Trailblazer

## Display name shown for this suit.
@export var suit_name := ""

## Player-facing description of the suit.
@export_multiline var description := ""

## Image shown for this suit.
@export var image: Texture2D

@export_category("Progress")
## Current meta progression level for this suit.
@export_range(1, 100) var current_level := 1

## Maximum level this suit can reach.
@export_range(1, 100) var max_level := 100

## Current stored experience for this suit level.
@export var current_exp := 0

## Whether this suit is unlocked for player use.
@export var has_unlocked := false

@export_category("Experience Formula")
## Base EXP required for the first levels.
@export var exp_base := 75.0

## Linear EXP increase per level.
@export var exp_linear_gain := 18.0

## Curved scaling strength. Higher values make later levels slower.
@export var exp_curve_power := 1.35

## Final multiplier applied to the whole EXP formula.
@export var exp_multiplier := 1.0

@export_category("Stats")
## Base stats granted while this suit is selected.
@export var stats: Stats = Stats.new()

## Repeating stat upgrade rules applied based on this suit's current level.
@export var stat_level_rules: Array[SuitStatLevelRule] = []


## Loads a suit resource by key and returns a deep duplicate with no save data applied.
static func load_base_suit_res(key: SuitKeys) -> SuitData:
	var path = Keys_res.get(key)

	if path == null or path == "":
		return null

	if _res_cache.has(key):
		return _res_cache[key].duplicate(true)

	var res: SuitData = load(path)

	if not is_instance_valid(res):
		return null

	_res_cache[key] = res
	return res.duplicate(true)


## Loads a suit resource by key and returns a deep duplicate for runtime use.
## If GameSaver is active, persisted slot progress is applied automatically.
static func load_suit_res(key: SuitKeys, use_saved_progress := true) -> SuitData:
	var suit_data := load_base_suit_res(key)

	if not is_instance_valid(suit_data):
		return null

	if use_saved_progress:
		_apply_saved_progress_to_runtime_suit(suit_data)

	return suit_data


static func _apply_saved_progress_to_runtime_suit(suit_data: SuitData) -> void:
	var game_saver := _get_game_saver()

	if game_saver != null and game_saver.has_method("apply_saved_suit_progress"):
		game_saver.apply_saved_suit_progress(suit_data)


static func _get_game_saver() -> Node:
	var main_loop := Engine.get_main_loop()

	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null("GameSaver")

	return null


## Adds EXP to this suit and automatically handles level ups.
func add_exp(amount: int) -> int:
	if amount <= 0:
		return 0

	if is_max_level():
		current_exp = 0
		max_level_reached.emit()
		return 0

	current_exp += amount

	var levels_gained := 0

	while current_exp >= get_exp_to_next_level() and not is_max_level():
		current_exp -= get_exp_to_next_level()
		current_level += 1
		levels_gained += 1
		leveled_up.emit(current_level)

	if is_max_level():
		current_exp = 0
		max_level_reached.emit()

	exp_changed.emit(current_exp, get_exp_to_next_level())

	return levels_gained


## Sets the suit level directly and clamps it between 1 and max_level.
func set_level(value: int) -> void:
	current_level = clampi(value, 1, max_level)

	if is_max_level():
		current_exp = 0

	exp_changed.emit(current_exp, get_exp_to_next_level())


## Returns true if this suit has reached max level.
func is_max_level() -> bool:
	return current_level >= max_level


## Returns the EXP required to reach the next level.
func get_exp_to_next_level() -> int:
	if is_max_level():
		return 0

	return get_exp_required_for_level(current_level)


## Returns the EXP required to level up from a specific level.
func get_exp_required_for_level(level: int) -> int:
	var safe_level = max(1, level)
	var value := exp_base + pow(float(safe_level), exp_curve_power) * exp_linear_gain
	return int(ceil(value * exp_multiplier))


## Returns progress toward the next level from 0.0 to 1.0.
func get_exp_progress_ratio() -> float:
	var required_exp := get_exp_to_next_level()

	if required_exp <= 0:
		return 1.0

	return clampf(float(current_exp) / float(required_exp), 0.0, 1.0)


## Returns a duplicated Stats resource with all suit level bonuses applied.
func get_runtime_stats() -> Stats:
	var runtime_stats := Stats.new()

	if stats is Stats:
		runtime_stats = stats.duplicate(true)

	_apply_level_bonuses_to_stats(runtime_stats)

	return runtime_stats


## Applies all calculated level bonuses to the given runtime stats resource.
func _apply_level_bonuses_to_stats(target_stats: Stats) -> void:
	if not is_instance_valid(target_stats):
		return

	var bonus_dict := get_total_stat_bonus_dict()
	var modifier_id := get_suit_modifier_id()

	for stat_key in bonus_dict.keys():
		var value: float = bonus_dict[stat_key]

		match stat_key:
			SuitStatBonus.StatKey.MAX_HP:
				target_stats.set_modifier(target_stats.max_hp_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.MAX_SPEED:
				target_stats.set_modifier(target_stats.max_speed_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.GRAVITY_STRENGTH:
				target_stats.set_modifier(target_stats.gravity_strength_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.ROTATION_SPEED:
				target_stats.set_modifier(target_stats.rotation_speed_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.PROJECTILE_DAMAGE:
				target_stats.set_modifier(target_stats.projectile_damage_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.ATTACK_SPEED:
				target_stats.set_modifier(target_stats.attack_speed_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.CRIT_CHANCE:
				target_stats.set_modifier(target_stats.crit_chance_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.BOHRER_DAMAGE:
				target_stats.set_modifier(target_stats.bohrer_damage_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.INVINCIBILITY_FRAME:
				target_stats.set_modifier(target_stats.invincibility_frame_modifiers, modifier_id, value)

			SuitStatBonus.StatKey.PROJECTILE_LIVES:
				target_stats.set_modifier(target_stats.projectile_lives_modifiers, modifier_id, value)

			_:
				push_warning("Unhandled suit stat key: " + str(stat_key))

## Returns all suit stat bonuses from every active level rule.
func get_total_stat_bonus_dict() -> Dictionary:
	var result := {}
	var sorted_rules := stat_level_rules.duplicate()

	sorted_rules.sort_custom(func(a: SuitStatLevelRule, b: SuitStatLevelRule) -> bool:
		if not is_instance_valid(a):
			return false

		if not is_instance_valid(b):
			return true

		return a.priority > b.priority
	)

	for rule in sorted_rules:
		if not is_instance_valid(rule):
			continue

		var rule_bonus = rule.get_total_bonus_dict(current_level)

		for stat_key in rule_bonus.keys():
			if not result.has(stat_key):
				result[stat_key] = 0.0

			result[stat_key] += rule_bonus[stat_key]

	return result


## Returns the total bonus value for one specific stat.
func get_total_stat_bonus(stat_key: SuitStatBonus.StatKey) -> float:
	var bonuses := get_total_stat_bonus_dict()

	if not bonuses.has(stat_key):
		return 0.0

	return bonuses[stat_key]


## Returns how often a specific stat upgrade rule has triggered.
func get_rule_trigger_count(rule: SuitStatLevelRule) -> int:
	if not is_instance_valid(rule):
		return 0

	return rule.get_trigger_count(current_level)


## Returns true if this suit unlocks alt fire at level 20.
func has_alt_fire_unlocked() -> bool:
	return current_level >= 20


## Returns true if this suit has the level 40 normal fire upgrade.
func has_level_40_weapon_upgrade() -> bool:
	return current_level >= 40


## Returns true if this suit has the level 60 alt fire upgrade.
func has_level_60_weapon_upgrade() -> bool:
	return current_level >= 60


## Returns true if this suit has the level 80 normal fire upgrade.
func has_level_80_weapon_upgrade() -> bool:
	return current_level >= 80

## Returns the modifier id used for this suit's stat bonuses.
func get_suit_modifier_id() -> String:
	return "suit_%s" % str(Key)
