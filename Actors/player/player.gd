extends CharacterBody2D
class_name Player

enum states {
	Default,
	Build,
}

var current_state := states.Default

@export var radar_icon : Texture2D

@onready var check_for_ground: ShapeCast2D = $Rays/check_for_ground
@onready var check_for_destroyable_ground: ShapeCast2D = $Rays/check_for_destroyable_ground



@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite_anim: AnimationPlayer = $Sprite/sprite_anim
@onready var bohrer_holder: Node2D = $bohrer_holder
@onready var bohrer_hit_coll: CollisionShape2D = $BohrerHitBox/bohrer_hit_coll

@onready var damage_sound: Audio2D = $Sounds/Damage
@onready var bohrer_sound: Audio2D = $Sounds/BohrerSound
@onready var live_indikator: Audio2D = $Sounds/LiveIndikator

@export var landing_anim_name : Array[String]

var gravity_dir := Vector2.DOWN

@export var player_id := 0
@export var controller_id := 0
@export var character_build_id := 0

var is_bohrer_active := false

var deadzone := 0.25

@export var stats: Stats

var collected_crystals : Array[ItemCrystal] = []

var can_take_damage := true


func _ready() -> void:
	if character_build_id < PlayerDataBuilds.player_saved_res.saved_builds.size():
		stats = PlayerDataBuilds.player_saved_res.saved_builds[character_build_id].stats
	else:
		print("No Player Build was found with the ID ", character_build_id)

func _physics_process(delta: float) -> void:
	move_and_slide()
	shader_effects()


var shader_value = 0

func get_hit_anim() -> void:
	var tween = create_tween()
	shader_value = 1
	sprite.scale = Vector2(1.5,1.5)
	
	damage_sound.play_sound()
	tween.tween_property(self, "shader_value", 0, 0.2)
	tween.parallel().tween_property(sprite, "scale", Vector2(1,1), 0.2)
	
	sprite_anim.play("damaged", -1, stats.invincibility_frame - stats.added_invincibility_frame)


func shader_effects() -> void:
	sprite.material.set_shader_parameter("mix_color", shader_value)

func clear_collected_null() -> void:
	for i in range(collected_crystals.size() - 1, -1, -1):
		if collected_crystals[i] == null:
			collected_crystals.remove_at(i)
