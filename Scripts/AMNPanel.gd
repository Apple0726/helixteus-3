extends "Panel.gd"

var from_type:String
var from_name:String
var to_type:String
var to_name:String

func _ready():
	set_polygon($Background.rect_size)

func refresh():
	$ScrollContainer/VBoxContainer/CAD.disabled = game.atoms.carbon == 0 and game.mets.diamond == 0
	if from_type == "":
		return
	$Control/HSlider.max_value = game[from_type][from_name]
	$Control/HSlider.visible = $Control/HSlider.max_value != 0
	$Control/Transform.visible = $Control/HSlider.max_value != 0

func _on_CAD_pressed():
	$Control.visible = true
	from_type = "atoms"
	from_name = "carbon"
	$Control/FromIcon.texture = load("res://Graphics/Atoms/carbon.png")
	to_type = "mets"
	to_name = "diamond"
	$Control/ToIcon.texture = load("res://Graphics/Metals/diamond.png")
	refresh()

func _on_Switch_pressed():
	var temp_type:String = from_type
	var temp_name:String = from_name
	var temp_texture:Reference = $Control/FromIcon.texture
	from_type = to_type
	from_name = to_name
	$Control/FromIcon.texture = $Control/ToIcon.texture
	to_type = temp_type
	to_name = temp_name
	$Control/ToIcon.texture = temp_texture
	refresh()

func _on_HSlider_value_changed(value):
	if from_type == "atoms":
		$Control/FromText.text = "%s mol" % [value]
	else:
		$Control/FromText.text = "%s kg" % [value * 0.8]
	if to_type == "atoms":
		$Control/ToText.text = "%s mol" % [value]
	else:
		$Control/ToText.text = "%s kg" % [value * 0.8]
	refresh()
	
