extends Control

@onready var game = get_node("/root/Game")
@onready var click_sound = game.get_node("click")
@onready var money_text = $Top/Resources/Money/Text
@onready var minerals_text = $Top/Resources/Minerals/Text
@onready var stone_text = $Top/Resources/Stone/Text
@onready var soil_text = $Top/Resources/Soil/Text
@onready var energy_text = $Top/Resources/Energy/Text
@onready var glass_text = $Top/Resources/Glass/Text
@onready var cellulose_text = $Top/Resources/Cellulose/Text
@onready var SP_text = $Top/Resources/SP/Text
@onready var minerals = $Top/Resources/Minerals
@onready var stone = $Top/Resources/Stone
@onready var SP = $Top/Resources/SP
@onready var ships = $Buttons/Ships
@onready var shop = $Buttons/Shop
@onready var craft = $Buttons/Craft
@onready var MU = $Buttons/MineralUpgrades
@onready var sc_tree = $Buttons/ScienceTree
@onready var lv_txt = $Top/Lv/Level
@onready var lv_progress = $Top/Lv/TextureProgressBar
@onready var bookmark_btns = $Bookmarks/BookmarksList/Buttons/VBoxContainer
@onready var planet_b_btn = $Bookmarks/BookMarkButtons/Planets
@onready var system_b_btn = $Bookmarks/BookMarkButtons/Systems
@onready var galaxy_b_btn = $Bookmarks/BookMarkButtons/Galaxies
@onready var cluster_b_btn = $Bookmarks/BookMarkButtons/Clusters
@onready var dimension_btn = $Bottom/DimensionBtn
@onready var switch_btn = $Bottom/SwitchBtn
@onready var prev_btn = $Bottom/PrevView
@onready var next_btn = $Bottom/NextView
@onready var ships_btn = $Buttons/Ships
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var on_button = false
var config = ConfigFile.new()
var ship2map
var emma_cave_shortcut:bool = false
var current_bookmark_type:String = "planet"

func _on_Button_pressed():
	click_sound.play()
	game.toggle_panel(game.settings)

func _ready():
	refresh_bookmarks()
	refresh_visibility()

func refresh_visibility():
	minerals.visible = game.show.has("minerals")
	$Bottom/Panel.visible = game.show.has("minerals")
	shop.visible = game.show.has("shop")
	stone.visible = game.show.has("stone")
	SP.visible = game.show.has("SP")
	sc_tree.visible = game.show.has("SP")
	$Buttons/Vehicles.visible = game.show.has("vehicles_button")
	craft.visible = game.show.has("materials")
	ships.visible = len(game.ship_data) > 0
	MU.visible = game.show.has("minerals")
	$Top/Resources/Cellulose.visible = game.science_unlocked.has("SA")

func refresh_bookmarks():
	for btn in bookmark_btns.get_children():
		btn.queue_free()
	if current_bookmark_type == "planet":
		for p_b in game.bookmarks.planet.values():
			add_p_b(p_b)
	elif current_bookmark_type == "system":
		for s_b in game.bookmarks.system.values():
			add_s_b(s_b)
	elif current_bookmark_type == "galaxy":
		for g_b in game.bookmarks.galaxy.values():
			add_g_b(g_b)
	elif current_bookmark_type == "cluster":
		for c_b in game.bookmarks.cluster.values():
			add_c_b(c_b)

func add_p_b(p_b:Dictionary):
	var btn = Button.new()
	btn.text = game.bookmarks.planet[str(p_b.c_p_g)].name
	btn.connect("pressed",Callable(self,"on_bookmark_pressed").bind("planet", p_b))
	bookmark_btns.add_child(btn)

func add_s_b(s_b:Dictionary):
	var btn = Button.new()
	btn.text = game.bookmarks.system[str(s_b.c_s_g)].name
	btn.connect("pressed",Callable(self,"on_bookmark_pressed").bind("system", s_b))
	bookmark_btns.add_child(btn)

func add_g_b(g_b:Dictionary):
	var btn = Button.new()
	btn.text = game.bookmarks.galaxy[str(g_b.c_g_g)].name
	btn.connect("pressed",Callable(self,"on_bookmark_pressed").bind("galaxy", g_b))
	bookmark_btns.add_child(btn)

func add_c_b(c_b:Dictionary):
	var btn = Button.new()
	btn.text = game.bookmarks.cluster[str(c_b.c_c)].name
	btn.connect("pressed",Callable(self,"on_bookmark_pressed").bind("cluster", c_b))
	bookmark_btns.add_child(btn)

func on_bookmark_pressed(view:String, bookmark:Dictionary):
	game.switch_view(view, {"fn":"set_bookmark_coords", "fn_args":[bookmark]})

