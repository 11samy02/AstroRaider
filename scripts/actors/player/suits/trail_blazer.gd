extends SuitMechanics

const PHOTON_GUN := ItemConfig.Keys.Photon_Gun
const ALT_SHOT_MIN_SUIT_LEVEL := 20
const NORMAL_DOUBLE_SHOT_LEVEL := 40
const ALT_FIVE_SHOT_LEVEL := 60
const NORMAL_TRIPLE_SHOT_LEVEL := 80
const MAX_CHARGE_TIME := 1.0
const MIN_CHARGE_TIME := 0.15

@export_category("Weapon Resource")
@export var item_key: ItemConfig.Keys = PHOTON_GUN

@export_category("Normal Fire")
@export var normal_shot_spacing := 8.0

@export_category("Alt Fire")
@export var alt_shot_spacing := 6.0
@export var alt_3_shot_spread_angle := 14.0
@export var alt_5_shot_spread_angle := 11.0

@export_category("Charge Visuals")
@export var base_aim_sprite_scale := Vector2(0.5, 0.5)
@export var max_charge_aim_sprite_scale := Vector2(0.85, 0.85)

var holding_item: HoldingItem
var had_shoot := false
var _is_charging := false
var _charge_time := 0.0

@onready var aim_sprite: Sprite2D = $sprite
@onready var shoot_sound: Audio2D = $ShootSound


## Sets this mechanics node to Trailblazer and loads its weapon resource.
func _ready() -> void:
	suit_key = SuitData.SuitKeys.Trailblazer
	_load_item()


## Resets charge, shooting state, and visuals when the Trailblazer mechanics are disabled.
func _on_deactivated() -> void:
	_is_charging = false
	_charge_time = 0.0
	had_shoot = false

	if is_instance_valid(aim_sprite):
		aim_sprite.scale = base_aim_sprite_scale


## Loads the configured weapon resource from ItemConfig.
func _load_item() -> void:
	holding_item = ItemConfig.get_item_resource(item_key)


## Updates aiming, charging, visibility, and alt-fire input while this suit is active.
func _process(delta: float) -> void:
	if not is_active or holding_item == null:
		return

	if holding_item.type != ItemConfig.Type.Ranged_Weapon:
		hide()
		return

	show()
	_update_aim(delta)
	_update_charge(delta)

	if player.current_state == player.states.Default and _can_use_alt_shot():
		_update_alt_charge_input()


## Handles primary fire input while the suit is active and the player can shoot.
func _input(_event: InputEvent) -> void:
	if not is_active or player.current_state != player.states.Default:
		return

	if holding_item == null or holding_item.type != ItemConfig.Type.Ranged_Weapon:
		return

	_handle_primary_shot_input()


## Rotates the weapon toward mouse aim or controller right-stick aim.
func _update_aim(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		look_at(get_global_mouse_position())
	else:
		var target_rotation := _get_input_axis()

		if target_rotation != Vector2.ZERO:
			rotation = lerp_angle(
				rotation,
				target_rotation.angle(),
				player.stats.get_rotation_speed_total() * delta
			)


## Increases charge time and scales the aim sprite while alt fire is charging.
func _update_charge(delta: float) -> void:
	if not _is_charging:
		return

	_charge_time = minf(_charge_time + delta, MAX_CHARGE_TIME)
	var charge_ratio := _charge_time / MAX_CHARGE_TIME
	aim_sprite.scale = base_aim_sprite_scale.lerp(max_charge_aim_sprite_scale, charge_ratio)


## Starts a normal weapon shot when primary fire is pressed and the fire delay is ready.
func _handle_primary_shot_input() -> void:
	if _is_charging or _is_alt_fire_pressed():
		return
	
	if not (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or Input.get_joy_axis(player.controller_id, JOY_AXIS_TRIGGER_RIGHT) > 0.0
		or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_RIGHT_SHOULDER)
	):
		return
	
	if had_shoot:
		return
	
	had_shoot = true
	shoot()


## Starts, holds, or releases the alt-fire charge input.
func _update_alt_charge_input() -> void:
	if had_shoot:
		return
	
	var alt_pressed := _is_alt_fire_pressed()
	
	if alt_pressed:
		if not _is_charging:
			_is_charging = true
			_charge_time = 0.0
	elif _is_charging:
		_release_charged_shot()


## Returns true when mouse or controller alt-fire input is pressed.
func _is_alt_fire_pressed() -> bool:
	return (
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		or Input.get_joy_axis(player.controller_id, JOY_AXIS_TRIGGER_LEFT) > 0.0
		or Input.is_joy_button_pressed(player.controller_id, JOY_BUTTON_LEFT_SHOULDER)
	)


