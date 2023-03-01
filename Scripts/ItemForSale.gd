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
		if parent == "construct_panel":
			game.new_bldgs[item_name] = false
			var tween = get_tree().create_tween()
			tween.tween_property($New, "modulate", Color(1, 1, 1, 0), 0.2)
		game[parent].set_item_info(item_name, item_desc, costs, item_type, item_dir)
		var tween = get_tree().create_tween()
		tween.tween_property(game[parent].item_info, "modulate", Color(1, 1, 1, 1), 0.1)

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
	if game.help.has("mass_buy"):
		if parent in ["craft_panel", "shop_panel"] and item_type != "pickaxes_info":
			game.show_tooltip("%s\n%s" % [tr("HOLD_SHIFT_FOR_10"), tr("HIDE_HELP")])

func _on_SmallButton_mouse_exited():
	game.hide_tooltip()


func _on_ItemForSale_mouse_exited():
	if not game[parent].locked:
		var tween = get_tree().create_tween()
		tween.tween_property(game[parent].item_info, "modulate", Color(1, 1, 1, 0), 0.1)

func _on_LockItemInfo_toggled(button_pressed):
	$ColorRect.visible = button_pressed
	if button_pressed:
		$AnimationPlayer.play("Flashing")
		for item in game[parent].grid.get_children():
			if item != self:
				item.get_node("LockItemInfo").pressed = false
		_on_ItemForSale_mouse_entered()
		game[parent].locked = true
	else:
		game[parent].locked = false