func _process(delta):
	$Top/AutosaveLight.modulate.g = lerp(0.3, 1.0, game.get_node("Autosave").time_left / Settings.autosave_interval)

func update_XP():
	while game.u_i.xp >= game.u_i.xp_to_lv:
		game.u_i.lv += 1
		game.u_i.xp -= game.u_i.xp_to_lv
		game.u_i.xp_to_lv = round(game.u_i.xp_to_lv * game.maths_bonus.ULUGF)
		if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.LEVEL:
			game.objective.current += 1
		if game.subject_levels.dimensional_power == 0:
			if game.u_i.lv == 28:
				game.popup_window(tr("LEVEL_28_REACHED"), "%s 28" % tr("LEVEL"))
			if game.u_i.lv == 32:
				game.popup_window(tr("LEVEL_32_REACHED"), "%s 32" % tr("LEVEL"))
			if game.u_i.lv == 55:
				game.popup_window(tr("LEVEL_55_REACHED"), "%s 55" % tr("LEVEL"))
		if game.u_i.lv == 60:
			game.new_bldgs[Building.PROBE_CONSTRUCTION_CENTER] = true
			game.popup_window(tr("LEVEL_60_REACHED"), "%s 60" % tr("LEVEL"))
	var d_u_info = ""
	if game.dim_num > 1 or len(game.universe_data) > 1:
		d_u_info = " (Dim #%s, Univ %s)" % [game.dim_num, game.c_u + 1]
	Helper.refresh_discord("Level %s%s" % [game.u_i.lv, d_u_info])
	lv_txt.text = tr("LV") + " %s" % [game.u_i.lv]
	lv_progress.value = game.u_i.xp / float(game.u_i.xp_to_lv)

func update_minerals():
	var min_cap = round(200 + (game.mineral_capacity - 200) * Helper.get_IR_mult(Building.MINERAL_SILO))
	minerals_text.text = "%s / %s" % [Helper.format_num(round(game.minerals)), Helper.format_num(min_cap)]
	if game.minerals >= min_cap:
		if not game.science_unlocked.has("ASM") and not $Bottom/Panel/AnimationPlayer.is_playing():
			$Bottom/Panel/AnimationPlayer.play("Flash")
	else:
		if $Top/Resources/Minerals/Text.is_connected("mouse_entered",Callable(self,"_on_MineralsText_mouse_entered")):
			$Top/Resources/Minerals/Text.disconnect("mouse_entered",Callable(self,"_on_MineralsText_mouse_entered"))

func update_money_energy_SP():
	var planet = game.view.obj
	if game.c_v == "planet" and is_instance_valid(planet) and planet.bldg_to_construct != -1:
		var money_cost = game.view.obj.constr_costs_total.money
		var energy_cost = game.view.obj.constr_costs_total.get("energy", 0.0)
		var SP_cost = game.view.obj.constr_costs_total.get("SP", 0.0)
		var glass_cost = game.view.obj.constr_costs_total.get("glass", 0.0)
		var soil_cost = game.view.obj.constr_costs_total.get("soil", 0.0)
		money_text.text = "%s / %s" % [Helper.format_num(round(game.money)), Helper.format_num(round(money_cost))]
		energy_text.text = "%s / %s" % [Helper.format_num(round(game.energy)), Helper.format_num(round(energy_cost))]
		SP_text.text = "%s / %s" % [Helper.format_num(round(game.SP)), Helper.format_num(round(SP_cost))]
		glass_text.text = "%s / %s kg" % [Helper.format_num(round(game.mats.glass)), Helper.format_num(round(glass_cost))]
		soil_text.text = "%s / %s kg" % [Helper.format_num(round(game.mats.soil)), Helper.format_num(round(soil_cost))]
		money_text["theme_override_colors/font_color"] = Color.GREEN if game.money >= money_cost else Color.RED
		energy_text["theme_override_colors/font_color"] = Color.GREEN if game.energy >= energy_cost else Color.RED
		SP_text["theme_override_colors/font_color"] = Color.GREEN if game.SP >= SP_cost else Color.RED
		glass_text["theme_override_colors/font_color"] = Color.GREEN if game.mats.glass >= glass_cost else Color.RED
		soil_text["theme_override_colors/font_color"] = Color.GREEN if game.mats.soil >= soil_cost else Color.RED
	else:
		money_text["theme_override_colors/font_color"] = Color.WHITE
		energy_text["theme_override_colors/font_color"] = Color.WHITE
		SP_text["theme_override_colors/font_color"] = Color.WHITE
		money_text.text = Helper.format_num(round(game.money))
		energy_text.text = "%s / %s" % [Helper.format_num(round(game.energy)), Helper.format_num(round(Helper.get_total_energy_cap()))]
		SP_text.text = Helper.format_num(round(game.SP))
		$Top/Resources/Soil.visible = game.autocollect.mats.has("soil")
		soil_text.text = "%s kg" % Helper.format_num(game.mats.soil, true)
		soil_text["theme_override_colors/font_color"] = Color.WHITE if game.mats.soil > 0 else Color.RED
	if $Top/Resources/Cellulose.visible:
		cellulose_text.text = "%s kg" % Helper.format_num(game.mats.cellulose, true)
		cellulose_text["theme_override_colors/font_color"] = Color.WHITE if game.mats.cellulose > 0 else Color.RED
	var total_stone:float = round(Helper.get_sum_of_dict(game.stone))
	stone_text.text = Helper.format_num(total_stone) + " kg"
	
