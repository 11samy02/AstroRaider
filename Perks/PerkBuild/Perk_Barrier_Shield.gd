extends PerkBuild

const BARRIER_SHIELD := preload("res://Objects/Perk Specials/barrier_shield.tscn")

func _ready() -> void:
	super()

## Activation: spawns a barrier shield around the player
func _enter_tree() -> void:
	GSignals.PERK_barrier_shield_destroyed.connect(_on_shield_destroyed)
	GSignals.WAV_wave_endet.connect(_on_wave_ended)

func _exit_tree() -> void:
	if GSignals.PERK_barrier_shield_destroyed.is_connected(_on_shield_destroyed):
		GSignals.PERK_barrier_shield_destroyed.disconnect(_on_shield_destroyed)
	if GSignals.WAV_wave_endet.is_connected(_on_wave_ended):
		GSignals.WAV_wave_endet.disconnect(_on_wave_ended)

func activate_perk() -> void:
	if !has_unlocked:
		return
	var res := get_player_res()
	if !is_instance_valid(res):
		return
	if res.shield_res.has_shield or res.shield_res.used_shield_in_round:
		return
	res.shield_res.has_shield = true
	res.shield_res.used_shield_in_round = true
	var new_shield := BARRIER_SHIELD.instantiate()
	new_shield.entity = player
	new_shield.global_position = player.global_position
	new_shield.Health = get_value()
	player.get_parent().add_child(new_shield)

func _on_shield_destroyed() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.shield_res.has_shield = false

func _on_wave_ended() -> void:
	var res := get_player_res()
	if is_instance_valid(res):
		res.shield_res.used_shield_in_round = false
