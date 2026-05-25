extends Area2D
class_name PlayerHand

@export var player_res: PlayerResource
@export var max_distance: float = 500.0

@onready var building_placement: Node2D = $BuildingPlacement
@onready var building_sprite: Sprite2D = $BuildingPlacement/Sprite2D
@onready var check_ground: Area2D = $check_ground
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var building_res : BluePrintResource = null

var can_place_building : bool = true
var building_list : Array[Area2D] = []
var place_building_is_locked : bool = false

var delete_mode : bool = false
var hovered_salvage_building: Building = null

var velocity: Vector2 = Vector2.ZERO
var _prev_rmb: bool = false
var _prev_lmb: bool = false
var _prev_joy_delete: bool = false
const HAND_FRAME_DEFAULT := 0
const HAND_FRAME_DELETE := 4

func _enter_tree() -> void:
	GSignals.BUI_BUILDING_select_building.connect(select_building)
	GSignals.BUI_allow_to_place.connect(set_place_building_locked)

func check_button_pressed(lmb: bool) -> void:
	if player_res.player.current_state == player_res.player.states.Build:
		if delete_mode:
			return
		if lmb and not _prev_lmb and !place_building_is_locked:
			place_building()

func show_texture() -> void:
	if delete_mode:
		building_sprite.texture = null
		return
	if is_instance_valid(building_res):
		if can_place_building:
			building_sprite.modulate = Color("#00ff0096")
		else:
			building_sprite.modulate = Color("#ff867996")
		building_sprite.texture = building_res.texture
	else:
		building_sprite.texture = null

func _process(delta: float) -> void:
	if player_res.player.current_state == player_res.player.states.Build:
		var cursor_allowed := GlobalGame.is_tutorial_action_allowed("build_cursor")
		if GlobalGame.are_player_inputs_blocked() or not cursor_allowed:
			_sync_blocked_button_state()
			velocity = Vector2.ZERO
			can_place_building = false
			show()
			if cursor_allowed:
				enforce_max_distance()
				show_texture()
			else:
				building_sprite.texture = null
			_apply_hand_sprite_frame()
			_update_salvage_hover()
			return

		var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if delete_mode and not GlobalGame.is_tutorial_action_allowed("salvage_building"):
			delete_mode = false
		if rmb and not _prev_rmb and GlobalGame.is_tutorial_action_allowed("salvage_building"):
			_toggle_delete_mode()
		var player: Player = player_res.player
		var joy_delete := false
		if Input.get_connected_joypads().size() > 0:
			joy_delete = Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_B)
		if joy_delete and not _prev_joy_delete and GlobalGame.is_tutorial_action_allowed("salvage_building"):
			_toggle_delete_mode()
		_prev_joy_delete = joy_delete

		show()
		movement(delta)
		enforce_max_distance()
		show_texture()
		_apply_hand_sprite_frame()
		_update_salvage_hover()
		var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if delete_mode:
			if lmb and not _prev_lmb and not place_building_is_locked:
				_try_salvage_under_hand()
		else:
			check_button_pressed(lmb)
		_prev_rmb = rmb
		_prev_lmb = lmb
		can_place_building = _can_buy_building() and building_list.is_empty() and _can_place_current_blueprint_in_tutorial()
	else:
		delete_mode = false
		_prev_rmb = false
		_prev_lmb = false
		_prev_joy_delete = false

		if is_instance_valid(hovered_salvage_building):
			hovered_salvage_building.set_salvage_hover(false)
		hovered_salvage_building = null

		hide()
		global_position = player_res.player.global_position + Vector2(0, -25)