func refresh():
	if not game:
		return
	$Top/Name/Name.caret_blink_interval = 0.5 / game.u_i.time_speed
	prev_btn.visible = game.view_history_pos > 0 and game.c_v in ["universe", "supercluster", "cluster", "galaxy", "system", "planet"]
	next_btn.visible = game.view_history_pos != len(game.view_history) - 1 and game.c_v in ["universe", "supercluster", "cluster", "galaxy", "system", "planet"]
	dimension_btn.visible = (len(game.universe_data) > 1 or not game.help.has("hide_dimension_stuff")) and game.c_v in ["supercluster", "cluster", "galaxy", "system", "planet"]
	switch_btn.visible = game.c_v in ["planet", "system", "galaxy", "cluster", "supercluster", "universe"]
	if config.load("user://settings.cfg") == OK:
		var autosave_light = config.get_value("saving", "autosave_light", false)
		if config.get_value("saving", "enable_autosave", true):
			set_process(autosave_light)
		else:
			$Top/AutosaveLight.modulate.g = 0.3
			set_process(false)
		$Top/AutosaveLight.visible = autosave_light
	update_money_energy_SP()
	update_minerals()
	if $Top/Resources/Glass.visible:
		var GH_glass_cost = Data.costs[Building.GREENHOUSE].glass * game.engineering_bonus.BCM
		if game.mats.glass >= GH_glass_cost:
			glass_text["theme_override_colors/font_color"] = Color.GREEN
		else:
			glass_text["theme_override_colors/font_color"] = Color.RED
		glass_text.text = "%s / %s kg" % [Helper.format_num(game.mats.glass, true), GH_glass_cost]
	update_XP()
	update_hotbar()
	if not game.objective.is_empty():
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
			if game.objective.id == 0:#Build 10 mineral silos
				game.objective = {"type":game.ObjectiveType.BUILD, "data":"MS", "id":1, "current":0, "goal":10}
			elif game.objective.id == 1:#Purchase a mineral upgrade
				game.objective = {"type":game.ObjectiveType.MINERAL_UPG, "id":2, "current":0, "goal":1}
			elif game.objective.id == 2:#Build 1 rover constr center
				game.objective = {"type":game.ObjectiveType.BUILD, "data":"RCC", "id":3, "current":0, "goal":1}
			elif game.objective.id == 3:#Explore a cave
				game.objective = {"type":game.ObjectiveType.CAVE, "id":4, "current":0, "goal":1}
			elif game.objective.id == 4:#Mine 3 tiles
				game.objective = {"type":game.ObjectiveType.MINE, "id":5, "current":0, "goal":3}
			elif game.objective.id == 5:#Reach the crust
				game.objective = {"type":game.ObjectiveType.CRUST, "id":6, "current":game.mining_HUD.tile.depth, "goal":game.planet_data[game.c_p].crust_start_depth + 1}
			elif game.objective.id == 6:#Build 4 research labs
				game.objective = {"type":game.ObjectiveType.BUILD, "data":"RL", "id":7, "current":0, "goal":4}
			elif game.objective.id == 7:#Reach level 8
				game.objective = {"type":game.ObjectiveType.LEVEL, "id":8, "current":game.u_i.lv, "goal":8}
			elif game.objective.id == 8:#Conquer a planet
				game.objective = {"type":game.ObjectiveType.CONQUER, "data":"planet", "id":9, "current":0, "goal":1}
			elif game.objective.id == 9:#Find wormhole
				game.objective = {"type":game.ObjectiveType.WORMHOLE, "id":10, "current":0, "goal":1}
			elif game.objective.id == 10:#Reach level 18
				game.objective = {"type":game.ObjectiveType.LEVEL, "id":-1, "current":game.u_i.lv, "goal":18}
			elif game.objective.id == 11:
				game.objective = {"type":game.ObjectiveType.DAVID, "id":-1, "current":0, "goal":1}
			elif game.objective.id == 12:
				game.objective = {"type":game.ObjectiveType.EMMA, "id":-1, "current":0, "goal":1}
			else:
				game.objective.clear()
			$Top/Objectives/TextureProgressBar.value = 0
	$Top/Objectives.visible = not game.objective.is_empty()
	if $Top/Objectives.visible:
		$Top/Objectives/Label.visible = false
		if game.objective.type == game.ObjectiveType.BUILD:
			$Top/Objectives/Label.text = tr("BUILD_OBJECTIVE").format({"num":game.objective.goal, "bldg":tr("%s_NAME%s" % [game.objective.data.to_upper(), "" if game.objective.goal == 1 else "_S"]).to_lower()})
		elif game.objective.type == game.ObjectiveType.SAVE:
			var split:Array = game.objective.data.split("/")
			var primary_resource = len(split) == 1
			if primary_resource:
				$Top/Objectives/Label.text = tr("SAVE_OBJECTIVE").format({"num":game.objective.goal, "rsrc":tr(split[0].to_upper()).to_lower()})
			else:
				$Top/Objectives/Label.text = tr("SAVE_W_OBJECTIVE").format({"num":game.objective.goal, "rsrc":tr(split[1].to_upper()).to_lower()})
		elif game.objective.type == game.ObjectiveType.MINE:
			$Top/Objectives/Label.text = tr("MINE_OBJECTIVE") % game.objective.goal
		elif game.objective.type == game.ObjectiveType.LEVEL:
			$Top/Objectives/Label.text = tr("LEVEL_OBJECTIVE") % game.objective.goal
		elif game.objective.type == game.ObjectiveType.CONQUER:
			$Top/Objectives/Label.text = tr("CONQUER_OBJECTIVE").format({"num":game.objective.goal, "object":tr(game.objective.data.to_upper() + ("S" if game.objective.goal > 1 else "")).to_lower()})
		elif game.objective.type == game.ObjectiveType.CAVE:
			$Top/Objectives/Label.text = tr("CAVE_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.CRUST:
			$Top/Objectives/Label.text = tr("CRUST_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.WORMHOLE:
			$Top/Objectives/Label.text = tr("WORMHOLE_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.SIGNAL:
			$Top/Objectives/Label.text = tr("SIGNAL_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.DAVID:
			$Top/Objectives/Label.text = tr("DAVID_OBJECTIVE")
		elif game.objective.type == game.ObjectiveType.COLLECT_PARTS:
			$Top/Objectives/Label.text = tr("COLLECT_SHIP_PARTS")
		elif game.objective.type == game.ObjectiveType.MANIPULATORS:
			$Top/Objectives/Label.text = tr("FIND_GEM_MANIPULATORS")
		elif game.objective.type == game.ObjectiveType.EMMA:
			$Top/Objectives/Label.text = tr("SELECT_EMMA_CAVE")
		elif game.objective.type == game.ObjectiveType.UPGRADE:
			$Top/Objectives/Label.text = tr("UPGRADE_BLDG")
		elif game.objective.type == game.ObjectiveType.MINERAL_UPG:
			$Top/Objectives/Label.text = tr("PURCHASE_MIN_UPG")
		$Top/Objectives/Label.visible = true
		$Top/Objectives/TextureProgressBar.size = $Top/Objectives/Label.size
		$Top/Objectives/TextureProgressBar.position = $Top/Objectives/Label.position
	else:
		$Top/Objectives.position.y = 4
	$Bookmarks.visible = game.show.has("bookmarks") and game.c_v != "science_tree"
	system_b_btn.visible = game.show.has("s_bk_button")
	galaxy_b_btn.visible = game.show.has("g_bk_button")
	cluster_b_btn.visible = game.show.has("c_bk_button")
	if game.c_v == "planet":
		$Bookmarks/Bookmarked.button_pressed = game.planet_data[game.c_p].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.planet_data[game.c_p].name
	elif game.c_v == "system":
		$Bookmarks/Bookmarked.button_pressed = game.system_data[game.c_s].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.system_data[game.c_s].name
	elif game.c_v == "galaxy":
		$Bookmarks/Bookmarked.button_pressed = game.galaxy_data[game.c_g].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.galaxy_data[game.c_g].name
	elif game.c_v == "cluster":
		$Bookmarks/Bookmarked.button_pressed = game.u_i.cluster_data[game.c_c].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.u_i.cluster_data[game.c_c].name
	else:
		$Bookmarks/Bookmarked.visible = false
		if game.c_v == "universe":
			$Top/Name/Name.text = game.u_i.name
	for view in $Bottom/ViewHistory/VBox.get_children():
		view.queue_free()
	for view in game.view_history:
		var label = Label.new()
		label.text = "%s p %s, s %s" % [view.view, view.c_p_g, view.c_s_g]
		$Bottom/ViewHistory/VBox.add_child(label)
	await get_tree().process_frame
	game.refresh_achievements()

func _on_Shop_pressed():
	click_sound.play()
	game.toggle_panel(game.shop_panel)

func _on_Shop_mouse_entered():
	game.show_tooltip(tr("SHOP") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_R)))

func _on_Inventory_mouse_entered():
	game.show_tooltip(tr("INVENTORY") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_E)))

