extends Area2D
class_name PlayerHand

@export var player_res: PlayerResource
@export var max_distance: float = 500.0

@onready var building_placement: Node2D = $BuildingPlacement
@onready var building_sprite: Sprite2D = $BuildingPlacement/Sprite2D
@onready var check_ground: Area2D = $check_ground

@export var building_res : BluePrintResource = null

var can_place_building : bool = true
var building_list : Array[Area2D] = []


var velocity: Vector2 = Vector2.ZERO


func check_button_pressed() -> void:
	if player_res.player.current_state == player_res.player.states.Build:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			place_building()

func show_texture() -> void:
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
		show()
		movement(delta)
		enforce_max_distance()
		show_texture()
		check_button_pressed()
		select_building()
		can_place_building = _can_buy_building() and building_list.is_empty()
	else:
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

func enforce_max_distance() -> void:
	var offset = global_position - player_res.player.global_position
	if offset.length() > max_distance:
		global_position = player_res.player.global_position + offset.normalized() * max_distance


func place_building() -> void:
	if can_place_building and is_instance_valid(building_res):
		var building : Building = BluePrintData.load_Building_tres(building_res.Key).instantiate()
		
		building.global_position = building_placement.global_position
		get_parent().get_parent().add_child(building)
		_deduct_building_cost()
		
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

func select_building() -> void:
	if Input.is_key_pressed(KEY_1):
		building_res = BluePrintData.load_Building_res(BluePrintData.Keys.MetalGround)
		GSignals.UI_selected_blueprint.emit(building_res)
	elif Input.is_key_pressed(KEY_2):
		building_res = BluePrintData.load_Building_res(BluePrintData.Keys.Torrent)
		GSignals.UI_selected_blueprint.emit(building_res)
	elif Input.is_key_pressed(KEY_3):
		building_res = BluePrintData.load_Building_res(BluePrintData.Keys.RepairDroneStation)
		GSignals.UI_selected_blueprint.emit(building_res)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		building_res = null
		GSignals.UI_selected_blueprint.emit(building_res)


func _on_check_ground_area_entered(area: Area2D) -> void:
	building_list.append(area)


func _on_check_ground_area_exited(area: Area2D) -> void:
	building_list.erase(area)
