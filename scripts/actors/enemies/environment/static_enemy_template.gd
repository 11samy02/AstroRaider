extends StaticBody2D
class_name StaticEnemy

@export var hp := 20
@export var valnuable_time := 0.1
@export var can_take_damage := true

func death():
	queue_free()