func movement(delta: float) -> void:
	var acceleration := 2000.0
	var max_speed := 200.0
	var friction := 4000.0
	var input_dir = Vector2.ZERO
	var player : Player = player_res.player
	
	if player.controller_id == 0 and Input.get_connected_joypads().size() == 0:
		input_dir = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
	else:
		var axis_x = Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_X)
		var axis_y = Input.get_joy_axis(player.controller_id, JOY_AXIS_LEFT_Y)
		input_dir = Vector2(axis_x, axis_y)
		if input_dir.length() < player.deadzone:
			input_dir = Vector2.ZERO
		else:
			input_dir = input_dir.normalized()
	
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	translate(velocity * delta)
	
	
	building_placement.global_position = global_position.snapped(Vector2(16, 16))
	check_ground.global_position = global_position.snapped(Vector2(16, 16))


func _sync_blocked_button_state() -> void:
	_prev_rmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	_prev_lmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	var player: Player = player_res.player
	if Input.get_connected_joypads().size() > 0:
		_prev_joy_delete = Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_B)
	else:
		_prev_joy_delete = false

func enforce_max_distance() -> void:
	var offset = global_position - player_res.player.global_position
	if offset.length() > max_distance:
		global_position = player_res.player.global_position + offset.normalized() * max_distance


func place_building() -> void:
	if not _can_place_current_blueprint_in_tutorial():
		return

	if can_place_building and is_instance_valid(building_res):
		var building : Building = BluePrintData.load_Building_tres(building_res.Key).instantiate()
		var placed_key := building_res.Key
		
		building.global_position = building_placement.global_position
		building.can_salvage_refund = true
		building.salvage_blueprint_key = building_res.Key
		get_parent().get_parent().add_child(building)
		_deduct_building_cost()
		GSignals.TUT_building_placed.emit(player_res.player, building, placed_key)
		
		var old_building_res : BluePrintResource = building_res.duplicate()
		
		building_res = null



func _can_buy_building() -> bool:
	if building_res != null:
		var can_buy = false
		if building_res.cost.is_empty():
			can_buy = true
		for ore: BluePrintCostResource in building_res.cost:
			var first_ore = OreTemplate.Ores.keys()[ore.Ore] 
			for ore_2 in player_res.Ores:
				var second_ore = ore_2
				if first_ore == second_ore:
					if ore.cost <= player_res.Ores[ore_2]:
						can_buy = true
					else:
						can_buy = false
						return false
		return can_buy
	return false

func _deduct_building_cost() -> void:
	if building_res != null:
		for ore: BluePrintCostResource in building_res.cost:
			var first_ore = OreTemplate.Ores.keys()[ore.Ore] 
			if player_res.Ores.has(first_ore):
				player_res.Ores[first_ore] -= ore.cost

func select_building(key: BluePrintData.Keys) -> void:
	if GlobalGame.are_player_inputs_blocked():
		return
	if not _can_select_blueprint_in_tutorial(key):
		return

	delete_mode = false
	_apply_hand_sprite_frame()
	if is_instance_valid(building_res):
		if building_res.Key == BluePrintData.Keys.Generator:
			return
	
	building_res = BluePrintData.load_Building_res(key)
	GSignals.UI_selected_blueprint.emit(building_res)


func _apply_hand_sprite_frame() -> void:
	if not is_instance_valid(sprite_2d):
		return
	var f := HAND_FRAME_DELETE if delete_mode else HAND_FRAME_DEFAULT
	sprite_2d.frame = clampi(f, 0, maxi(sprite_2d.hframes * sprite_2d.vframes - 1, 0))


func _toggle_delete_mode() -> void:
	if not GlobalGame.is_tutorial_action_allowed("salvage_building"):
		return

	delete_mode = !delete_mode

	if delete_mode:
		building_res = null
		GSignals.BUI_hide_resource_cost.emit()
	else:
		if is_instance_valid(hovered_salvage_building):
			hovered_salvage_building.set_salvage_hover(false)
		hovered_salvage_building = null

	_apply_hand_sprite_frame()


func _building_from_overlap(area: Area2D) -> Building:
	if area == null or area.name != "BuildingPlacedColl":
		return null
	var p := area.get_parent()
	return p as Building


