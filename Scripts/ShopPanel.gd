extends Control

onready var game = get_node("/root/Game")
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")

func _ready():
	tween = Tween.new()
	add_child(tween)

func _on_Speedups_pressed():
	tab = "speedups"
	$Contents.visible = true
	set_item_visibility("Speedups")
	$Contents/Info.text = "Speed-up items instantly accelerate construction of a building. Higher-tier items affect multiple buildings."
	set_btn_color($Tabs/Speedups)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Overclocks_pressed():
	tab = "overclocks"
	$Contents.visible = true
	set_item_visibility("Overclocks")
	$Contents/Info.text = "Overclock items temporarily boost resource production of the affected buildings. Higher levels boost more and last longer, as well as affecting multiple buildings."
	set_btn_color($Tabs/Overclocks)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Pickaxes_pressed():
	tab = "pickaxes"
	$Contents.visible = true
	set_item_visibility("Pickaxes")
	$Contents/Info.text = "Pickaxes allow you to manually mine a planet for various resources. Higher tier pickaxes mine faster and last longer."
	set_btn_color($Tabs/Pickaxes)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = false
	if $Contents/HBoxContainer/Items/Pickaxes.get_child_count() == 0:
		for pickaxe in game.pickaxe_info.keys():
			var pickaxe_info = game.pickaxe_info[pickaxe]
			var pickaxe_item = item_for_sale_scene.instance()
			pickaxe_item.item_name = pickaxe
			pickaxe_item.item_desc = pickaxe_info.desc
			pickaxe_item.money_cost = pickaxe_info.money_cost
			$Contents/HBoxContainer/Items/Pickaxes.add_child(pickaxe_item)

func set_btn_color(btn):
	for other_btn in $Tabs.get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

func set_item_visibility(type:String):
	for other_type in $Contents/HBoxContainer/Items.get_children():
		other_type.visible = false
	$Contents/HBoxContainer/Items.get_node(type).visible = true
	$Contents/HBoxContainer/ItemInfo/Name.text = ""
	$Contents/HBoxContainer/ItemInfo/Description.text = ""
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = false

var item_money_cost = 0.0
var item_name = ""

func set_item_info(name:String, desc:String, money_cost:float):
	var desc2 = desc
	$Contents/HBoxContainer/ItemInfo/Name.text = get_item_name(name)
	item_money_cost = money_cost
	item_name = name
	if tab == "pickaxes":
		var pickaxe_info = game.pickaxe_info[name]
		desc += "\n\nMining speed: " + String(pickaxe_info.speed) + "\nDurability: " + String(pickaxe_info.durability)
	$Contents/HBoxContainer/ItemInfo/Description.text = desc
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = true

func get_item_name(name:String):
	match name:
		"stick":
			return "Stick"

func _on_Buy_pressed():
	if game.money >= item_money_cost:
		if tab == "pickaxes":
			if game.pickaxe != null:
				YNPanel("Replace your " + get_item_name(game.pickaxe.name).to_lower() + " with a " + get_item_name(item_name).to_lower() + "?")
			else:
				buy_pickaxe()
	else:
		game.popup("You don't have enough money.")

func YNPanel(text:String):
	#var YN = ConfirmationDialog.new()
	#$Confirms.add_child(YN)
	$ConfirmationDialog.dialog_text = text
	$ConfirmationDialog.popup_centered()
	if not $ConfirmationDialog.is_connected("confirmed", self, "buy_pickaxe"):
		$ConfirmationDialog.connect("confirmed", self, "buy_pickaxe")

func buy_pickaxe_confirm():
	buy_pickaxe()
	$ConfirmationDialog.disconnect("confirmed", self, "buy_pickaxe")

func buy_pickaxe():
	game.money -= item_money_cost
	game.pickaxe = {"name":item_name, "speed":game.pickaxe_info[item_name].speed, "durability":game.pickaxe_info[item_name].durability}
	game.popup("You bought a " + get_item_name(item_name).to_lower() + "!", 1.0)
