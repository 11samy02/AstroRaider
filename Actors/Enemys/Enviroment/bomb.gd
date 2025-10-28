extends StaticEnemy
class_name Bomb

const EXPLOSION = preload("res://Actors/Enemys/Enviroment/bomb_explosion.tscn")

@onready var sprite: AnimatedSprite2D = $sprite
@onready var explosion_sound: Audio2D = $ExplosionSound
@onready var explosion_indikator: Line2D = $explosion_indikator
@onready var dashed_circle: Line2D = $DashedCircle

@export var damage: int = 10
@export var grid_size: int = 16
@export var explosion_radius: int = 7  # Durchmesser in Tiles

var _exploded := false
static var _mask_cache := {}

func _ready() -> void:
	can_take_damage = false
	hp += randi_range(-2, 2)

	# --- Radius/Position SOFORT setzen ---
	var r_tiles := int(ceil(explosion_radius / 2.0))
	var r_px := r_tiles * grid_size
	var center := global_position.snapped(Vector2(grid_size / 2, grid_size / 2))

	# Randkreis direkt zeichnen (statisch)
	if dashed_circle:
		dashed_circle.radius = r_px
		dashed_circle.global_position = center
		dashed_circle.draw_dashed_circle()

	# Explosion-Indikator NUR setzen, NICHT starten
	if explosion_indikator:
		explosion_indikator.radius = r_px
		explosion_indikator.global_position = center
		# KEIN draw_dashed_circle() hier, damit die Animation erst beim Explodieren beginnt

func _on_explode_time_timeout() -> void:
	hp -= 1

func _process(_delta: float) -> void:
	if _exploded:
		return

	if hp <= 0:
		# Start der Indikator-Animation genau jetzt
		if explosion_indikator and explosion_indikator.visible:
			explosion_indikator.draw_dashed_circle()
			# Warten bis der Kreis die Mitte erreicht (dein Script setzt dann visible=false)
			while explosion_indikator.visible:
				await get_tree().process_frame

		# Jetzt (und erst jetzt) explodieren
		_exploded = true
		var all_collision_pos: PackedVector2Array = _collect_explosion_points_world_cached()
		GSignals.ENV_destroy_tile.emit(all_collision_pos, damage * 100)
		GSignals.CAM_shake_effect.emit()
		await get_tree().process_frame
		death()

func _collect_explosion_points_world_cached() -> PackedVector2Array:
	var offsets: Array[Vector2i] = _get_mask_offsets(explosion_radius, grid_size)
	var center := global_position.snapped(Vector2(grid_size / 2, grid_size / 2))
	var uniq := {}
	for o in offsets:
		var wp := center + Vector2(o.x * grid_size, o.y * grid_size)
		uniq[wp] = true

	var pts := PackedVector2Array()
	for p in uniq.keys():
		pts.append(p)
	return pts

static func _get_mask_offsets(diameter_tiles: int, grid: int) -> Array[Vector2i]:
	var key := Vector2i(diameter_tiles, grid)
	if _mask_cache.has(key):
		return _mask_cache[key]
	var r_tiles := int(ceil(diameter_tiles / 2.0))
	var r2 := r_tiles * r_tiles
	var arr: Array[Vector2i] = []
	for y in range(-r_tiles, r_tiles + 1):
		var yy := y * y
		for x in range(-r_tiles, r_tiles + 1):
			if x * x + yy <= r2:
				arr.append(Vector2i(x, y))
	_mask_cache[key] = arr
	return arr

func death():
	var explosion: BombExplosion = EXPLOSION.instantiate()
	explosion.global_position = global_position
	explosion.damage = damage

	# Kollisions-Radius an Explosion übergeben
	var r_tiles := int(ceil(explosion_radius / 2.0))
	var r_px := r_tiles * grid_size
	if "set_radius_px" in explosion:
		explosion.set_radius_px(r_px)
	else:
		explosion.radius_px = r_px

	get_parent().add_child(explosion)

	var real_sound: Audio2D = explosion_sound.duplicate()
	get_parent().add_child(real_sound)
	real_sound.global_position = self.global_position
	real_sound.play_sound()
	super()

func _on_initiate_time_timeout() -> void:
	can_take_damage = true

static func reset() -> void:
	pass
