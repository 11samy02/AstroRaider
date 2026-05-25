extends HBoxContainer

signal slot_assigned

@onready var ability1: Control = $ability
@onready var ability2: Control = $ability2
@onready var ability3: Control = $ability3
@onready var ability4: Control = $ability4

@export var equip_text: Label

var slots: PerkSlots
var _slot_map: Dictionary = {}
var _pending_perk: PerkBuild = null
var _selecting := false
var _tween_map: Dictionary = {}
var _dialogic_open := false

func _ready() -> void:
	equip_text.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dialogic_open = Dialogic.current_timeline != null
	if not Dialogic.timeline_started.is_connected(_on_dialogic_timeline_started):
		Dialogic.timeline_started.connect(_on_dialogic_timeline_started)
	if not Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	await get_tree().process_frame
	_resolve_slots()
	_slot_map = {
		"C": ability1,
		"Q": ability2,
		"E": ability3,
		"X": ability4,
	}
	for key in _slot_map:
		var btn: Button = _slot_map[key].get_node("Button")
		btn.pressed.connect(_on_slot_clicked.bind(key))
	_refresh_all()
	_sync_dialogic_visibility()


func _exit_tree() -> void:
	if Dialogic.timeline_started.is_connected(_on_dialogic_timeline_started):
		Dialogic.timeline_started.disconnect(_on_dialogic_timeline_started)
	if Dialogic.timeline_ended.is_connected(_on_dialogic_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_dialogic_timeline_ended)

func _process(_delta: float) -> void:
	_sync_dialogic_visibility()
	if _dialogic_open:
		return

	if not _selecting:
		return
	if Input.is_action_just_pressed("slot_q") and slots.activation_slots["Q"] == null:
		_assign_pending("Q")
	if Input.is_action_just_pressed("slot_e") and slots.activation_slots["E"] == null:
		_assign_pending("E")
	if Input.is_action_just_pressed("slot_c") and slots.activation_slots["C"] == null:
		_assign_pending("C")


func _on_dialogic_timeline_started() -> void:
	_dialogic_open = true
	_sync_dialogic_visibility()


func _on_dialogic_timeline_ended() -> void:
	_dialogic_open = false
	_sync_dialogic_visibility()


func _sync_dialogic_visibility() -> void:
	_dialogic_open = GlobalGame.are_player_inputs_blocked()
	visible = not _dialogic_open


## Resolves PerkSlots from the first player in GlobalGame
func _resolve_slots() -> void:
	for player_res: PlayerResource in GlobalGame.Players:
		if is_instance_valid(player_res.player) and is_instance_valid(player_res.player.perk_manager):
			slots = player_res.player.perk_manager.slots
			break

## Called by PerkManager when an Activation perk needs a slot assigned
func begin_slot_selection(perk: PerkBuild) -> void:
	_pending_perk = perk
	_selecting = true
	_refresh_all()
	_start_pulse_on_free_slots()

## Called by PerkManager when an Ult perk is selected — auto assigns to X
func assign_ult(perk: PerkBuild) -> void:
	_set_slot_icon("X", perk.perk_res.image)

## Refreshes all slot visuals from current slots state
func _refresh_all() -> void:
	if not is_instance_valid(slots):
		return
	for key in _slot_map:
		if key == "X":
			if is_instance_valid(slots.ult_perk):
				_set_slot_icon("X", slots.ult_perk.perk_res.image)
			else:
				_set_slot_empty("X")
		else:
			var perk: PerkBuild = slots.activation_slots.get(key)
			if is_instance_valid(perk):
				_set_slot_icon(key, perk.perk_res.image)
			else:
				_set_slot_empty(key)

## Sets a slot to show a perk icon and stops pulse
func _set_slot_icon(key: String, image: Texture2D) -> void:
	var node: Control = _slot_map[key]
	var tex: TextureRect = node.get_node("Button/MarginContainer/TextureRect")
	tex.texture = image
	_stop_pulse(key)

## Sets a slot to empty state
func _set_slot_empty(key: String) -> void:
	var node: Control = _slot_map[key]
	var tex: TextureRect = node.get_node("Button/MarginContainer/TextureRect")
	tex.texture = null
	_stop_pulse(key)

## Starts pulse animation on all free activation slots
func _start_pulse_on_free_slots() -> void:
	for key in ["Q", "E", "C"]:
		if slots.activation_slots[key] == null:
			_start_pulse(key)

## Starts pulse tween on a slot button
func _start_pulse(key: String) -> void:
	equip_text.show()
	var btn: Button = _slot_map[key].get_node("Button")
	if _tween_map.has(key) and is_instance_valid(_tween_map[key]):
		_tween_map[key].kill()
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn, "modulate:a", 0.4, 0.5)
	tween.tween_property(btn, "modulate:a", 1.0, 0.5)
	_tween_map[key] = tween

## Stops pulse tween on a slot
func _stop_pulse(key: String) -> void:
	if _tween_map.has(key) and is_instance_valid(_tween_map[key]):
		_tween_map[key].kill()
		_tween_map.erase(key)
	var btn: Button = _slot_map[key].get_node("Button")
	btn.modulate.a = 1.0
	btn.scale = Vector2(1.0, 1.0)
	equip_text.hide()

## Called when a slot button is clicked
func _on_slot_clicked(key: String) -> void:
	if GlobalGame.are_player_inputs_blocked():
		return

	if _selecting:
		if key == "X":
			return
		if slots.activation_slots.get(key) != null:
			return
		_assign_pending(key)

## Assigns the pending perk to the given slot key
func _assign_pending(key: String) -> void:
	if not is_instance_valid(_pending_perk):
		return
	slots.assign_to_slot(key, _pending_perk)
	_pending_perk.assigned_slot = key
	_set_slot_icon(key, _pending_perk.perk_res.image)
	_pending_perk = null
	_selecting = false
	_stop_all_pulses()
	slot_assigned.emit()

## Stops all active pulse animations
func _stop_all_pulses() -> void:
	for key in ["Q", "E", "C"]:
		_stop_pulse(key)