func _on_Inventory_pressed():
	click_sound.play()
	game.toggle_panel(game.inventory)

func _on_Craft_mouse_entered():
	game.show_tooltip(tr("CRAFT") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_T)))

func _on_Craft_pressed():
	click_sound.play()
	game.toggle_panel(game.craft_panel)

func _on_ScienceTree_pressed():
	click_sound.play()
	if game.c_v != "science_tree":
		game.switch_view("science_tree")

func _on_ScienceTree_mouse_entered():
	game.show_tooltip(tr("SCIENCE_TREE") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_I)))

func _on_MineralUpgrades_pressed():
	game.toggle_panel(game.MU_panel)

func _on_MineralUpgrades_mouse_entered():
	game.show_tooltip(tr("MINERAL_UPGRADES") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_U)))

func _on_Texture_mouse_entered(extra_arg_0):
	var tooltip:String = tr(extra_arg_0)
	if extra_arg_0 == "CELLULOSE":
		if game.autocollect.mats.cellulose > 0:
			tooltip += "\n" + tr("YOU_PRODUCE") % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mats.cellulose), true), tr("S_SECOND")])
		else:
			tooltip += "\n" + tr("YOU_USE") % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mats.cellulose), true), tr("S_SECOND")])
			if not is_zero_approx(game.autocollect.mats.cellulose):
				tooltip += " (%s)" % tr("OUT_OF_X_IN").format({"rsrc":tr("CELLULOSE"), "time":Helper.time_to_str(game.mats.cellulose / abs(game.autocollect.mats.cellulose))})
	elif extra_arg_0 == "SOIL" and game.autocollect.mats.has("soil"):
		tooltip += "\n" + tr("YOU_USE") % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mats.soil), true), tr("S_SECOND")])
		if not is_zero_approx(game.autocollect.mats.soil):
			tooltip += " (%s)" % tr("OUT_OF_X_IN").format({"rsrc":tr("SOIL"), "time":Helper.time_to_str(game.mats.soil / abs(game.autocollect.mats.soil))})
	elif game.autocollect.has("rsrc"):
		var min_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.MEE) * game.u_i.time_speed
		var energy_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.EPE) * game.u_i.time_speed
		var SP_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.RLE) * game.u_i.time_speed
		var rsrc_amount = 0.0
		if extra_arg_0 == "MINERALS":
			rsrc_amount = (game.autocollect.rsrc.minerals + game.autocollect.GS.minerals + game.autocollect.MS.minerals) * min_mult + (game.autocollect.mats.get("minerals", 0) if game.mats.cellulose > 0 else 0)
			tooltip += "\n" + tr("YOU_PRODUCE") % ("%s/%s" % [Helper.format_num(rsrc_amount, true), tr("S_SECOND")])
		elif extra_arg_0 == "ENERGY":
			rsrc_amount = (game.autocollect.rsrc.energy + game.autocollect.GS.energy + game.autocollect.MS.energy) * energy_mult
			tooltip += "\n" + tr("YOU_PRODUCE") % ("%s/%s" % [Helper.format_num(rsrc_amount, true), tr("S_SECOND")])
		elif extra_arg_0 == "SP":
			rsrc_amount = (game.autocollect.rsrc.SP + game.autocollect.GS.SP + game.autocollect.MS.SP) * SP_mult
			tooltip += "\n" + tr("YOU_PRODUCE") % ("%s/%s" % [Helper.format_num(rsrc_amount, true), tr("S_SECOND")])
	if extra_arg_0 == "STONE" and tooltip == "Stone" and Settings.op_cursor:
		tooltip = "Rok"
	game.show_tooltip(tooltip)

