extends TextureRect

@export var game_ui : GameUi
@onready var level_label: Label = $level_label


func _ready() -> void:
	_update_level_label()
	
	if GameSaver.suit_progress_changed.is_connected(_on_suit_progress_changed):
		return
	GameSaver.suit_progress_changed.connect(_on_suit_progress_changed)


func _update_level_label() -> void:
	if not is_instance_valid(game_ui) or not is_instance_valid(game_ui.player):
		level_label.set_text("")
		return

	var suit_data := game_ui.player.get_selected_suit_data()
	if not is_instance_valid(suit_data):
		level_label.set_text("")
		return

	level_label.set_text(str(suit_data.current_level))


func _on_suit_progress_changed(
	suit_key: SuitData.SuitKeys,
	current_level: int,
	_current_exp: int,
	_levels_gained: int
) -> void:
	if not is_instance_valid(game_ui) or not is_instance_valid(game_ui.player):
		return
	if game_ui.player.selected_suit != suit_key:
		return

	level_label.set_text(str(current_level))