## Releases the charged shot if the minimum charge time was reached.
func _release_charged_shot() -> void:
	if not _is_charging:
		return

	_is_charging = false
	aim_sprite.scale = base_aim_sprite_scale

	if _charge_time < MIN_CHARGE_TIME:
		_charge_time = 0.0
		return

	_fire_charged_burst()
	_charge_time = 0.0


## Returns true when the selected suit has reached the required level for alt fire.
func _can_use_alt_shot() -> bool:
	var suit := get_suit_data()
	return is_instance_valid(suit) and suit.has_unlocked and suit.current_level >= ALT_SHOT_MIN_SUIT_LEVEL


## Returns the current selected suit level or 1 when no valid suit data exists.
func _get_suit_level() -> int:
	var suit := get_suit_data()

	if not is_instance_valid(suit) or not suit.has_unlocked:
		return 1

	return suit.current_level


## Returns the amount of normal-fire projectiles based on Trailblazer suit level.
func _get_normal_projectile_count() -> int:
	var suit_level := _get_suit_level()

	if suit_level >= NORMAL_TRIPLE_SHOT_LEVEL:
		return 3

	if suit_level >= NORMAL_DOUBLE_SHOT_LEVEL:
		return 2

	return 1


## Returns the amount of alt-fire burst projectiles based on Trailblazer suit level.
func _get_alt_projectile_count() -> int:
	var suit_level := _get_suit_level()

	if suit_level >= ALT_FIVE_SHOT_LEVEL:
		return 5

	return 3


## Returns the alt-fire spread angle based on Trailblazer suit level.
func _get_alt_spread_angle() -> float:
	var suit_level := _get_suit_level()

	if suit_level >= ALT_FIVE_SHOT_LEVEL:
		return alt_5_shot_spread_angle

	return alt_3_shot_spread_angle


## Returns the controller aiming direction from the right stick.
func _get_input_axis() -> Vector2:
	var input_axis := Vector2.ZERO

	if abs(Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_X)) > 0.1:
		input_axis.x = Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_X)

	if abs(Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_Y)) > 0.1:
		input_axis.y = Input.get_joy_axis(player.controller_id, JOY_AXIS_RIGHT_Y)

	return input_axis.normalized()


## Returns the current shooting direction from player position to aim sprite position.
func _get_shoot_direction() -> Vector2:
	return (aim_sprite.global_position - player.global_position).normalized()


## Fires the normal weapon pattern based on the current Trailblazer suit level.
func shoot() -> void:
	var shoot_dir := _get_shoot_direction()
	var count := _get_normal_projectile_count()

	_fire_straight_projectile_line(shoot_dir, count, normal_shot_spacing)

	shoot_sound.play_sound()

	await get_tree().create_timer(player.stats.get_attack_speed_total()).timeout

	had_shoot = false
	GSignals.PLA_is_shooting.emit(player)


## Fires the charged alt-fire burst based on the current Trailblazer suit level.
func _fire_charged_burst() -> void:
	var shoot_dir := _get_shoot_direction()
	var count := _get_alt_projectile_count()
	var spread_angle := _get_alt_spread_angle()

	_fire_spread_projectiles(shoot_dir, count, spread_angle, alt_shot_spacing)

	shoot_sound.play_sound()
	GSignals.PLA_is_shooting.emit(player)


## Fires multiple projectiles in parallel with sideways spawn spacing.
func _fire_straight_projectile_line(direction: Vector2, count: int, spacing: float) -> void:
	var spread_axis := direction.orthogonal()
	var center_offset := float(count - 1) * 0.5

	for i in range(count):
		var spawn_offset := spread_axis * (float(i) - center_offset) * spacing
		_spawn_projectile(direction, spawn_offset)


## Fires multiple projectiles with angular spread and sideways spawn spacing.
func _fire_spread_projectiles(direction: Vector2, count: int, angle_step_degrees: float, spacing: float) -> void:
	var spread_axis := direction.orthogonal()
	var center_offset := float(count - 1) * 0.5

	for i in range(count):
		var index_offset := float(i) - center_offset
		var shot_dir := direction.rotated(deg_to_rad(index_offset * angle_step_degrees)).normalized()
		var spawn_offset := spread_axis * index_offset * spacing

		_spawn_projectile(shot_dir, spawn_offset)


## Spawns one projectile with the given direction and local spawn offset.
func _spawn_projectile(direction: Vector2, spawn_offset: Vector2 = Vector2.ZERO) -> void:
	var projectile: PlayerProjectile = ItemConfig.get_item_scene(holding_item.key).instantiate()
	
	projectile.dir = direction
	projectile.global_position = player.global_position + spawn_offset
	projectile.player = player
	
	player.get_parent().add_child(projectile)
