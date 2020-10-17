extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String
var buy_sell_scene = preload("res://Scenes/Panels/BuySellPanel.tscn")
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var buy_sell
onready var inventory_grid = $Contents/Control/Inventory
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var item_hovered:String = ""
var item_stack:int = 0
var item_slot:int = 0

func _ready():
	buy_sell = buy_sell_scene.instance()
	buy_sell.visible = false
	add_child(buy_sell)
	tween = Tween.new()
	add_child(tween)
	_on_Items_pressed()
	$Tabs/Materials.visible = game.show.materials
	$Tabs/Metals.visible = game.show.metals

func refresh():
	if tab == "items":
		_on_Items_pressed()
	elif tab == "materials":
		_on_Materials_pressed()
	elif tab == "metals":
		_on_Metals_pressed()

func _on_Items_pressed():
	tab = "items"
	$Contents/Info.text = tr("INV_ITEMS_DESC")
	Helper.set_btn_color($Tabs/Items)
	inventory_grid.visible = true
	$Contents/Control/GridContainer.visible = false
	for item in inventory_grid.get_children():
		inventory_grid.remove_child(item)
	var i:int = 0
	for item in game.items:
		var slot = slot_scene.instance()
		if item != null:
			slot.get_node("Label").text = String(item.num)
			slot.get_node("TextureRect").texture = load("res://Graphics/" + item.directory  + "/" + item.name + ".png")
			slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [item.name, item.num, i])
			slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
			slot.get_node("Button").connect("pressed", self, "on_slot_press", [item.name, item.type, item.directory])
		inventory_grid.add_child(slot)
		i += 1

func on_slot_over (name:String, num:int, slot:int):
	item_slot = slot
	item_hovered = name
	item_stack = num
	if game.help.inventory_shortcuts:
		game.help_str = "inventory_shortcuts"
		game.show_tooltip(Helper.get_item_name(name) + "\n%s\n%s\n%s\n%s\n%s" % [tr("CLICK_TO_USE"), tr("SHIFT_CLICK_TO_USE_ALL"), tr("X_TO_THROW_ONE"), tr("SHIFT_X_TO_THROW_STACK"), tr("H_FOR_HOTBAR")] + "\n" + tr("HIDE_SHORTCUTS"))
	else:
		game.show_tooltip(Helper.get_item_name(name))

func on_slot_out():
	item_hovered = ""
	game.hide_tooltip()

func on_slot_press(name:String, type:String, dir:String):
	game.hide_tooltip()
	if visible:
		game.toggle_panel(game.inventory)
	if game.shop_panel.visible:
		game.toggle_panel(game.shop_panel)
	var num:int
	if Input.is_action_pressed("shift"):
		num = game.get_item_num(name)
	else:
		num = 1
	game.item_to_use.name = name
	game.item_to_use.num = num
	var texture
	if type == "craft_agric_info":
		if game.craft_agric_info[name].has("grow_time"):
			game.put_bottom_info(tr("PLANT_SEED_INFO"))
			game.item_to_use.type = "seeds"
		elif game.craft_agric_info[name].has("speed_up_time"):
			game.item_to_use.type = "fertilizer"
	elif type == "speedup_info":
		game.put_bottom_info(tr("USE_SPEEDUP_INFO"))
		game.item_to_use.type = "speedup"
	elif type == "overclock_info":
		game.put_bottom_info(tr("USE_OVERCLOCK_INFO"))
		game.item_to_use.type = "overclock"
	texture = load("res://Graphics/" + dir + "/" + name + ".png")
	game.show_item_cursor(texture)

func _on_Materials_pressed():
	tab = "materials"
	$Contents/Info.text = tr("INV_MAT_DESC")
	Helper.set_btn_color($Tabs/Materials)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	var mat_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mats)
	for mat in mat_data:
		if game.show.has(mat.name) and not game.show[mat.name]:
			mat.rsrc.visible = false
			continue
		var texture = mat.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_mat", [mat.name])
		texture.connect("mouse_exited", self, "hide_mat")
		texture.connect("pressed", self, "show_buy_sell", ["Materials", mat.name])

func _on_Metals_pressed():
	tab = "metals"
	$Contents/Info.text = tr("INV_MET_DESC")
	Helper.set_btn_color($Tabs/Metals)
	inventory_grid.visible = false
	$Contents/Control/GridContainer.visible = true
	var met_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mets)
	for met in met_data:
		if game.show.has(met.name) and not game.show[met.name]:
			met.rsrc.visible = false
			continue
		var texture = met.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_met", [met.name])
		texture.connect("mouse_exited", self, "hide_met")
		texture.connect("pressed", self, "show_buy_sell", ["Metals", met.name])

func show_buy_sell(type:String, obj:String):
	if game.money == 0:
		if type == "Materials" and game.mats[obj] == 0:
			game.popup("PURCHASE_SALE_IMPOSSIBLE", 1.5)
			return
		if type == "Metals" and game.mets[obj] == 0:
			game.popup("PURCHASE_SALE_IMPOSSIBLE", 1.5)
			return
		buy_sell.is_selling = true
	else:
		if type == "Materials" and game.mats[obj] <= 0:
			buy_sell.is_selling = false
		if type == "Metals" and game.mets[obj] <= 0:
			buy_sell.is_selling = false
	buy_sell.visible = true
	buy_sell.refresh(type, obj)
	if not game.panels.has(buy_sell):
		game.panels.push_front(buy_sell)

func show_mat(mat:String):
	game.show_tooltip(get_mat_str(mat) + "\n" + get_mat_str(mat, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_mat():
	game.hide_tooltip()

func show_met(met:String):
	game.show_tooltip(get_met_str(met) + "\n" + get_met_str(met, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_met():
	game.hide_tooltip()

func get_mat_str(mat:String, desc:String = ""):
	match mat:
		"coal":
			return tr("COAL" + desc)
		"glass":
			return tr("GLASS" + desc)
		"sand":
			return tr("SAND" + desc)
		"clay":
			return tr("CLAY" + desc)
		"soil":
			return tr("SOIL" + desc)
		"cellulose":
			return tr("CELLULOSE" + desc)

func get_met_str(met:String, desc:String = ""):
	match met:
		"lead":
			return tr("LEAD" + desc)
		"copper":
			return tr("COPPER" + desc)
		"iron":
			return tr("IRON" + desc)
		"aluminium":
			return tr("ALUMINIUM" + desc)
		"silver":
			return tr("SILVER" + desc)
		"gold":
			return tr("GOLD" + desc)
		"amethyst":
			return tr("AMETHYST" + desc)
		"emerald":
			return tr("EMERALD" + desc)
		"quartz":
			return tr("QUARTZ" + desc)
		"topaz":
			return tr("TOPAZ" + desc)
		"ruby":
			return tr("RUBY" + desc)
		"sapphire":
			return tr("SAPPHIRE" + desc)

func _input(_event):
	if item_hovered != "":
		if Input.is_action_just_released("throw"):
			if Input.is_action_pressed("shift"):
				game.remove_items(item_hovered, item_stack)
			else:
				game.remove_items(item_hovered)
			_on_Items_pressed()
			if not game.items[item_slot]:
				item_hovered = ""
				game.hide_tooltip()
		if Input.is_action_just_released("hotbar"):
			if game.hotbar.find(item_hovered) == -1:
				game.hotbar.append(item_hovered)
			else:
				game.hotbar.erase(item_hovered)
			game.HUD.update_hotbar()