func _get_buildings_under_hand() -> Array[Building]:
	var out: Array[Building] = []
	var seen: Dictionary = {}
	for a in building_list:
		var b := _building_from_overlap(a)
		if b != null and not seen.has(b):
			seen[b] = true
			out.append(b)
	return out


func _salvage_refund_fraction(building: Building) -> float:
	if not building.has_health or building.max_health <= 0:
		return 1.0
	var h := clampf(float(building.current_health) / float(building.max_health), 0.0, 1.0)
	if h < 0.1:
		return 0.0
	return (h - 0.1) / 0.9


func _refund_salvage_to_player(building: Building) -> void:
	if not building.can_salvage_refund:
		return
	var bp := BluePrintData.load_Building_res(building.salvage_blueprint_key)
	if bp == null:
		return
	var mult := _salvage_refund_fraction(building)
	if mult <= 0.0:
		return
	for ore: BluePrintCostResource in bp.cost:
		var ore_key = OreTemplate.Ores.keys()[ore.Ore]
		var add_amt := int(ceil(float(ore.cost) * mult))
		if add_amt <= 0:
			continue
		if player_res.Ores.has(ore_key):
			player_res.Ores[ore_key] += add_amt
		else:
			player_res.Ores[ore_key] = add_amt


func _try_salvage_under_hand() -> void:
	if not GlobalGame.is_tutorial_action_allowed("salvage_building"):
		return

	var candidates := _get_buildings_under_hand()
	if candidates.is_empty():
		return
	var best: Building = null
	var best_d2 := INF
	var pt := building_placement.global_position
	for b in candidates:
		if _is_generator_building(b):
			continue
		var d2 := pt.distance_squared_to(b.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = b
	if best == null:
		return
	_refund_salvage_to_player(best)

	if is_instance_valid(best):
		best.set_salvage_hover(false)

	if hovered_salvage_building == best:
		hovered_salvage_building = null

	var salvaged_key := best.salvage_blueprint_key
	best.queue_free()
	GSignals.TUT_building_salvaged.emit(player_res.player, salvaged_key)


func _is_generator_building(b: Building) -> bool:
	if b is CrystalGenerator:
		return true
	return b.can_salvage_refund and b.salvage_blueprint_key == BluePrintData.Keys.Generator


func _can_select_blueprint_in_tutorial(key: BluePrintData.Keys) -> bool:
	if key == BluePrintData.Keys.Generator:
		return (
			GlobalGame.is_tutorial_action_allowed("select_generator")
			or GlobalGame.is_tutorial_action_allowed("place_generator")
		)

	return GlobalGame.is_tutorial_action_allowed("select_building")


func _can_place_current_blueprint_in_tutorial() -> bool:
	if not is_instance_valid(building_res):
		return false

	if building_res.Key == BluePrintData.Keys.Generator:
		return GlobalGame.is_tutorial_action_allowed("place_generator")

	return GlobalGame.is_tutorial_action_allowed("place_building")



func _on_check_ground_area_entered(area: Area2D) -> void:
	building_list.append(area)


func _on_check_ground_area_exited(area: Area2D) -> void:
	building_list.erase(area)

func set_place_building_locked(value : bool) -> void:
	place_building_is_locked = value

func _update_salvage_hover() -> void:
	var new_hover: Building = null

	var candidates := _get_buildings_under_hand()
	var best_d2 := INF
	var pt := building_placement.global_position

	for b in candidates:
		if delete_mode and _is_generator_building(b):
			continue

		var d2 := pt.distance_squared_to(b.global_position)
		if d2 < best_d2:
			best_d2 = d2
			new_hover = b

	if hovered_salvage_building != new_hover:
		if is_instance_valid(hovered_salvage_building):
			hovered_salvage_building.set_building_hover(false)

		hovered_salvage_building = new_hover

		if is_instance_valid(hovered_salvage_building):
			hovered_salvage_building.set_building_hover(true)
