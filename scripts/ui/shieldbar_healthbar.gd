extends TextureProgressBar
class_name ShieldBar

@export var game_ui: GameUi
@export var chip_bar: TextureProgressBar
@export var shield_label: Label

@export_range(0, 1, 0.01) var diff_ratio_percentage := 0.08

@onready var bar: TextureProgressBar = self

var player_res: PlayerResource = null
var current_shield := 0
var max_shield := 0


func _enter_tree() -> void:
	if not GSignals.PERK_barrier_shield_changed.is_connected(_on_shield_changed):
		GSignals.PERK_barrier_shield_changed.connect(_on_shield_changed)


func _exit_tree() -> void:
	if GSignals.PERK_barrier_shield_changed.is_connected(_on_shield_changed):
		GSignals.PERK_barrier_shield_changed.disconnect(_on_shield_changed)


func _ready() -> void:
	visible = false

	if is_instance_valid(chip_bar):
		chip_bar.visible = false

	if is_instance_valid(shield_label):
		shield_label.visible = false

	await game_ui.ready
	call_deferred("setup_player_res")


func _process(_delta: float) -> void:
	if player_res == null:
		setup_player_res()
		return

	_sync_max_value()
	_update_visibility()
	_set_shield_label_text()


## Resolves the player resource from the game UI player reference
func setup_player_res() -> void:
	if game_ui == null or game_ui.player == null or GlobalGame.Players.is_empty():
		return

	for p_res: PlayerResource in GlobalGame.Players:
		if p_res.player == game_ui.player:
			player_res = p_res
			_sync_max_value()
			value = current_shield

			if is_instance_valid(chip_bar):
				chip_bar.max_value = max_value
				chip_bar.value = current_shield

			_update_visibility()
			return


## ShieldBar max value should always be the player's max health
func _sync_max_value() -> void:
	if player_res == null or game_ui == null or game_ui.player == null:
		return

	if game_ui.player is not Player:
		return

	var player_max_hp := game_ui.player.stats.get_max_hp_total()

	max_value = player_max_hp

	if is_instance_valid(chip_bar):
		chip_bar.max_value = player_max_hp


## Receives shield updates from BarrierShield
func _on_shield_changed(player: Player, new_current_shield: int, new_max_shield: int) -> void:
	if game_ui == null or player != game_ui.player:
		return

	var old_shield := current_shield

	current_shield = maxi(new_current_shield, 0)
	max_shield = maxi(new_max_shield, 0)

	_sync_max_value()

	value = current_shield

	if is_instance_valid(chip_bar):
		var diff := old_shield - current_shield

		if diff > 0:
			var diff_ratio := 0.0

			if max_value > 0:
				diff_ratio = float(diff) / float(max_value)

			_animate_chip(current_shield, diff_ratio)
		else:
			chip_bar.value = current_shield

	_update_visibility()
	_set_shield_label_text()

	if old_shield > current_shield:
		hit_flash()


## Animates the chip bar after shield damage
func _animate_chip(target: int, diff_ratio: float) -> void:
	if not is_instance_valid(chip_bar):
		return

	chip_bar.value = max(float(chip_bar.value), float(current_shield + (max_value * diff_ratio)))

	var dur = lerp(0.18, 0.42, clamp(diff_ratio * 1.4, 0.0, 1.0))

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUINT)
	t.set_ease(Tween.EASE_OUT)
	t.tween_interval(0.15)
	t.tween_property(chip_bar, "value", float(target), dur)


## Short hit flash on the shield bar
func hit_flash() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.04)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.10)


## Shows shield UI only while shield value is above 0
func _update_visibility() -> void:
	var has_visible_shield := current_shield > 0

	visible = has_visible_shield

	if is_instance_valid(chip_bar):
		chip_bar.visible = has_visible_shield

	if is_instance_valid(shield_label):
		shield_label.visible = has_visible_shield


## Shows only the current shield value
func _set_shield_label_text() -> void:
	if not is_instance_valid(shield_label):
		return

	if current_shield <= 0:
		shield_label.visible = false
		return

	shield_label.visible = true
	shield_label.set_text(str(current_shield))
