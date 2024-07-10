extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var atk_resource: AttackResource = AttackResource.new()
@export var speed := 500
@export var dir := Vector2.ZERO


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		area.get_hit(atk_resource)
		set_physics_process(false)
		animation_player.play("hit")


func _physics_process(delta: float) -> void:
	translate(dir * speed * delta)


func _on_lifetime_timeout() -> void:
	set_physics_process(false)
	animation_player.play("hit")
