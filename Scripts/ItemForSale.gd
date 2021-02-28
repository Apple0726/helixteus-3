extends Control

onready var game = get_node("/root/Game")
export var item_name:String = ""
var item_desc:String = ""
var item_type:String = ""
var item_dir:String = ""#Directory of the item sprite
var costs:Dictionary
var parent = ""

func _ready():
	if item_dir != "":
		$ItemTexture.texture = load("res://Graphics/" + item_dir + "/" + item_name + ".png")

func _on_Button_pressed():
	if not parent in ["construct_panel", "megastructures_panel"]:
		game[parent].amount_node.value = 1
	game[parent].set_item_info(item_name, item_desc, costs, item_type, item_dir)

func _on_SmallButton_pressed():
	#var total_costs = costs.duplicate(true)
	game[parent].item_costs = costs.duplicate(true)
	if not parent in ["construct_panel", "megastructures_panel"]:
		if parent == "shop_panel" and game[parent].tab == "Pickaxes":
			game[parent].amount_node.value = 1
		else:
			if Input.is_action_pressed("shift"):
				game[parent].amount_node.value = 10
			else:
				game[parent].amount_node.value = 1
	game[parent].get_item(item_name, item_type, item_dir)

func _on_SmallButton_mouse_entered():
	game.help.mass_buy = true
	if game.help.mass_buy:
		game.show_tooltip("%s\n%s" % [tr("HOLD_SHIFT_FOR_10"), tr("HIDE_HELP")])

func _on_SmallButton_mouse_exited():
	game.hide_tooltip()
