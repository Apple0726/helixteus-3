extends Control

onready var game = get_node("/root/Game")
onready var click_sound = game.get_node("click")
onready var money_text = $Resources/Money/Text
onready var minerals_text = $Resources/Minerals/Text
onready var stone_text = $Resources/Stone/Text
onready var soil_text = $Resources/Soil/Text
onready var energy_text = $Resources/Energy/Text
onready var SP_text = $Resources/SP/Text
onready var minerals = $Resources/Minerals
onready var stone = $Resources/Stone
onready var SP = $Resources/SP
onready var ships = $Buttons/Ships
onready var shop = $Buttons/Shop
onready var craft = $Buttons/Craft
onready var MU = $Buttons/MineralUpgrades
onready var sc_tree = $Buttons/ScienceTree
onready var lv_txt = $Lv/Label
onready var lv_progress = $Lv/TextureProgress
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var on_button = false
var config = ConfigFile.new()
var tween:Tween
var ship2map

func _on_Button_pressed():
	click_sound.play()
	game.toggle_panel(game.settings)

func _ready():
	tween = Tween.new()
	add_child(tween)
	refresh()

func _process(delta):
	$AutosaveLight.modulate.g = lerp(0.3, 1, game.get_node("Autosave").time_left / game.autosave_interval)

