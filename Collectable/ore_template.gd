extends CollectableTemplate
class_name OreTemplate

enum Ores {
	Iron,
	Copper,
	Gold,
}

@export var ore_type := Ores.Iron

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.play("Appear")
	super()

func on_destroy() -> void:
	anim.play("Clear")
