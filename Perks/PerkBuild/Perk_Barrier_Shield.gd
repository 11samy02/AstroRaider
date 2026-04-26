extends PerkBuild

const BARRIER_SHIELD := preload("res://Objects/Perk Specials/barrier_shield.tscn")


## Initializes cooldown timer for the shield
func _ready() -> void:
	super()
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)


## Connects to global signal for shield destruction
func _enter_tree() -> void:
	GSignals.PERK_barrier_shield_destroyed.connect(_on_shield_destroyed)


## Disconnects signal when node exits tree
func _exit_tree() -> void:
	if GSignals.PERK_barrier_shield_destroyed.is_connected(_on_shield_destroyed):
		GSignals.PERK_barrier_shield_destroyed.disconnect(_on_shield_destroyed)


## Spawns a barrier shield around the player
func activate_perk() -> void:
	if !selected_in_run :
		return
	var res := get_player_res()
	if !is_instance_valid(res):
		return
	if res.shield_res.has_shield or res.shield_res.on_cooldown:
		return

	res.shield_res.has_shield = true
	res.shield_res.on_cooldown = false

	var new_shield := BARRIER_SHIELD.instantiate()
	new_shield.entity = player
	new_shield.global_position = player.global_position
	new_shield.Health = get_value()
	player.get_parent().add_child(new_shield)


## Called when the shield is destroyed, starts cooldown
func _on_shield_destroyed() -> void:
	var res := get_player_res()
	if !is_instance_valid(res):
		return

	res.shield_res.has_shield = false
	res.shield_res.on_cooldown = true
	_cooldown_timer.start(get_cooldown())
	cooldown_started.emit(get_cooldown())


## Resets cooldown state when finished
func _on_cooldown_finished() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.shield_res.on_cooldown = false


## Returns true if shield is active or cooldown is running
func is_on_cooldown() -> bool:
	var res := get_player_res()
	if !is_instance_valid(res):
		return false
	if res.shield_res.has_shield:
		return true
	if res.shield_res.on_cooldown:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false