func refresh():
	if not game:
		return
	$Panel/CollectProgress.visible = false
	$Panel/CollectAll.modulate = Color.white
	if config.load("user://settings.cfg") == OK:
		var autosave_light = config.get_value("saving", "autosave_light", false)
		if config.get_value("saving", "enable_autosave", true) and (not game.tutorial or game.tutorial.tut_num >= 26):
			set_process(autosave_light)
		else:
			$AutosaveLight.modulate.g = 0.3
			set_process(false)
		$AutosaveLight.visible = autosave_light
	var planet = game.view.obj
	if game.c_v == "planet" and planet and planet.bldg_to_construct != "":
		var money_cost = game.view.obj.constr_costs.money
		var energy_cost = game.view.obj.constr_costs.energy if game.view.obj.constr_costs.has("energy") else 0
		if not planet.shadows.empty():
			money_cost *= len(planet.shadows)
			energy_cost *= len(planet.shadows)
		money_text.text = "%s / %s" % [Helper.format_num(round(game.money), 6), Helper.format_num(round(money_cost), 6)]
		energy_text.text = "%s / %s" % [Helper.format_num(round(game.energy), 6), Helper.format_num(round(energy_cost), 6)]
		if game.money >= money_cost:
			money_text["custom_colors/font_color"] = Color.green
		else:
			money_text["custom_colors/font_color"] = Color.red
		if game.energy >= energy_cost:
			energy_text["custom_colors/font_color"] = Color.green
		else:
			energy_text["custom_colors/font_color"] = Color.red
	else:
		money_text["custom_colors/font_color"] = Color.white
		energy_text["custom_colors/font_color"] = Color.white
		money_text.text = Helper.format_num(round(game.money), 6)
		energy_text.text = Helper.format_num(game.energy, 6)
	var min_cap = round(200 + (game.mineral_capacity - 200) * Helper.get_IR_mult("MS"))
	minerals_text.text = "%s / %s" % [Helper.format_num(round(game.minerals), 6), Helper.format_num(min_cap, 6)]
	if round(game.minerals) == min_cap:
		if not $Resources/Minerals/Text.is_connected("mouse_entered", self, "_on_MineralsText_mouse_entered"):
			$Resources/Minerals/Text.connect("mouse_entered", self, "_on_MineralsText_mouse_entered")
		minerals_text["custom_colors/font_color"] = Color.red
	else:
		if $Resources/Minerals/Text.is_connected("mouse_entered", self, "_on_MineralsText_mouse_entered"):
			 $Resources/Minerals/Text.disconnect("mouse_entered", self, "_on_MineralsText_mouse_entered")
		minerals_text["custom_colors/font_color"] = Color.white
	var total_stone:float = round(Helper.get_sum_of_dict(game.stone))
	stone_text.text = Helper.format_num(total_stone, 6) + " kg"
	soil_text.text = Helper.format_num(game.clever_round(game.mats.soil, 3), 6) + " kg"
	SP_text.text = Helper.format_num(game.SP, 6)
	minerals.visible = game.show.minerals
	stone.visible = game.show.stone
	shop.visible = game.show.shop
	SP.visible = game.show.SP
	sc_tree.visible = game.show.SP
	$Buttons/Vehicles.visible = game.show.vehicles_button
	craft.visible = game.show.materials
	ships.visible = len(game.ship_data) > 0
	MU.visible = game.show.minerals
	$Panel.visible = game.show.minerals
	$ShipLocator.visible = len(game.ship_data) == 1 and game.second_ship_hints.ship_locator
	$Ship2Map.visible = len(game.ship_data) == 2 and not game.third_ship_hints.has("map_found_at")
	while game.xp >= game.xp_to_lv:
		game.lv += 1
		game.xp -= game.xp_to_lv
		game.xp_to_lv = round(game.xp_to_lv * 1.5)
		if not game.objective.empty() and game.objective.type == game.ObjectiveType.LEVEL:
			game.objective.current += 1
		if game.lv == 30:
			game.long_popup(tr("LEVEL_30_REACHED"), "%s 30" % tr("LEVEL"))
		if game.lv == 32:
			game.long_popup(tr("LEVEL_32_REACHED"), "%s 32" % tr("LEVEL"))
	lv_txt.text = tr("LV") + " %s" % [game.lv]
	lv_progress.value = game.xp / float(game.xp_to_lv)
	if OS.get_latin_keyboard_variant() == "QWERTZ":
		$Buttons/Ships.shortcut.shortcut.action = "Z"
	else:
		$Buttons/Ships.shortcut.shortcut.action = "Y"
	update_hotbar()
	if not game.objective.empty():
		if game.objective.type == game.ObjectiveType.SAVE:
			var split:Array = game.objective.data.split("/")
			var primary_resource = len(split) == 1
			if primary_resource:
				game.objective.current = game[game.objective.data]
			else:
				game.objective.current = game[split[0]][split[1]]
		elif game.objective.type == game.ObjectiveType.CRUST and game.c_v == "mining":
			game.objective.current = game.mining_HUD.tile.depth
			game.objective.goal = game.planet_data[game.c_p].crust_start_depth + 1
		if game.objective.current >= game.objective.goal:
			if game.objective.id == 0:
				game.objective = {"type":game.ObjectiveType.BUILD, "data":"RCC", "id":1, "current":0, "goal":1}
			elif game.objective.id == 1:
				game.objective = {"type":game.ObjectiveType.CAVE, "id":2, "current":0, "goal":1}
			elif game.objective.id == 3:
				game.objective = {"type":game.ObjectiveType.CRUST, "id":4, "current":game.mining_HUD.tile.depth, "goal":game.planet_data[game.c_p].crust_start_depth + 1}
			elif game.objective.id == 4:
				game.objective = {"type":game.ObjectiveType.BUILD, "data":"RL", "id":5, "current":0, "goal":4}
			elif game.objective.id == 5:
				game.objective = {"type":game.ObjectiveType.LEVEL, "id":6, "current":game.lv, "goal":8}
			elif game.objective.id == 6:
				game.objective = {"type":game.ObjectiveType.CONQUER, "data":"planet", "id":7, "current":0, "goal":1}
			elif game.objective.id == 7:
				game.objective = {"type":game.ObjectiveType.WORMHOLE, "id":8, "current":0, "goal":1}
			elif game.objective.id == 8:
				game.objective = {"type":game.ObjectiveType.LEVEL, "id":9, "current":game.lv, "goal":18}
			elif game.objective.id == 10:
				game.objective = {"type":game.ObjectiveType.DAVID, "id":11, "current":0, "goal":1}
			else:
				game.objective.clear()
				if game.tutorial:
					if game.tutorial.tut_num in [6, 9, 10, 15, 24]:
						game.tutorial.begin()
					elif game.tutorial.tut_num == 11:
						if game.money < 300:
							game.objective = {"type":game.ObjectiveType.SAVE, "data":"money", "id":-1, "current":game.money, "goal":300}
						else:
							game.tutorial.begin()
			$Objectives/TextureProgress.value = 0
	tween.stop_all()
	$Objectives.visible = not game.objective.empty()
	if $Objectives.visible:
		$Objectives/Label.visible = false
		if game.objective.type == game.ObjectiveType.BUILD:
			$Objectives/Label.text = tr("BUILD_OBJECTIVE").format({"num":game.objective.goal, "bldg":Helper.get_item_name(game.objective.data, "" if game.objective.goal == 1 else "S").to_lower()})
		elif game.objective.type == game.ObjectiveType.SAVE:
			var split:Array = game.objective.data.split("/")
			var primary_resource = len(split) == 1
			if primary_resource:
				$Objectives/Label.text = tr("SAVE_OBJECTIVE").format({"num":game.objective.goal, "rsrc":tr(split[0].to_upper()).to_lower()})
			else:
				$Objectives/Label.text = tr("SAVE_W_OBJECTIVE").format({"num":game.objective.goal, "rsrc":tr(split[1].to_upper()).to_lower()})
		elif game.objective.type == game.ObjectiveType.MINE:
			$Objectives/Label.text = tr("MINE_OBJECTIVE") % game.objective.goal
		elif game.objective.type == game.ObjectiveType.LEVEL:
			$Objectives/Label.text = tr("LEVEL_OBJECTIVE") % game.objective.goal
		elif game.objective.type == game.ObjectiveType.CONQUER:
			$Objectives/Label.text = tr("CONQUER_OBJECTIVE").format({"num":game.objective.goal, "object":tr(game.objective.data.to_upper() + ("S" if game.objective.goal > 1 else "")).to_lower()})
		elif game.objective.type == game.ObjectiveType.CAVE:
			$Objectives/Label.text = tr("CAVE_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.CRUST:
			$Objectives/Label.text = tr("CRUST_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.WORMHOLE:
			$Objectives/Label.text = tr("WORMHOLE_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.SIGNAL:
			$Objectives/Label.text = tr("SIGNAL_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.DAVID:
			$Objectives/Label.text = tr("DAVID_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.COLLECT_PARTS:
			$Objectives/Label.text = tr("COLLECT_SHIP_PARTS")
		$Objectives/Label.visible = true
		$Objectives/TextureProgress.rect_size = $Objectives/Label.rect_size
		$Objectives/TextureProgress.rect_position = $Objectives/Label.rect_position
		tween.interpolate_property($Objectives, "rect_position", null, Vector2($Objectives.rect_position.x, 36), 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property($Objectives/TextureProgress, "value", null, game.objective.current / float(game.objective.goal) * 100, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
	else:
		$Objectives.rect_position.y = 4
		

func _on_Shop_pressed():
	click_sound.play()
	if game.tutorial:
		if game.tutorial.visible and not game.shop_panel.visible and game.tutorial.tut_num == 11:
			game.tutorial.fade(0.15)
			game.toggle_panel(game.shop_panel)
		if not game.tutorial.tut_num in [11, 12, 13]:
			game.toggle_panel(game.shop_panel)
	else:
		game.toggle_panel(game.shop_panel)

func _on_Shop_mouse_entered():
	on_button = true
	game.show_tooltip(tr("SHOP") + " (R)")

func _on_Inventory_mouse_entered():
	on_button = true
	game.show_tooltip(tr("INVENTORY") + " (E)")

func _on_Inventory_pressed():
	click_sound.play()
	if game.tutorial and game.tutorial.visible:
		if not game.inventory.visible and game.tutorial.tut_num in [18, 20, 21]:
			game.tutorial.fade(0.15)
			game.inventory._on_Items_pressed()
			game.toggle_panel(game.inventory)
		if not game.tutorial.tut_num in [18, 19, 20, 21]:
			game.toggle_panel(game.inventory)
	else:
		game.toggle_panel(game.inventory)

func _on_Craft_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CRAFT") + " (T)")

func _on_Craft_pressed():
	click_sound.play()
	game.toggle_panel(game.craft_panel)

func _on_ScienceTree_pressed():
	click_sound.play()
	if game.c_v != "science_tree":
		if game.tutorial and game.tutorial.visible:
			if game.tutorial.tut_num == 24:
				game.tutorial.fade(0.15)
				game.switch_view("science_tree")
		else:
			game.switch_view("science_tree")

func _on_ScienceTree_mouse_entered():
	game.show_tooltip(tr("SCIENCE_TREE") + " (I)")

func _on_MineralUpgrades_pressed():
	game.toggle_panel(game.MU_panel)

func _on_MineralUpgrades_mouse_entered():
	game.show_tooltip(tr("MINERAL_UPGRADES") + " (U)")

func _on_Texture_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()

func update_hotbar():
	for child in $Hotbar.get_children():
		$Hotbar.remove_child(child)
		child.queue_free()
	var i:int = 0
	for item in game.hotbar:
		var slot = slot_scene.instance()
		var num = game.get_item_num(item)
		slot.get_node("Label").text = String(num)
		slot.get_node("TextureRect").texture = load("res://Graphics/" + Helper.get_dir_from_name(item)  + "/" + item + ".png")
		slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [i])
		slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
		if num > 0:
			slot.get_node("Button").connect("pressed", self, "on_slot_press", [i])
		$Hotbar.add_child(slot)
		i += 1

var slot_over = -1
func on_slot_over(i:int):
	slot_over = i
	on_button = true
	game.help_str = "hotbar_shortcuts"
	var txt = ("\n" + tr("H_FOR_HOTBAR_REMOVE") + "\n" + tr("HIDE_SHORTCUTS")) if game.help.hotbar_shortcuts else ""
	var num = " (%s)" % [i + 1] if i < 5 else ""
	game.show_tooltip(Helper.get_item_name(game.hotbar[i]) + num + txt)

func on_slot_out():
	slot_over = -1
	on_button = false
	game.hide_tooltip()

func on_slot_press(i:int):
	var name = game.hotbar[i]
	game.inventory.on_slot_press(name)

func _on_Label_mouse_entered():
	on_button = true
	game.show_tooltip((tr("LEVEL") + " %s\nXP: %s / %s\n%s") % [game.lv, Helper.format_num(game.xp, 4), Helper.format_num(game.xp_to_lv, 4), tr("XP_HELP")])


func _on_Label_mouse_exited():
	on_button = false
	game.hide_tooltip()

func _input(_event):
	if Input.is_action_just_released("H") and slot_over != -1:
		game.hotbar.remove(slot_over)
		game.hide_tooltip()
		on_button = false
		slot_over = -1
		update_hotbar()
		refresh()

func _on_CollectAll_mouse_entered():
	on_button = true
	game.show_tooltip(tr("COLLECT_ALL_%s" % tr(game.c_v).to_upper()) + " (.)")

func _on_CollectAll_pressed():
	if not $Panel/CollectProgress.visible:
		$Panel/CollectProgress.visible = true
		$Panel/CollectProgress.value = 0
		$Panel/CollectAll.modulate = Color(0.3, 0.3, 0.3, 1)
		game.view.obj.collect_all()

func _on_ConvertMinerals_mouse_entered():
	on_button = true
	game.show_tooltip(tr("SELL_MINERALS") + " (,)")

func _on_ConvertMinerals_pressed():
	game.sell_all_minerals()
	if game.tutorial and game.tutorial.tut_num == 8 and not game.tutorial.tween.is_active():
		game.tutorial.fade()

func _on_Ships_pressed():
	game.toggle_panel(game.ship_panel)

func _on_Ships_mouse_entered():
	on_button = true
	game.show_tooltip("%s (%s)" % [tr("SHIPS"), $Buttons/Ships.shortcut.shortcut.action])


func _on_AutosaveLight_mouse_entered():
	if game.help.autosave_light_desc:
		game.help_str = "autosave_light_desc"
		game.show_tooltip("%s\n%s" % [tr("AUTOSAVE_LIGHT_DESC"), tr("HIDE_HELP")])

func _on_ShipLocator_pressed():
	if game.c_v == "galaxy":
		game.put_bottom_info(tr("LOCATE_SHIP_HELP"), "locating_ship", "hide_ship_locator")
		game.show_ship_locator()


func _on_ShipLocator_mouse_entered():
	if game.c_v == "galaxy":
		game.show_tooltip(tr("LOCATE_SHIP"))
	else:
		game.show_tooltip(tr("SHIP_LOCATOR_ERROR"))

func _on_MineralsText_mouse_entered():
	game.show_tooltip(tr("FULL_MINERALS"))

func _on_Ship2Map_mouse_entered():
	game.show_tooltip(tr("GALAXY_MAP"))


func _on_Ship2Map_pressed():
	if ship2map:
		remove_child(ship2map)
		ship2map = null
	else:
		ship2map = load("res://Scenes/Ship2Map.tscn").instance()
		add_child(ship2map)
		ship2map.refresh()

func _on_Vehicles_mouse_entered():
	on_button = true
	game.show_tooltip(tr("VEHICLES") + " (V)")

func _on_Vehicles_pressed():
	if not Input.is_action_pressed("shift"):
		click_sound.play()
		game.toggle_panel(game.vehicle_panel)
