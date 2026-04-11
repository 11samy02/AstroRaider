extends Control

@onready var perk_list: HBoxContainer = %PerkList
@onready var titel: Label = %titel
@onready var description: Label = %description
@onready var progress_bar: ProgressBar = %ProgressBar

signal select_perk_by_index(index: int)

var temp_list: Array[PerkBuild] = []
var selected_perk_id := -1
var is_button_pressed := false
var _perk_buttons: Array[TextureButton] = []


func _ready() -> void:
	for child in perk_list.get_children():
		if child is TextureButton:
			_perk_buttons.append(child)
	for i in _perk_buttons.size():
		_perk_buttons[i].mouse_entered.connect(_on_perk_mouse_entered.bind(i))
		_perk_buttons[i].button_down.connect(_on_perk_button_down.bind(i))
		_perk_buttons[i].button_up.connect(_on_perk_button_up)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not visible or not is_button_pressed:
		return
	progress_bar.value += 300.0 * delta
	if progress_bar.value >= progress_bar.max_value:
		is_button_pressed = false
		progress_bar.value = 0.0
		hide()
		select_perk_by_index.emit(selected_perk_id)


## Sets up the perk buttons with the given perk list
func set_perk_details(list: Array[PerkBuild]) -> void:
	temp_list = list.duplicate()
	progress_bar.value = 0.0
	selected_perk_id = -1
	is_button_pressed = false
	for i in _perk_buttons.size():
		if i < list.size() and is_instance_valid(list[i]):
			var tex: TextureRect = _perk_buttons[i].get_child(0)
			tex.texture = list[i].perk_res.image
			_perk_buttons[i].show()
		else:
			_perk_buttons[i].hide()
	if !visible:
		show()
		GSignals.UI_show_only_PerkSelector.emit()


func _on_perk_mouse_entered(id: int) -> void:
	if id >= temp_list.size() or not is_instance_valid(temp_list[id]):
		return
	var perk := temp_list[id]
	var res := perk.perk_res
	var display_level := perk.Level if not perk.has_unlocked else perk.Level + 1
	description.text = res.get_description(display_level)
	titel.text = res.perk_name


func _on_perk_button_down(id: int) -> void:
	if id >= temp_list.size() or not is_instance_valid(temp_list[id]):
		return
	selected_perk_id = id
	is_button_pressed = true


func _on_perk_button_up() -> void:
	is_button_pressed = false
	progress_bar.value = 0.0
