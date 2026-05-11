extends PerkBuild

var _collected_count := 0
var _shared_total := 0


## Connects the crystal collection signal and initializes the base perk data
func _ready() -> void:
	GSignals.PERK_event_collect_crystal.connect(_on_crystal_collected)
	super()


## Disconnects the crystal collection signal
func _exit_tree() -> void:
	if GSignals.PERK_event_collect_crystal.is_connected(_on_crystal_collected):
		GSignals.PERK_event_collect_crystal.disconnect(_on_crystal_collected)


## Shares a percentage of collected crystals with teammates
func _on_crystal_collected(_pos: Vector2) -> void:
	if !selected_in_run :
		return

	_collected_count += 1

	var total_share := int(floor(_collected_count / 100.0 * get_value()))
	var new_share := total_share - _shared_total

	if new_share <= 0:
		return

	_shared_total = total_share

	var res := get_player_res()
	if !is_instance_valid(res):
		return

	for p_res: PlayerResource in GlobalGame.Players:
		if p_res.player != res.player:
			p_res.crystal_count += new_share
