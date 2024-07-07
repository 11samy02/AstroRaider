extends CollectableTemplate
class_name ItemCrystal

@onready var sprite: Sprite2D = $Sprite2D

@export var value := 10

func _ready() -> void:
	sprite.frame = randi_range(0,2)


func collect(body: Node2D) -> void:
	print(value)
	super(body)
