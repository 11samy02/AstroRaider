extends Node

@export var tab_container: TabContainer
@export var tab_button_container: HBoxContainer

var button_list : Array[CustomButton]

func _ready() -> void:
	connect_signals()
	await get_tree().process_frame
	tab_pressed(0)

func connect_signals() -> void:
	var index := 0
	for button in tab_button_container.get_children():
		if button is CustomButton:
			button.connect("pressed", tab_pressed.bind(index))
			index += 1
			button_list.append(button)

func tab_pressed(index: int) -> void:
	tab_container.current_tab = index
	for i in button_list.size():
		button_list[i].button_pressed = (i == index)
	button_list[index].grab_focus()
