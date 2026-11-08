extends Control

@onready var game = get_node("/root/Game")
var type:String
var obj:String
var polygon
@onready var obj_node = $Object
@onready var money_node = $Money

func _ready():
	$Resource/Texture2D.custom_minimum_size = Vector2(36, 36)
	$Resource2/Texture2D.custom_minimum_size = Vector2(36, 36)
	$Resource2/Texture2D.texture_normal = preload("res://Graphics/Icons/money.png")
	$Resource.set_process(false)
	$Resource2.set_process(false)

var max_value:float

func refresh(_type:String = type, _obj:String = obj):
	type = _type
	obj = _obj
	$HSlider.value = 0
	rounded_value = 0
	money_value = 0
	if type == "Materials":
		max_value = game.mats[obj]
	elif type == "Metals":
		max_value = game.mets[obj]
	obj_node.get_node("Texture2D").texture_normal = load("res://Graphics/" + type + "/" + obj + ".png")
	money_node.get_node("Texture2D").texture_normal = load("res://Graphics/Icons/money.png")
	obj_node.get_node("Text").text = "0 kg"
	money_node.get_node("Text").text = "0"

var rounded_value = 0
var money_value = 0
func _on_HSlider_value_changed(value):
	value = value * max_value / 100.0
	rounded_value = Helper.clever_round(value)
	obj_node.get_node("Text").text = "%s kg" % Helper.format_num(rounded_value)
	if type == "Materials":
		money_value = floor(rounded_value * game.mat_info[obj].value)
		money_node.get_node("Text").text = Helper.format_num(money_value)
	elif type == "Metals":
		money_value = floor(rounded_value * game.met_info[obj].value)
		money_node.get_node("Text").text = Helper.format_num(money_value)

func _on_Button_pressed():
	if type == "Materials":
		game.mats[obj] -= rounded_value
		if game.mats[obj] < 0:
			game.mats[obj] = 0
	elif type == "Metals":
		game.mets[obj] -= rounded_value
		if game.mets[obj] < 0:
			game.mets[obj] = 0
	game.add_resources({"money":money_value})
	game.popup(tr("SALE_SUCCESS"), 1.5)
	game.inventory.refresh()
	game.HUD.refresh()
	_on_close_button_pressed()

func _on_close_button_pressed():
	visible = false
	game.sub_panel = null
	game.view.move_view = true
	game.view.scroll_view = true


func _on_h_slider_mouse_entered():
	game.view.move_view = false
	game.view.scroll_view = false


func _on_h_slider_mouse_exited():
	game.view.move_view = true
	game.view.scroll_view = true
