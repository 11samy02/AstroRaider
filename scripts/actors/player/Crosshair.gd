extends Node2D

@export var player: Player
@export var item_key: ItemConfig.Keys

var holding_item: HoldingItem
var had_shoot := false

@onready var sprite: Sprite2D = $sprite
@onready var shoot_sound: Audio2D = $ShootSound


## Loads the currently assigned item resource
func _ready() -> void:
	_load_item()


## Resolves the item resource from the configured item key
func _load_item() -> void:
	if item_key != null:
		holding_item = ItemConfig.get_item_resource(item_key)


## Updates weapon visibility and aiming behavior
func _process(delta: float) -> void:
	if holding_item == null:
		return

	if holding_item.type == ItemConfig.Type.Ranged_Weapon:
		show()

		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			look_at(get_global_mouse_position())
		else:
			var target_rotation := get_input_axis()
			if target_rotation != Vector2.ZERO:
				rotation = lerp_angle(rotation, target_rotation.angle(), player.stats.get_rotation_speed_total() * delta)
	else:
		hide()


## Handles shoot input while the player is in the default state
func _input(_event: InputEvent) -> void:
	if player.current_state == player.states.Default:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.get_joy_axis(player.controller_id, JOY_AXIS_TRIGGER_RIGHT) > 0 \
		or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_RIGHT_SHOULDER):
			if !had_shoot:
				if holding_item != null and holding_item.type == ItemConfig.Type.Ranged_Weapon:
					had_shoot = true
					shoot()


## Returns the normalized right stick input direction
func get_input_axis() -> Vector2:
	var input_axis := Vector2.ZERO

	if abs(Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_X)) > 0.1:
		input_axis.x = Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_X)

	if abs(Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_Y)) > 0.1:
		input_axis.y = Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_Y)

	return input_axis.normalized()


## Spawns and launches a projectile from the current weapon
func shoot() -> void:
	var projectile: PlayerProjectile = ItemConfig.get_item_scene(holding_item.key).instantiate()

	projectile.dir = (sprite.global_position - player.global_position).normalized()
	projectile.global_position = player.global_position
	projectile.player = player

	get_parent().get_parent().add_child(projectile)

	shoot_sound.play_sound()

	await get_tree().create_timer(player.stats.get_attack_speed_total()).timeout
	had_shoot = false

	GSignals.PLA_is_shooting.emit(player)
