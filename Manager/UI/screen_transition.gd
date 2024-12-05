extends CanvasLayer

var new_szene : PackedScene
@onready var anim: AnimationPlayer = $anim
signal finished_loading

func _ready() -> void:
	finished_loading.connect(fade_out)

func change_scene_to(szene_path: PackedScene) -> void:
	new_szene = szene_path
	PauseMenu.can_pause_on_screen = false
	anim.play("Transition")

func change_scene_and_wait(szene_path: PackedScene) -> void:
	new_szene = szene_path
	PauseMenu.can_pause_on_screen = false
	anim.play("Transition_and_wait")

func _transition():
	get_tree().change_scene_to_packed(new_szene)
	PauseMenu.can_pause_on_screen = true

func _transition_wait():
	get_tree().change_scene_to_packed(new_szene)

func fade_out():
	anim.play("fade_out")
	PauseMenu.can_pause_on_screen = true