func _on_mouse_exited():
	game.hide_tooltip()

func update_hotbar():
	for child in $Bottom/Hotbar.get_children():
		child.queue_free()
	var i:int = 0
	for item in game.hotbar:
		var slot = slot_scene.instantiate()
		var num = game.get_item_num(item)
		slot.get_node("Label").text = str(num)
		slot.get_node("TextureRect").texture = load("res://Graphics/" + Helper.get_dir_from_name(item)  + "/" + item + ".png")
		slot.get_node("Button").connect("mouse_entered",Callable(self,"on_slot_over").bind(i))
		slot.get_node("Button").connect("mouse_exited",Callable(self,"on_slot_out"))
		if num > 0:
			slot.get_node("Button").connect("pressed",Callable(self,"on_slot_press").bind(i))
		$Bottom/Hotbar.add_child(slot)
		i += 1

var slot_over = -1
func on_slot_over(i:int):
	slot_over = i
	game.help_str = "hotbar_shortcuts"
	var txt = ("\n" + tr("H_FOR_HOTBAR_REMOVE") + "\n" + tr("HIDE_SHORTCUTS")) if game.help.has("hotbar_shortcuts") else ""
	var num = " (%s)" % [i + 1] if i < 10 else ""
	game.show_tooltip(Helper.get_item_name(game.hotbar[i]) + num + txt)

