extends TextureProgressBar

@export var chip_bar: TextureProgressBar
@export var health_label: Label
@export var frame : TextureRect
@export_range(0, 1, 0.01) var diff_ratio_percentage := 0.08
@export_range(0, 1, 0.01) var glow_threshold := 0.25

@onready var bar: TextureProgressBar = self

var generator: CrystalGenerator = null
var glow_tween: Tween
var glow_active := false
var last_health := -1

func _ready() -> void:
	GSignals.BUI_generator_is_placed.connect(set_generator)
	frame.hide()

func set_generator(obj: CrystalGenerator) -> void:
	if is_instance_valid(obj):
		generator = obj
		max_value = generator.max_health
		value = generator.current_health
		last_health = generator.current_health
		frame.show()
		if is_instance_valid(chip_bar):
			chip_bar.max_value = generator.max_health
			chip_bar.value = generator.current_health
		
		_set_health_label_text()
		update_glow_state()

func _process(_delta: float) -> void:
	if !is_instance_valid(generator):
		return

	_sync_max_health()
	_detect_health_change()
	_set_health_label_text()
	update_glow_state()

## Syncs max health and current value
func _sync_max_health() -> void:
	if !is_instance_valid(generator):
		return

	generator.current_health = clampi(generator.current_health, 0, generator.max_health)

	max_value = generator.max_health
	if is_instance_valid(chip_bar):
		chip_bar.max_value = generator.max_health

## Detects HP changes and applies matching effects
func _detect_health_change() -> void:
	if !is_instance_valid(generator):
		return

	var current_hp := generator.current_health

	if last_health == -1:
		last_health = current_hp
		value = current_hp
		if is_instance_valid(chip_bar):
			chip_bar.value = current_hp
		return

	if current_hp < last_health:
		_apply_damage_effect(last_health, current_hp)
	elif current_hp > last_health:
		_apply_heal_effect(current_hp)
	else:
		value = current_hp

	last_health = current_hp

## Applies damage visuals
func _apply_damage_effect(old_hp: int, new_hp: int) -> void:
	value = new_hp

	var diff_ratio := 0.0
	if generator.max_health > 0:
		diff_ratio = float(old_hp - new_hp) / float(generator.max_health)

	_animate_chip(new_hp, diff_ratio)
	hit_flash()

	if diff_ratio > diff_ratio_percentage:
		micro_shake()

	update_glow_state()

## Applies healing visuals
func _apply_heal_effect(new_hp: int) -> void:
	if is_instance_valid(chip_bar):
		chip_bar.value = float(new_hp)

	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "value", float(new_hp), 0.25)

	update_glow_state()

## Animates the chip bar with delay
func _animate_chip(target: int, diff_ratio: float) -> void:
	if !is_instance_valid(chip_bar):
		return

	chip_bar.value = value + (generator.max_health * diff_ratio)

	var dur = lerp(0.18, 0.42, clamp(diff_ratio * 1.4, 0.0, 1.0))
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUINT)
	t.set_ease(Tween.EASE_OUT)
	t.tween_interval(0.15)
	t.tween_property(chip_bar, "value", float(target), dur)

## Short hit flash on the bar
func hit_flash() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.04)
	t.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.10)

## Small horizontal shake on big hits
func micro_shake(intensity: float = 3.0, dur: float = 0.15) -> void:
	var start := position
	var t := create_tween()
	t.tween_property(self, "position", start + Vector2(-intensity, 0), dur * 0.25)
	t.tween_property(self, "position", start + Vector2(intensity, 0), dur * 0.50)
	t.tween_property(self, "position", start, dur * 0.25)

## Updates glow state based on current HP ratio
func update_glow_state() -> void:
	if !is_instance_valid(generator) or generator.max_health <= 0:
		return

	var hp_ratio := float(generator.current_health) / float(generator.max_health)

	if hp_ratio < glow_threshold:
		if not glow_active:
			start_glow_pulse()
	else:
		if glow_active:
			stop_glow_pulse()

## Heartbeat glow pulse at low HP
func start_glow_pulse() -> void:
	stop_glow_pulse()
	glow_active = true

	if not material or !is_instance_valid(generator) or generator.max_health <= 0:
		return

	var hp_ratio := float(generator.current_health) / float(generator.max_health)
	var t_ratio = clamp(1.0 - (hp_ratio / max(glow_threshold, 0.001)), 0.0, 1.0)
	var bpm = lerp(70.0, 160.0, t_ratio)
	var cycle = 60.0 / bpm
	var base_sum := 0.08 + 0.12 + 0.06 + 0.07 + 0.12
	var scale = cycle / max(base_sum, 0.0001)

	var peak1 = lerp(0.75, 0.95, t_ratio)
	var peak2 = lerp(0.62, 0.82, t_ratio)
	var base_i = lerp(0.25, 0.35, t_ratio)
	var low_i = lerp(0.22, 0.30, t_ratio)

	material.set_shader_parameter("glow_intensity", base_i)

	glow_tween = create_tween()
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", peak1, 0.08 * scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", low_i, 0.12 * scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	glow_tween.tween_interval(0.06 * scale)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", peak2, 0.07 * scale).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(material, "shader_parameter/glow_intensity", base_i, 0.12 * scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	glow_tween.tween_callback(Callable(self, "start_glow_pulse"))

## Stops the glow pulse
func stop_glow_pulse() -> void:
	if glow_tween and glow_tween.is_valid():
		glow_tween.kill()

	glow_tween = null
	glow_active = false

	if material:
		material.set_shader_parameter("glow_intensity", 0.0)

## Sets the label text to current / max health
func _set_health_label_text() -> void:
	if is_instance_valid(health_label):
		health_label.text = str(roundi(value)) + " / " + str(roundi(max_value))
