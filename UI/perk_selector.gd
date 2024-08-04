extends CanvasLayer

@onready var perk_button: TextureButton = $button_margin/TextureRect/MarginContainer/VBoxContainer/HBoxContainer/PerkButton
@onready var perk_button_2: TextureButton = $button_margin/TextureRect/MarginContainer/VBoxContainer/HBoxContainer/PerkButton2
@onready var perk_button_3: TextureButton = $button_margin/TextureRect/MarginContainer/VBoxContainer/HBoxContainer/PerkButton3

@onready var label: Label = %Label

func _ready() -> void:
	perk_button.connect("change_description", change_description)
	perk_button_2.connect("change_description", change_description)
	perk_button_3.connect("change_description", change_description)

func change_description(perk: Perk) -> void:
	label.set_text(perk.get_description())
