extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String = ""
var item_for_sale_scene = preload("res://Scenes/ItemForSale.tscn")

func _ready():
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/Buy.text = tr("BUY") + " (B)"
	tween = Tween.new()
	add_child(tween)

func _on_Speedups_pressed():
	tab = "speedups"
	$Contents.visible = true
	set_item_visibility("Speedups")
	$Contents/Info.text = tr("SPEED_UP_DESC")
	set_btn_color($Tabs/Speedups)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Overclocks_pressed():
	tab = "overclocks"
	$Contents.visible = true
	set_item_visibility("Overclocks")
	$Contents/Info.text = tr("OVERCLOCK_DESC")
	set_btn_color($Tabs/Overclocks)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = true

func _on_Pickaxes_pressed():
	tab = "pickaxes"
	$Contents.visible = true
	set_item_visibility("Pickaxes")
	$Contents/Info.text = tr("PICKAXE_DESC")
	set_btn_color($Tabs/Pickaxes)
	$Contents/HBoxContainer/ItemInfo/HBoxContainer/BuyAmount.visible = false
	if $Contents/HBoxContainer/Items/Pickaxes.get_child_count() == 0:
		for pickaxe in game.pickaxe_info.keys():
			var pickaxe_info = game.pickaxe_info[pickaxe]
			var pickaxe_item = item_for_sale_scene.instance()
			pickaxe_item.item_name = pickaxe
			pickaxe_item.item_type = "Pickaxes"
			pickaxe_item.item_desc = tr(pickaxe.to_upper() + "_DESC")
			pickaxe_item.costs = pickaxe_info.costs
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
	remove_costs()
	$Contents/HBoxContainer/Items.get_node(type).visible = true
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Name.text = ""
	$Contents/HBoxContainer/ItemInfo/VBoxContainer/Description.text = ""
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = false

func remove_costs():
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	for child in vbox.get_children():
		if not child is Label:
			vbox.remove_child(child)

var item_costs:Dictionary
var item_name = ""

func set_item_info(name:String, desc:String, costs:Dictionary):
	remove_costs()
	var vbox = $Contents/HBoxContainer/ItemInfo/VBoxContainer
	vbox.get_node("Name").text = get_item_name(name)
	item_costs = costs
	item_name = name
	if tab == "pickaxes":
		var pickaxe_info = game.pickaxe_info[name]
		desc += ("\n\n" + tr("MINING_SPEED") + ": %s\n" + tr("DURABILITY") + ": %s") % [pickaxe_info.speed, pickaxe_info.durability]
	desc += "\n"
	vbox.get_node("Description").text = desc
	$Contents/HBoxContainer/ItemInfo/HBoxContainer.visible = true
	for cost in costs:
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		if cost == "money":
			texture.texture_normal = load("res://Graphics/Icons/Money.png")
			rsrc.get_node("Text").text = String(costs[cost])
		elif cost == "stone":
			texture.texture_normal = load("res://Graphics/Icons/stone.png")
			rsrc.get_node("Text").text = String(costs[cost]) + " kg"
		elif game.mats.has(cost):
			texture.texture_normal = load("res://Graphics/Materials/" + cost + ".png")
			rsrc.get_node("Text").text = String(costs[cost]) + " kg"
		elif game.mets.has(cost):
			texture.texture_normal = load("res://Graphics/Metals/" + cost + ".png")
			rsrc.get_node("Text").text = String(costs[cost]) + " kg"
		texture.rect_min_size = Vector2(42, 42)
		vbox.add_child(rsrc)

func get_item_name(name:String):
	match name:
		"stick":
			return tr("STICK")
		"wooden_pickaxe":
			return tr("WOODEN_PICKAXE")
		"stone_pickaxe":
			return tr("STONE_PICKAXE")
		"lead_pickaxe":
			return tr("LEAD_PICKAXE")
		"copper_pickaxe":
			return tr("COPPER_PICKAXE")
		"iron_pickaxe":
			return tr("IRON_PICKAXE")

func _on_Buy_pressed():
	var enough = true
	for cost in item_costs:
		if cost == "money" and game.money < item_costs[cost]:
			enough = false
		if cost == "stone" and game.stone < item_costs[cost]:
			enough = false
		if game.mats.has(cost) and game.mats[cost] < item_costs[cost]:
			enough = false
		if game.mets.has(cost) and game.mets[cost] < item_costs[cost]:
			enough = false
	if enough:
		if tab == "pickaxes":
			if game.pickaxe != null:
				YNPanel(tr("REPLACE_PICKAXE") % [get_item_name(game.pickaxe.name).to_lower(), get_item_name(item_name).to_lower()])
			else:
				buy_pickaxe()
	else:
		game.popup(tr("NOT_ENOUGH_RESOURCES"), 1.5)

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
	if game.c_v == "mining":
		game.mining_HUD.get_node("Pickaxe").visible = true
	game.money -= item_costs.money
	game.pickaxe = {"name":item_name, "speed":game.pickaxe_info[item_name].speed, "durability":game.pickaxe_info[item_name].durability}
	game.popup(tr("BUY_PICKAXE") % [get_item_name(item_name).to_lower()], 1.0)
