extends Panel

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

func _on_ItemForSale_mouse_entered():
	if not game[parent].locked:
		if not parent in ["construct_panel", "megastructures_panel"]:
			game[parent].amount_node.value = 1
		game[parent].set_item_info(item_name, item_desc, costs, item_type, item_dir)

func _on_SmallButton_pressed():
	game[parent].set_item_info(item_name, item_desc, costs, item_type, item_dir)
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
	game.help_str = "mass_buy"
	if game.help.mass_buy:
		game.show_tooltip("%s\n%s" % [tr("HOLD_SHIFT_FOR_10"), tr("HIDE_HELP")])

func _on_SmallButton_mouse_exited():
	game.hide_tooltip()


func _on_ItemForSale_mouse_exited():
	if not game[parent].locked:
		game[parent].item_info.visible = false

func _on_LockItemInfo_toggled(button_pressed):
	if button_pressed:
		for item in game[parent].grid.get_children():
			if item != self:
				item.get_node("LockItemInfo").pressed = false
		_on_ItemForSale_mouse_entered()
		game[parent].locked = true
	else:
		game[parent].locked = false
