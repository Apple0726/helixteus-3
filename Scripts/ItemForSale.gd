extends Control

onready var game = get_node("/root/Game")
export var item_name:String = ""
var item_desc:String = ""
var item_type:String = ""
var item_dir:String = ""#Directory of the item sprite
var costs:Dictionary
var parent = ""

func _ready():
	$ItemTexture.texture = load("res://Graphics/" + item_dir + "/" + item_name + ".png")

func _on_Button_pressed():
	game[parent].set_item_info(item_name, item_desc, costs, item_type, item_dir)

func _on_SmallButton_pressed():
	game[parent].get_item(item_name, costs, item_type, item_dir)
