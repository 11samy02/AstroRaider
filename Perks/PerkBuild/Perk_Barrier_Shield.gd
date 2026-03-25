extends PerkBuild
const BARRIER_SHIELD := preload("res://Objects/Perk Specials/barrier_shield.tscn")


func _ready() -> void:
	super()
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)

func _enter_tree() -> void:
	GSignals.PERK_barrier_shield_destroyed.connect(_on_shield_destroyed)

func _exit_tree() -> void:
	if GSignals.PERK_barrier_shield_destroyed.is_connected(_on_shield_destroyed):
		GSignals.PERK_barrier_shield_destroyed.disconnect(_on_shield_destroyed)

## Activation: spawns a barrier shield around the player
func activate_perk() -> void:
	if !has_unlocked:
		return
	var res := get_player_res()
	if !is_instance_valid(res):
		return
	if res.shield_res.has_shield or res.shield_res.on_cooldown:
		return

	res.shield_res.has_shield = true
	res.shield_res.on_cooldown = true

	var new_shield := BARRIER_SHIELD.instantiate()
	new_shield.entity = player
	new_shield.global_position = player.global_position
	new_shield.Health = get_value()
	player.get_parent().add_child(new_shield)

## Called when shield is destroyed — starts cooldown
func _on_shield_destroyed() -> void:
	var res := get_player_res()
	print("shield destroyed, emitting cooldown_started with: ", get_cooldown())
	if !is_instance_valid(res):
		return
	res.shield_res.has_shield = false
	res.shield_res.on_cooldown = false
	cooldown_started.emit(get_cooldown())

## Called when cooldown finishes — ready to use again
func _on_cooldown_finished() -> void:
	var res := get_player_res()
	print("Cooldown finished, res valid: ", is_instance_valid(res))
	if is_instance_valid(res):
		res.shield_res.on_cooldown = false
		print("on_cooldown set to false")

## Returns true if shield is active or cooldown bar is still running
func is_on_cooldown() -> bool:
	var res := get_player_res()
	if !is_instance_valid(res):
		return false
	if res.shield_res.has_shield:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false
