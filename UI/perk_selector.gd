extends Control

@onready var perk_list: HBoxContainer = %PerkList
@onready var titel: Label = %titel
@onready var description: Label = %description
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var perk: TextureButton = %Perk
@onready var perk_2: TextureButton = %Perk2
@onready var perk_3: TextureButton = %Perk3

signal select_perk_by_index(index: int)

var temp_list : Array[PerkBuild]
var selected_perk_id : int = -1
var is_button_pressed := false

func _ready() -> void:
	perk.mouse_entered.connect(_on_perk_mouse_entered.bind(0))
	perk_2.mouse_entered.connect(_on_perk_mouse_entered.bind(1))
	perk_3.mouse_entered.connect(_on_perk_mouse_entered.bind(2))
	
	perk.button_down.connect(_on_perk_button_down.bind(0))
	perk_2.button_down.connect(_on_perk_button_down.bind(1))
	perk_3.button_down.connect(_on_perk_button_down.bind(2))
	
	perk.button_up.connect(_on_perk_button_up)
	perk_2.button_up.connect(_on_perk_button_up)
	perk_3.button_up.connect(_on_perk_button_up)

func _process(delta: float) -> void:
	if visible and is_button_pressed:
		progress_bar.value += 200.0 * delta
		if progress_bar.value >= progress_bar.max_value:
			is_button_pressed = false
			progress_bar.value = 0.0
			select_perk_by_index.emit(selected_perk_id)
			await get_tree().create_timer(0.1)
			hide()
			get_tree().paused = false

func set_perk_details(list: Array[PerkBuild]) -> void:
	temp_list = list.duplicate()
	progress_bar.value = 0.0
	var id := 0
	for perk_button: TextureButton in perk_list.get_children():
		if id < list.size() and is_instance_valid(list[id]):
			var tex: TextureRect = perk_button.get_child(0)
			tex.texture = list[id].perk_res.image
			id += 1
			perk_button.show()
		else:
			perk_button.hide()
	if !visible:
		show()
		get_tree().paused = true

func _on_perk_mouse_entered(id: int) -> void:
	if id < temp_list.size() and is_instance_valid(temp_list[id]):
		var perk = temp_list[id]
		var res = temp_list[id].perk_res
		if !perk.has_unlocked:
			description.text = res.get_description(temp_list[id].Level)
		else:
			description.text = res.get_description(temp_list[id].Level + 1)
		titel.text = res.perk_name


func _on_perk_button_down(id: int) -> void:
	if id < temp_list.size() and is_instance_valid(temp_list[id]):
		selected_perk_id = id
		is_button_pressed = true

func _on_perk_button_up() -> void:
	is_button_pressed = false
	progress_bar.value = 0.0
