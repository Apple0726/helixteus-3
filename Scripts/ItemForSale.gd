extends Control

onready var game = get_node("/root/Game")
export var item_name:String = ""
var item_desc:String = ""
var item_type:String = ""
var costs:Dictionary

func _ready():
	$ItemTexture.texture = load("res://Graphics/" + item_type + "/" + item_name + ".png")

func _on_Button_pressed():
	game.shop_panel.set_item_info(item_name, item_desc, costs)