func on_slot_out():
	slot_over = -1
	game.hide_tooltip()

func on_slot_press(i:int):
	var name = game.hotbar[i]
	game.inventory.on_slot_press(name)

func _on_Label_mouse_exited():
	emma_cave_shortcut = false
	game.hide_tooltip()

var bookmark_shown:bool = false
func _input(event):
	if Input.is_action_just_released("H") and slot_over != -1:
		game.hotbar.remove_at(slot_over)
		game.hide_tooltip()
		slot_over = -1
		update_hotbar()
		refresh()
	if Input.is_action_just_released("F2") and game.c_v in ["planet", "system", "galaxy", "cluster", "universe"]:
		$Top/Name/Name.grab_focus()
	if event is InputEventMouseMotion:
		if bookmark_shown and not Geometry2D.is_point_in_polygon(event.position, $MouseOut.polygon):
			bookmark_shown = false
			$AnimationPlayer.play_backwards("BookmarkAnim")
		if not bookmark_shown and Geometry2D.is_point_in_polygon(event.position, $MouseIn.polygon):
			bookmark_shown = true
			$AnimationPlayer.play("BookmarkAnim")
		$Nice.position = event.position

func _on_ConvertMinerals_mouse_entered():
	game.show_tooltip(tr("SELL_MINERALS") + " (%s)" % OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_COMMA)))

func _on_ConvertMinerals_pressed():
	game.sell_all_minerals()
	$Bottom/Panel/AnimationPlayer.stop()
	$Bottom/Panel/ColorRect.color.a = 0.0

func _on_Ships_pressed():
	game.toggle_panel(game.ship_panel)

func _on_Ships_mouse_entered():
	game.show_tooltip("%s (%s)" % [tr("SHIPS"), OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_Y))])


func _on_AutosaveLight_mouse_entered():
	game.help_str = "autosave_light_desc"
	if game.help.has("autosave_light_desc"):
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
	if is_instance_valid(ship2map):
		remove_child(ship2map)
		ship2map.queue_free()
	else:
		ship2map = load("res://Scenes/Ship2Map.tscn").instantiate()
		add_child(ship2map)
		ship2map.refresh()

func _on_Vehicles_mouse_entered():
	game.show_tooltip(tr("VEHICLES") + " (V)")

func _on_Vehicles_pressed():
	if not Input.is_action_pressed("shift"):
		click_sound.play()
		game.toggle_panel(game.vehicle_panel)

func _on_ObjectivesLabel_mouse_entered():
	if game.objective.type == game.ObjectiveType.EMMA:
		emma_cave_shortcut = true


func _on_Wiki_mouse_entered():
	game.show_tooltip(tr("INGAME_WIKI"))


func _on_Wiki_pressed():
	game.toggle_panel(game.wiki)


func _on_Dialogue_dialogue_finished(_NPC_id:int, _dialogue_id:int):
	$Dialogue.NPC_id = -1

func _on_Planets_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 1.0
	system_b_btn.get_node("TextureRect").modulate.a = 0.5
	galaxy_b_btn.get_node("TextureRect").modulate.a = 0.5
	cluster_b_btn.get_node("TextureRect").modulate.a = 0.5
	current_bookmark_type = "planet"
	refresh_bookmarks()

func _on_Systems_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 1.0
	galaxy_b_btn.get_node("TextureRect").modulate.a = 0.5
	cluster_b_btn.get_node("TextureRect").modulate.a = 0.5
	current_bookmark_type = "system"
	refresh_bookmarks()

func _on_Galaxies_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 0.5
	galaxy_b_btn.get_node("TextureRect").modulate.a = 1.0
	cluster_b_btn.get_node("TextureRect").modulate.a = 0.5
	current_bookmark_type = "galaxy"
	refresh_bookmarks()

