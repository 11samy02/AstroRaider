extends PerkBuild

const BARRIER_SHIELD: PackedScene = preload("res://scenes/objects/perk_specials/barrier_shield.tscn")

const SHIELD_HP_PERCENT_BY_LEVEL: Array[float] = [
	0.35,
	0.45,
	0.55,
	0.65,
	0.80,
	1.00,
]


## Initializes cooldown timer for the shield.
func _ready() -> void:
	super()

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)


## Connects to global signal for shield destruction.
func _enter_tree() -> void:
	if not GSignals.PERK_barrier_shield_destroyed.is_connected(_on_shield_destroyed):
		GSignals.PERK_barrier_shield_destroyed.connect(_on_shield_destroyed)


## Disconnects signal when node exits tree.
func _exit_tree() -> void:
	if GSignals.PERK_barrier_shield_destroyed.is_connected(_on_shield_destroyed):
		GSignals.PERK_barrier_shield_destroyed.disconnect(_on_shield_destroyed)


## Spawns a barrier shield around the player.
func activate_perk() -> void:
	if not selected_in_run:
		return

	if not has_valid_runtime_refs():
		return

	var res := get_player_res()

	if not is_instance_valid(res):
		return

	if res.shield_res.has_shield or res.shield_res.on_cooldown:
		return

	res.shield_res.has_shield = true
	res.shield_res.on_cooldown = false

	var shield_health := _get_scaled_shield_health()
	
	var new_shield := BARRIER_SHIELD.instantiate() as BarrierShield
	new_shield.entity = player
	new_shield.global_position = player.global_position
	new_shield.Health = shield_health
	new_shield.MaxHealth = shield_health

	player.get_parent().add_child(new_shield)


## Returns shield health using hybrid scaling:
## fixed perk value OR percentage of suit-scaled max HP, whichever is higher.
func _get_scaled_shield_health() -> int:
	var minimum_health := int(get_value())
	var suit_scaled_max_hp := _get_suit_scaled_max_hp()
	var percent := _get_shield_hp_percent()
	var percent_health := int(round(suit_scaled_max_hp * percent))

	return maxi(minimum_health, percent_health)


## Returns the player's max HP from suit base + suit level bonus.
## Ignores perk HP modifiers.
func _get_suit_scaled_max_hp() -> float:
	var suit_modifier_id := get_selected_suit_modifier_id()

	if suit_modifier_id == "":
		return float(stats.max_hp)

	return stats.get_suit_scaled_max_hp(suit_modifier_id)


## Returns the shield HP percentage for the current perk level.
func _get_shield_hp_percent() -> float:
	var index := clampi(Level - 1, 0, SHIELD_HP_PERCENT_BY_LEVEL.size() - 1)
	return SHIELD_HP_PERCENT_BY_LEVEL[index]


## Called when the shield is destroyed, starts cooldown.
func _on_shield_destroyed() -> void:
	var res := get_player_res()

	if not is_instance_valid(res):
		return

	res.shield_res.has_shield = false
	res.shield_res.on_cooldown = true

	_cooldown_timer.start(get_cooldown())
	cooldown_started.emit(get_cooldown())


## Resets cooldown state when finished.
func _on_cooldown_finished() -> void:
	var res := get_player_res()

	if is_instance_valid(res):
		res.shield_res.on_cooldown = false


## Returns true if shield is active or cooldown is running.
func is_on_cooldown() -> bool:
	var res := get_player_res()

	if not is_instance_valid(res):
		return false

	if res.shield_res.has_shield:
		return true

	if res.shield_res.on_cooldown:
		return true

	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0

	return false
