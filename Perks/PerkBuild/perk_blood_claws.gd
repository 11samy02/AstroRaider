extends PerkBuild

const CLAW_SCENE := preload("res://Objects/Perk Specials/claw.tscn")
const BLOOD_CLAWS_NODE_NAME := "BloodClaws"

@export var reach_per_level: Array[float] = [55.0, 58.0, 62.0, 66.0, 70.0, 75.0]
@export var lunge_reach_per_level: Array[float] = [40.0, 45.0, 50.0, 55.0, 60.0, 70.0]
@export var strike_damage_per_level: Array[int] = [8, 11, 14, 18, 22, 28]

var _claws_root: Node2D = null
var _duration_timer: Timer = null
var _is_active := false
var _is_despawning := false
var _pending_claw_despawns := 0
var _emit_cooldown_after_despawn := false


func _ready() -> void:
	super()
	_duration_timer = Timer.new()
	_duration_timer.one_shot = true
	_duration_timer.timeout.connect(_on_duration_ended)
	add_child(_duration_timer)


func activate_perk() -> void:
	if not has_unlocked or _is_active or _is_despawning or is_on_cooldown():
		return
	if not is_instance_valid(player):
		return

	_emit_cooldown_after_despawn = false

	if is_instance_valid(_duration_timer):
		_duration_timer.stop()

	_spawn_claws()
	if not is_instance_valid(_claws_root):
		return

	_is_active = true
	_duration_timer.start(get_duration())

	if is_instance_valid(ability_slot_ref):
		ability_slot_ref.show_active(get_cooldown())


func _on_duration_ended() -> void:
	_is_active = false
	_emit_cooldown_after_despawn = true
	_despawn_claws(false)


func _reset_stats() -> void:
	_is_active = false
	_is_despawning = false
	_emit_cooldown_after_despawn = false

	if is_instance_valid(_duration_timer):
		_duration_timer.stop()

	_despawn_claws(true)


func is_on_cooldown() -> bool:
	if _is_active or _is_despawning:
		return true
	if is_instance_valid(ability_slot_ref):
		return ability_slot_ref.cooldown.value > 0.0
	return false


func _spawn_claws() -> void:
	_emit_cooldown_after_despawn = false
	_despawn_claws(true)

	var scene_root := get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	var count: int = max(1, get_value())
	var reach_idx := clampi(Level - 1, 0, reach_per_level.size() - 1)
	var lunge_idx := clampi(Level - 1, 0, lunge_reach_per_level.size() - 1)
	var dmg_idx := clampi(Level - 1, 0, strike_damage_per_level.size() - 1)

	var reach: float = reach_per_level[reach_idx]
	var lunge: float = lunge_reach_per_level[lunge_idx]
	var dmg: int = strike_damage_per_level[dmg_idx]

	_claws_root = Node2D.new()
	_claws_root.name = BLOOD_CLAWS_NODE_NAME
	scene_root.add_child(_claws_root)

	for i in range(count):
		var claw: Node2D = CLAW_SCENE.instantiate()
		_claws_root.add_child(claw)

		var angle_offset := (TAU / float(count)) * float(i)
		claw.setup(angle_offset, reach, lunge, dmg, player)


func _despawn_claws(instant: bool = false) -> void:
	if not is_instance_valid(_claws_root):
		_claws_root = null
		_is_despawning = false
		_pending_claw_despawns = 0

		if _emit_cooldown_after_despawn and not instant:
			_emit_cooldown_after_despawn = false
			cooldown_started.emit(get_cooldown())
		return

	if instant:
		_is_despawning = false
		_pending_claw_despawns = 0
		_claws_root.queue_free()
		_claws_root = null
		return

	_is_despawning = true
	_pending_claw_despawns = 0

	for child in _claws_root.get_children():
		if child.has_method("begin_despawn") and child.has_signal("despawn_finished"):
			_pending_claw_despawns += 1
			child.connect("despawn_finished", Callable(self, "_on_claw_despawn_finished"), CONNECT_ONE_SHOT)
			child.call("begin_despawn")
		else:
			child.queue_free()

	if _pending_claw_despawns == 0:
		_finish_claw_root_cleanup()


func _on_claw_despawn_finished(_claw: Node2D) -> void:
	_pending_claw_despawns = max(0, _pending_claw_despawns - 1)

	if _pending_claw_despawns == 0:
		_finish_claw_root_cleanup()


func _finish_claw_root_cleanup() -> void:
	if is_instance_valid(_claws_root):
		_claws_root.queue_free()

	_claws_root = null
	_is_despawning = false
	_pending_claw_despawns = 0

	if _emit_cooldown_after_despawn:
		_emit_cooldown_after_despawn = false
		cooldown_started.emit(get_cooldown())
