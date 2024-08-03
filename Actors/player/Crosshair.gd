extends Node2D

@export var player: Player

@export var item_key : ItemConfig.Keys

var holding_item : HoldingItem

@onready var sprite: Sprite2D = $sprite

var had_shoot := false

func _ready() -> void:
	_load_item()


func _load_item() -> void:
	if item_key != null:
		holding_item = ItemConfig.get_item_resource(item_key)


func _process(delta: float) -> void:
	if holding_item == null:
		return
	
	if holding_item.type == ItemConfig.Type.Ranged_Weapon:
		show()
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			look_at(get_global_mouse_position())
		else:
			var target_rotation = get_input_axis()
			if target_rotation != Vector2.ZERO:
				rotation = lerp_angle(rotation, target_rotation.angle(), player.stats.rotation_speed * delta)
		
	else:
		hide()


func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(player.player_id ,JOY_BUTTON_RIGHT_SHOULDER):
		if !had_shoot:
			if holding_item != null:
				if holding_item.type == ItemConfig.Type.Ranged_Weapon:
					had_shoot = true
					shoot()

func get_input_axis() -> Vector2:
	var input_axis: Vector2
	if abs(Input.get_joy_axis(player.player_id,JOY_AXIS_RIGHT_X)) > 0.1:
		input_axis.x = Input.get_joy_axis(player.player_id,JOY_AXIS_RIGHT_X)
	if abs(Input.get_joy_axis(player.player_id,JOY_AXIS_RIGHT_Y)) > 0.1:
		input_axis.y = Input.get_joy_axis(player.player_id,JOY_AXIS_RIGHT_Y)
	return input_axis.normalized()

func shoot():
	var projectile: PlayerProjectile = ItemConfig.get_item_scene(holding_item.key).instantiate()
	projectile.dir = (sprite.global_position - player.global_position).normalized()
	projectile.global_position = player.global_position
	projectile.parent = player
	get_parent().get_parent().add_child(projectile)
	await (get_tree().create_timer(0.2).timeout)
	had_shoot = false