func _on_Clusters_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 0.5
	galaxy_b_btn.get_node("TextureRect").modulate.a = 0.5
	cluster_b_btn.get_node("TextureRect").modulate.a = 1.0
	current_bookmark_type = "cluster"
	refresh_bookmarks()

func _on_Bookmarked_pressed():
	if game.c_v == "planet":
		var p_i:Dictionary = game.planet_data[game.c_p]
		if p_i.has("bookmarked"):
			game.bookmarks.planet.erase(str(game.c_p_g))
			p_i.erase("bookmarked")
		else:
			var bookmark:Dictionary = {
				"type":p_i.type,
				"name":p_i.name,
				"c_p":game.c_p,
				"c_p_g":game.c_p_g,
				"c_s":game.c_s,
				"c_s_g":game.c_s_g,
				"c_g":game.c_g,
				"c_g_g":game.c_g_g,
				"c_c":game.c_c}
			p_i.bookmarked = true
			game.bookmarks.planet[str(game.c_p_g)] = bookmark
	elif game.c_v == "system":
		var s_i:Dictionary = game.system_data[game.c_s]
		if s_i.has("bookmarked"):
			game.bookmarks.system.erase(str(game.c_s_g))
			s_i.erase("bookmarked")
		else:
			var star:Dictionary = s_i.stars[0]
			for i in range(1, len(s_i.stars)):
				if s_i.stars[i].luminosity > star.luminosity:
					star = s_i.stars[i]
			var bookmark:Dictionary = {
				"modulate":Helper.get_star_modulate(star["class"]),
				"name":s_i.name,
				"c_s":game.c_s,
				"c_s_g":game.c_s_g,
				"c_g":game.c_g,
				"c_g_g":game.c_g_g,
				"c_c":game.c_c}
			s_i.bookmarked = true
			game.bookmarks.system[str(game.c_s_g)] = bookmark
	elif game.c_v == "galaxy":
		var g_i:Dictionary = game.galaxy_data[game.c_g]
		if g_i.has("bookmarked"):
			game.bookmarks.galaxy.erase(str(game.c_g_g))
			g_i.erase("bookmarked")
		else:
			var bookmark:Dictionary = {
				"type":g_i.type,
				"name":g_i.name,
				"c_g":game.c_g,
				"c_g_g":game.c_g_g,
				"c_c":game.c_c}
			g_i.bookmarked = true
			game.bookmarks.galaxy[str(game.c_g_g)] = bookmark
	elif game.c_v == "cluster":
		var c_i:Dictionary = game.u_i.cluster_data[game.c_c]
		if c_i.has("bookmarked"):
			game.bookmarks.cluster.erase(str(game.c_c))
			c_i.erase("bookmarked")
		else:
			var bookmark:Dictionary = {
				"name":c_i.name,
				"c_c":game.c_c}
			c_i.bookmarked = true
			game.bookmarks.cluster[str(game.c_c)] = bookmark
	refresh_bookmarks()

func _on_Bookmarked_mouse_entered():
	if $Bookmarks/Bookmarked.button_pressed:
		game.show_tooltip("%s (B)" % tr("REMOVE_FROM_BOOKMARKS"))
	else:
		game.show_tooltip("%s (B)" % tr("ADD_TO_BOOKMARKS"))


func _on_Bookmarked_mouse_exited():
	game.hide_tooltip()


func _on_Planets_mouse_entered():
	game.show_tooltip(tr("PLANETS"))


func _on_Systems_mouse_entered():
	game.show_tooltip(tr("STAR_SYSTEMS"))


func _on_Galaxies_mouse_entered():
	game.show_tooltip(tr("GALAXIES"))


func _on_Clusters_mouse_entered():
	game.show_tooltip(tr("CLUSTERS"))


func _on_Name_text_entered(new_text):
	$Top/Name/Name.release_focus()
	if game.c_v == "planet":
		game.planet_data[game.c_p].name = new_text
		if new_text.substr(0, 9).to_lower() == "bad apple":
			var LOD = 1
			var e = 9
			while len(new_text) > e and new_text[e] == "!":
				LOD += 1
				e += 1
			game.view.obj.play_bad_apple(LOD)
		if game.bookmarks.planet.has(str(game.c_p_g)):
			game.bookmarks.planet[str(game.c_p_g)].name = new_text
	elif game.c_v == "system":
		game.system_data[game.c_s].name = new_text
		if game.bookmarks.system.has(str(game.c_s_g)):
			game.bookmarks.system[str(game.c_s_g)].name = new_text
	elif game.c_v == "galaxy":
		game.galaxy_data[game.c_g].name = new_text
		if game.bookmarks.galaxy.has(str(game.c_g_g)):
			game.bookmarks.galaxy[str(game.c_g_g)].name = new_text
	elif game.c_v == "cluster":
		game.u_i.cluster_data[game.c_c].name = new_text
		if game.bookmarks.cluster.has(str(game.c_c)):
			game.bookmarks.cluster[str(game.c_c)].name = new_text
	elif game.c_v == "universe":
		game.u_i.name = new_text
	refresh_bookmarks()


