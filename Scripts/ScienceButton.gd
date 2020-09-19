extends Control

export var science:String

func _ready():
	$PanelContainer.connect("mouse_entered", self, "on_mouse_entered")
	$PanelContainer.connect("mouse_exited", self, "on_mouse_exited")
	$PanelContainer/HBoxContainer/TextureRect.texture = load("res://Graphics/Science/" + science + ".png")
	$PanelContainer/HBoxContainer/VBoxContainer/Label.text = get_science_name(science)
	$PanelContainer/HBoxContainer/VBoxContainer/Resource/Text.text = String(Data.science_unlocks[science].cost)

func get_science_name(sc:String):
	match sc:
		"SA":
			return tr("SPACE_AGRICULTURE")

func on_mouse_entered():
	get_parent().show_tooltip(science)

func on_mouse_exited():
	get_parent().hide_tooltip()