func _on_Dimension_pressed():
	game.switch_view("dimension")


func _on_Dimension_mouse_entered():
	game.show_tooltip(tr("VIEW_DIMENSION"))


func _on_SwitchBtn_mouse_entered():
	var u_i:Dictionary = game.u_i
	var view_str:String = ""
	if game.c_v == "universe":
		view_str = tr("VIEW_DIMENSION")
		if not game.show.has("dimensions") and game.help.has("flash_send_probe_btn"):
			view_str += "\n%s" %tr("CONSTR_TP_TO_UNLOCK")
	elif game.c_v == "cluster":
		view_str = tr("VIEW_UNIVERSE")
		if u_i.lv < 60:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 60"]]
	elif game.c_v == "galaxy":
		view_str = tr("VIEW_CLUSTER")
		if u_i.lv < 40:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 40"]]
	elif game.c_v == "system":
		view_str = tr("VIEW_GALAXY")
		if u_i.lv < 18:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 18"]]
	elif game.c_v == "planet":
		view_str = tr("VIEW_STAR_SYSTEM")
		if u_i.lv < 8:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 8"]]
	game.show_tooltip("%s (%s)" % [view_str, OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_Z))])

func _on_SwitchBtn_pressed():
	var u_i:Dictionary = game.u_i
	match game.c_v:
		"planet":
			if u_i.lv >= 8:
				game.switch_view("system")
		"system":
			if u_i.lv >= 18:
				game.switch_view("galaxy")
		"galaxy":
			if u_i.lv >= 40:
				game.switch_view("cluster")
		"cluster":
			if u_i.lv >= 60:
				game.switch_view("universe")
		"universe":
			if game.show.has("dimensions") or not game.help.has("flash_send_probe_btn"):
				game.switch_view("dimension")

func _on_Stats_mouse_entered():
	game.show_tooltip("%s & %s" % [tr("ACHIEVEMENTS"), tr("STATISTICS")])


func _on_Stats_pressed():
	game.toggle_panel(game.stats_panel)


func _on_PrevView_pressed():
	set_view_and_switch(-1)

func _on_NextView_pressed():
	set_view_and_switch(1)

func set_view_and_switch(shift:int):
	var view_data:Dictionary = game.view_history[game.view_history_pos + shift].duplicate(true)
	var view:String = view_data.view
	view_data.erase("view")
	game.switch_view(view, {"fn":"set_custom_coords", "fn_args":[view_data.keys(), view_data.values()], "shift":shift})

func _on_PrevView_mouse_entered():
	game.show_tooltip(tr("PREV_VIEW"))

func _on_NextView_mouse_entered():
	game.show_tooltip(tr("NEXT_VIEW"))


func _on_HUD_tree_entered():
	$AnimationPlayer2.play("MoveStuff")


func _on_MainMenu_mouse_entered():
	game.show_tooltip(tr("RETURN_TO_MENU"))


func _on_MainMenu_pressed():
	game.show_YN_panel("return_to_menu", tr("ARE_YOU_SURE"))

func set_ship_btn_shader(active:bool, tier:int = -1):
	ships_btn.material.set_shader_parameter("active", active)
	if tier != -1:
		ships_btn.material.set_shader_parameter("color", Data.tier_colors[tier - 1])
		ships_btn.material.set_shader_parameter("speed", tier * game.u_i.time_speed)
		await get_tree().process_frame
		game.ship_panel.get_node("SpaceportTimer").start(4.0 / tier)

func _on_level_mouse_entered():
	game.show_tooltip((tr("LEVEL") + " %s\nXP: %s / %s\n%s") % [game.u_i.lv, Helper.format_num(round(game.u_i.xp), 4), Helper.format_num(game.u_i.xp_to_lv, 4), tr("XP_HELP")])
	if game.u_i.lv == 69 and Settings.op_cursor:
		$Nice.visible = true

func _on_level_mouse_exited():
	$Nice.visible = false
	game.hide_tooltip()


func _on_name_focus_entered():
	game.view.move_with_keyboard = false


func _on_name_focus_exited():
	game.view.move_with_keyboard = true
