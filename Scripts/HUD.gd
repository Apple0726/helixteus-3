extends Control

onready var game = get_node("/root/Game")
onready var click_sound = game.get_node("click")
onready var money_text = $Top/Resources/Money/Text
onready var minerals_text = $Top/Resources/Minerals/Text
onready var stone_text = $Top/Resources/Stone/Text
onready var soil_text = $Top/Resources/Soil/Text
onready var energy_text = $Top/Resources/Energy/Text
onready var glass_text = $Top/Resources/Glass/Text
onready var cellulose_text = $Top/Resources/Cellulose/Text
onready var SP_text = $Top/Resources/SP/Text
onready var minerals = $Top/Resources/Minerals
onready var stone = $Top/Resources/Stone
onready var SP = $Top/Resources/SP
onready var ships = $Buttons/Ships
onready var shop = $Buttons/Shop
onready var craft = $Buttons/Craft
onready var MU = $Buttons/MineralUpgrades
onready var sc_tree = $Buttons/ScienceTree
onready var lv_txt = $Top/Lv/Label
onready var lv_progress = $Top/Lv/TextureProgress
onready var planet_grid = $Bookmarks/BookmarksList/Planets
onready var planet_grid_btns = $Bookmarks/BookmarksList/Planets/GridContainer
onready var system_grid = $Bookmarks/BookmarksList/Systems
onready var system_grid_btns = $Bookmarks/BookmarksList/Systems/GridContainer
onready var galaxy_grid = $Bookmarks/BookmarksList/Galaxies
onready var galaxy_grid_btns = $Bookmarks/BookmarksList/Galaxies/GridContainer
onready var cluster_grid = $Bookmarks/BookmarksList/Clusters
onready var cluster_grid_btns = $Bookmarks/BookmarksList/Clusters/GridContainer
onready var planet_b_btn = $Bookmarks/BookMarkButtons/Planets
onready var system_b_btn = $Bookmarks/BookMarkButtons/Systems
onready var galaxy_b_btn = $Bookmarks/BookMarkButtons/Galaxies
onready var cluster_b_btn = $Bookmarks/BookMarkButtons/Clusters
onready var dimension_btn = $Bottom/DimensionBtn
onready var switch_btn = $Bottom/SwitchBtn
onready var prev_btn = $Bottom/PrevView
onready var next_btn = $Bottom/NextView
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var on_button = false
var config = ConfigFile.new()
var tween:Tween
var ship2map
var emma_cave_shortcut:bool = false
var renaming:bool = false

func _on_Button_pressed():
	click_sound.play()
	game.toggle_panel(game.settings)

func _ready():
	tween = Tween.new()
	add_child(tween)
	if OS.get_latin_keyboard_variant() == "QWERTZ":
		switch_btn.shortcut.shortcut.action = "Y"
	elif OS.get_latin_keyboard_variant() == "AZERTY":
		switch_btn.shortcut.shortcut.action = "W"
	else:
		switch_btn.shortcut.shortcut.action = "Z"
	refresh_bookmarks()
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
#	if not game.viewing_dimension:
#		refresh()

func refresh_bookmarks():
	for slot in planet_grid_btns.get_children():
		planet_grid_btns.remove_child(slot)
		slot.queue_free()
	for slot in system_grid_btns.get_children():
		system_grid_btns.remove_child(slot)
		slot.queue_free()
	for slot in galaxy_grid_btns.get_children():
		galaxy_grid_btns.remove_child(slot)
		slot.queue_free()
	for slot in cluster_grid_btns.get_children():
		cluster_grid_btns.remove_child(slot)
		slot.queue_free()
	if not game.bookmarks.empty():
		for p_b in game.bookmarks.planet.values():
			add_p_b(p_b)
		for s_b in game.bookmarks.system.values():
			add_s_b(s_b)
		for g_b in game.bookmarks.galaxy.values():
			add_g_b(g_b)
		for c_b in game.bookmarks.cluster.values():
			add_c_b(c_b)

func add_p_b(p_b:Dictionary):
	var slot = preload("res://Scenes/BookmarkSlot.tscn").instance()
	slot.get_node("TextureButton").texture_normal = game.planet_textures[p_b.type - 3]
	slot.name = str(p_b.c_p_g)
	setup_b(slot, p_b, "planet")
	planet_grid_btns.add_child(slot)

func add_s_b(s_b:Dictionary):
	var slot = preload("res://Scenes/BookmarkSlot.tscn").instance()
	slot.get_node("TextureButton").texture_normal = preload("res://Graphics/Stars/Star.png")
	slot.name = str(s_b.c_s_g)
	slot.get_node("TextureButton").modulate = s_b.modulate
	setup_b(slot, s_b, "system")
	system_grid_btns.add_child(slot)

func add_g_b(g_b:Dictionary):
	var slot = preload("res://Scenes/BookmarkSlot.tscn").instance()
	slot.get_node("TextureButton").texture_normal = game.galaxy_textures[g_b.type]
	slot.name = str(g_b.c_g_g)
	setup_b(slot, g_b, "galaxy")
	galaxy_grid_btns.add_child(slot)

func add_c_b(c_b:Dictionary):
	var slot = preload("res://Scenes/BookmarkSlot.tscn").instance()
	slot.get_node("TextureButton").texture_normal = preload("res://Graphics/Clusters/0.png")
	slot.name = str(c_b.c_c)
	setup_b(slot, c_b, "cluster")
	cluster_grid_btns.add_child(slot)

func setup_b(slot, bookmark:Dictionary, view:String):
	slot.get_node("TextureButton").connect("mouse_entered", self, "on_bookmark_entered", [view, slot.name])
	slot.get_node("TextureButton").connect("mouse_exited", self, "on_bookmark_exited")
	slot.get_node("TextureButton").connect("pressed", self, "on_bookmark_pressed", [view, bookmark])
	
func on_bookmark_entered(type:String, id:String):
	game.show_tooltip(game.bookmarks[type][id].name)

func on_bookmark_exited():
	game.hide_tooltip()

func on_bookmark_pressed(view:String, bookmark:Dictionary):
	game.switch_view(view, {"fn":"set_bookmark_coords", "fn_args":[bookmark]})

func _process(delta):
	$Top/AutosaveLight.modulate.g = lerp(0.3, 1, game.get_node("Autosave").time_left / game.autosave_interval)

func update_XP():
	while game.u_i.xp >= game.u_i.xp_to_lv:
		game.u_i.lv += 1
		game.u_i.xp -= game.u_i.xp_to_lv
		game.u_i.xp_to_lv = round(game.u_i.xp_to_lv * game.maths_bonus.ULUGF)
		if not game.objective.empty() and game.objective.type == game.ObjectiveType.LEVEL:
			game.objective.current += 1
		if game.u_i.lv == 30:
			game.long_popup(tr("LEVEL_30_REACHED"), "%s 30" % tr("LEVEL"))
		if game.u_i.lv == 32:
			game.long_popup(tr("LEVEL_32_REACHED"), "%s 32" % tr("LEVEL"))
		if game.u_i.lv == 50:
			game.long_popup(tr("LEVEL_50_REACHED"), "%s 50" % tr("LEVEL"))
			game.new_bldgs.PCC = true
		if game.u_i.lv == 60:
			game.long_popup(tr("LEVEL_60_REACHED"), "%s 60" % tr("LEVEL"))
	lv_txt.text = tr("LV") + " %s" % [game.u_i.lv]
	lv_progress.value = game.u_i.xp / float(game.u_i.xp_to_lv)

func update_minerals():
#	if game.c_v == "planet" and is_instance_valid(game.view.obj) and game.view.obj.bldg_to_construct != "":
#		return
	var min_cap = round(200 + (game.mineral_capacity - 200) * Helper.get_IR_mult("MS"))
	minerals_text.text = "%s / %s" % [Helper.format_num(round(game.minerals)), Helper.format_num(min_cap)]
	if round(game.minerals) == min_cap:
		if not $Top/Resources/Minerals/Text.is_connected("mouse_entered", self, "_on_MineralsText_mouse_entered"):
			$Top/Resources/Minerals/Text.connect("mouse_entered", self, "_on_MineralsText_mouse_entered")
	else:
		if $Top/Resources/Minerals/Text.is_connected("mouse_entered", self, "_on_MineralsText_mouse_entered"):
			 $Top/Resources/Minerals/Text.disconnect("mouse_entered", self, "_on_MineralsText_mouse_entered")

func update_money_energy_SP():
	var planet = game.view.obj
	if game.c_v == "planet" and is_instance_valid(planet) and planet.bldg_to_construct != "":
		var money_cost = game.view.obj.constr_costs_total.money
		var energy_cost = game.view.obj.constr_costs_total.energy if game.view.obj.constr_costs_total.has("energy") else 0.0
		var glass_cost = game.view.obj.constr_costs_total.glass if game.view.obj.constr_costs_total.has("glass") else 0.0
		var soil_cost = game.view.obj.constr_costs_total.soil if game.view.obj.constr_costs_total.has("soil") else 0.0
		money_text.text = "%s / %s" % [Helper.format_num(round(game.money)), Helper.format_num(round(money_cost))]
		energy_text.text = "%s / %s" % [Helper.format_num(round(game.energy)), Helper.format_num(round(energy_cost))]
		glass_text.text = "%s / %s kg" % [Helper.format_num(round(game.mats.glass)), Helper.format_num(round(glass_cost))]
		soil_text.text = "%s / %s kg" % [Helper.format_num(round(game.mats.soil)), Helper.format_num(round(soil_cost))]
		money_text["custom_colors/font_color"] = Color.green if game.money >= money_cost else Color.red
		energy_text["custom_colors/font_color"] = Color.green if game.energy >= energy_cost else Color.red
		glass_text["custom_colors/font_color"] = Color.green if game.mats.glass >= glass_cost else Color.red
		soil_text["custom_colors/font_color"] = Color.green if game.mats.soil >= soil_cost else Color.red
	else:
		money_text["custom_colors/font_color"] = Color.white
		energy_text["custom_colors/font_color"] = Color.white
		money_text.text = Helper.format_num(round(game.money))
		energy_text.text = "%s / %s" % [Helper.format_num(round(game.energy)), Helper.format_num(2500 + round((game.energy_capacity - 2500) * Helper.get_IR_mult("B")))]
		soil_text.text = "%s kg" % Helper.format_num(game.mats.soil, true)
		soil_text["custom_colors/font_color"] = Color.white if game.mats.soil > 0 else Color.red
	SP_text.text = Helper.format_num(round(game.SP))
	if $Top/Resources/Cellulose.visible:
		cellulose_text.text = "%s kg" % Helper.format_num(game.mats.cellulose, true)
		cellulose_text["custom_colors/font_color"] = Color.white if game.mats.cellulose > 0 else Color.red
	
func refresh():
	if not game:
		return
	prev_btn.visible = game.view_history_pos > 0 and game.c_v in ["universe", "supercluster", "cluster", "galaxy", "system", "planet"]
	next_btn.visible = game.view_history_pos != len(game.view_history) - 1 and game.c_v in ["universe", "supercluster", "cluster", "galaxy", "system", "planet"]
	dimension_btn.visible = (len(game.universe_data) > 1 or game.dim_num > 1) and game.c_v in ["supercluster", "cluster", "galaxy", "system", "planet"]
	switch_btn.visible = game.c_v in ["planet", "system", "galaxy", "cluster", "supercluster", "universe"]
	if config.load("user://settings.cfg") == OK:
		var autosave_light = config.get_value("saving", "autosave_light", false)
		if config.get_value("saving", "enable_autosave", true) and (not game.tutorial or game.tutorial.tut_num >= 26):
			set_process(autosave_light)
		else:
			$Top/AutosaveLight.modulate.g = 0.3
			set_process(false)
		$Top/AutosaveLight.visible = autosave_light
	$Emma.visible = game.fourth_ship_hints.emma_joined and len(game.ship_data) != 4
	update_money_energy_SP()
	update_minerals()
	var total_stone:float = round(Helper.get_sum_of_dict(game.stone))
	stone_text.text = Helper.format_num(total_stone) + " kg"
	if $Top/Resources/Glass.visible:
		var GH_glass_cost = Data.costs.GH.glass * game.engineering_bonus.BCM
		if game.mats.glass >= GH_glass_cost:
			glass_text["custom_colors/font_color"] = Color.green
		else:
			glass_text["custom_colors/font_color"] = Color.red
		glass_text.text = "%s / %s kg" % [Helper.format_num(game.mats.glass, true), GH_glass_cost]
	if $Top/Resources/Soil.visible:
		var GH_soil_cost = Data.costs.GH.soil * game.engineering_bonus.BCM
		if game.mats.soil >= GH_soil_cost:
			soil_text["custom_colors/font_color"] = Color.green
		else:
			soil_text["custom_colors/font_color"] = Color.red
		soil_text.text = "%s / %s kg" % [Helper.format_num(game.mats.soil, true), GH_soil_cost]
	update_XP()
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
				if game.tutorial:
					if game.tutorial.tut_num in [6, 9, 10, 15, 24]:
						game.tutorial.begin()
					elif game.tutorial.tut_num == 11:
						if game.money < 300:
							game.objective = {"type":game.ObjectiveType.SAVE, "data":"money", "id":-1, "current":game.money, "goal":300}
						else:
							game.tutorial.begin()
			$Top/Objectives/TextureProgress.value = 0
	tween.stop_all()
	$Top/Objectives.visible = not game.objective.empty()
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
		$Top/Objectives/TextureProgress.rect_size = $Top/Objectives/Label.rect_size
		$Top/Objectives/TextureProgress.rect_position = $Top/Objectives/Label.rect_position
		tween.interpolate_property($Top/Objectives, "rect_position", null, Vector2($Top/Objectives.rect_position.x, 36), 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.interpolate_property($Top/Objectives/TextureProgress, "value", null, game.objective.current / float(game.objective.goal) * 100, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
		tween.start()
	else:
		$Top/Objectives.rect_position.y = 4
	$Bookmarks.visible = game.show.has("bookmarks")
	system_b_btn.visible = game.show.has("s_bk_button")
	galaxy_b_btn.visible = game.show.has("g_bk_button")
	cluster_b_btn.visible = game.universe_data[0].has("discovered")
	if game.c_v == "planet":
		$Bookmarks/Bookmarked.pressed = game.planet_data[game.c_p].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.planet_data[game.c_p].name
	elif game.c_v == "system":
		$Bookmarks/Bookmarked.pressed = game.system_data[game.c_s].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.system_data[game.c_s].name
	elif game.c_v == "galaxy":
		$Bookmarks/Bookmarked.pressed = game.galaxy_data[game.c_g].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.galaxy_data[game.c_g].name
	elif game.c_v == "cluster":
		$Bookmarks/Bookmarked.pressed = game.u_i.cluster_data[game.c_c].has("bookmarked")
		$Bookmarks/Bookmarked.visible = true
		$Top/Name/Name.text = game.u_i.cluster_data[game.c_c].name
	else:
		$Bookmarks/Bookmarked.visible = false
		if game.c_v == "supercluster":
			$Top/Name/Name.text = game.supercluster_data[game.c_sc].name
		elif game.c_v == "universe":
			$Top/Name/Name.text = game.u_i.name
	$Top/Name.visible = false
	$Top/Name.visible = true
	yield(get_tree(), "idle_frame")
	game.refresh_achievements()

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
	game.show_tooltip(tr("SHOP") + " (R)")

func _on_Inventory_mouse_entered():
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
	var tooltip:String = tr(extra_arg_0)
	if extra_arg_0 == "CELLULOSE":
		tooltip += "\n" + tr("YOU_USE") % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mats.cellulose), true), tr("S_SECOND")])
	elif game.autocollect.has("rsrc"):
		var min_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.MEE) * game.u_i.time_speed
		var energy_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.EPE) * game.u_i.time_speed
		var SP_mult:float = pow(game.maths_bonus.IRM, game.infinite_research.RLE) * game.u_i.time_speed
		if extra_arg_0 == "MINERALS":
			tooltip += "\n" + tr("YOU_AUTOCOLLECT") % ("%s/%s" % [Helper.format_num((game.autocollect.rsrc.minerals + game.autocollect.GS.minerals) * min_mult + game.autocollect.MS.minerals, true), tr("S_SECOND")])
		elif extra_arg_0 == "ENERGY":
			tooltip += "\n" + tr("YOU_AUTOCOLLECT") % ("%s/%s" % [Helper.format_num((game.autocollect.rsrc.energy + game.autocollect.GS.energy) * energy_mult + game.autocollect.MS.energy, true), tr("S_SECOND")])
		elif extra_arg_0 == "SP":
			tooltip += "\n" + tr("YOU_AUTOCOLLECT") % ("%s/%s" % [Helper.format_num((game.autocollect.rsrc.SP + game.autocollect.GS.SP) * SP_mult + game.autocollect.MS.SP, true), tr("S_SECOND")])
	if extra_arg_0 == "MINERALS":
		tooltip += "\n" + tr("MINERAL_DESC")
	game.show_tooltip(tooltip)

func _on_mouse_exited():
	game.hide_tooltip()

func update_hotbar():
	for child in $Bottom/Hotbar.get_children():
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

func _on_Label_mouse_entered():
	game.show_tooltip((tr("LEVEL") + " %s\nXP: %s / %s\n%s") % [game.u_i.lv, Helper.format_num(game.u_i.xp, 4), Helper.format_num(game.u_i.xp_to_lv, 4), tr("XP_HELP")])

func _on_Label_mouse_exited():
	emma_cave_shortcut = false
	game.hide_tooltip()

var bookmark_shown:bool = false
func _input(event):
	if Input.is_action_just_released("H") and slot_over != -1:
		game.hotbar.remove(slot_over)
		game.hide_tooltip()
		slot_over = -1
		update_hotbar()
		refresh()
	if Input.is_action_just_released("F2") and game.c_v in ["planet", "system", "galaxy", "cluster"]:
		$Top/Name/Name.grab_focus()
		$Top/Name/Name.select_all()
	if Input.is_action_just_released("left_click"):
		if emma_cave_shortcut and game.c_v == "planet":
			for i in len(game.tile_data):
				if game.tile_data[i] and game.tile_data[i].has("cave") and game.tile_data[i].cave == game.fourth_ship_hints.op_grill_cave_spawn:
					game.toggle_panel(game.vehicle_panel)
					game.vehicle_panel.tile_id = i
					break
		elif renaming:
			if game.c_v == "planet":
				pass
	if event is InputEventMouseMotion:
		if bookmark_shown and not Geometry.is_point_in_polygon(event.position, $MouseOut.polygon):
			bookmark_shown = false
			$AnimationPlayer.play_backwards("BookmarkAnim")
		if not bookmark_shown and Geometry.is_point_in_polygon(event.position, $MouseIn.polygon):
			bookmark_shown = true
			$AnimationPlayer.play("BookmarkAnim")

func _on_ConvertMinerals_mouse_entered():
	game.show_tooltip(tr("SELL_MINERALS") + " (,)")

func _on_ConvertMinerals_pressed():
	game.sell_all_minerals()
	if game.tutorial and game.tutorial.tut_num == 8 and not game.tutorial.tween.is_active():
		game.tutorial.fade()

func _on_Ships_pressed():
	game.toggle_panel(game.ship_panel)

func _on_Ships_mouse_entered():
	game.show_tooltip("%s (%s)" % [tr("SHIPS"), $Buttons/Ships.shortcut.shortcut.action])


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
		ship2map = load("res://Scenes/Ship2Map.tscn").instance()
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

func _on_Emma_mouse_entered():
	game.show_tooltip(tr("TALK_TO_OP_GRILL"))

func _on_Emma_pressed():
	game.objective.clear()
	$Dialogue.visible = true
	$Dialogue.NPC_id = 3
	if game.c_c == 3:
		if game.c_v == "cluster" or game.c_v == "galaxy" and game.c_g != game.fourth_ship_hints.dark_matter_spawn_galaxy:
			$Dialogue.dialogue_id = 8
		if game.c_g == game.fourth_ship_hints.dark_matter_spawn_galaxy:
			if game.c_v in ["galaxy", "system"]:
				$Dialogue.dialogue_id = 9
			elif game.c_v == "planet" and game.c_s_g == game.fourth_ship_hints.dark_matter_spawn_system:
				$Dialogue.dialogue_id = 10
	else:
		$Dialogue.dialogue_id = 7
	$Dialogue.show_dialogue()


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
	planet_grid.visible = true
	system_grid.visible = false
	galaxy_grid.visible = false
	cluster_grid.visible = false

func _on_Systems_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 1.0
	galaxy_b_btn.get_node("TextureRect").modulate.a = 0.5
	cluster_b_btn.get_node("TextureRect").modulate.a = 0.5
	planet_grid.visible = false
	system_grid.visible = true
	galaxy_grid.visible = false
	cluster_grid.visible = false

func _on_Galaxies_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 0.5
	galaxy_b_btn.get_node("TextureRect").modulate.a = 1.0
	cluster_b_btn.get_node("TextureRect").modulate.a = 0.5
	planet_grid.visible = false
	system_grid.visible = false
	galaxy_grid.visible = true
	cluster_grid.visible = false

func _on_Clusters_pressed():
	planet_b_btn.get_node("TextureRect").modulate.a = 0.5
	system_b_btn.get_node("TextureRect").modulate.a = 0.5
	galaxy_b_btn.get_node("TextureRect").modulate.a = 0.5
	cluster_b_btn.get_node("TextureRect").modulate.a = 1.0
	planet_grid.visible = false
	system_grid.visible = false
	galaxy_grid.visible = false
	cluster_grid.visible = true

func _on_Bookmarked_pressed():
	if game.c_v == "planet":
		var p_i:Dictionary = game.planet_data[game.c_p]
		if p_i.has("bookmarked"):
			game.bookmarks.planet.erase(str(game.c_p_g))
			planet_grid_btns.remove_child(planet_grid_btns.get_node(str(game.c_p_g)))
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
			add_p_b(bookmark)
	elif game.c_v == "system":
		var s_i:Dictionary = game.system_data[game.c_s]
		if s_i.has("bookmarked"):
			game.bookmarks.system.erase(str(game.c_s_g))
			system_grid_btns.remove_child(system_grid_btns.get_node(str(game.c_s_g)))
			s_i.erase("bookmarked")
		else:
			var star:Dictionary = s_i.stars[0]
			for i in range(1, len(s_i.stars)):
				if s_i.stars[i].luminosity > star.luminosity:
					star = s_i.stars[i]
			var bookmark:Dictionary = {
				"modulate":Helper.get_star_modulate(star.class),
				"name":s_i.name,
				"c_s":game.c_s,
				"c_s_g":game.c_s_g,
				"c_g":game.c_g,
				"c_g_g":game.c_g_g,
				"c_c":game.c_c}
			s_i.bookmarked = true
			game.bookmarks.system[str(game.c_s_g)] = bookmark
			add_s_b(bookmark)
	elif game.c_v == "galaxy":
		var g_i:Dictionary = game.galaxy_data[game.c_g]
		if g_i.has("bookmarked"):
			game.bookmarks.galaxy.erase(str(game.c_g_g))
			galaxy_grid_btns.remove_child(galaxy_grid_btns.get_node(str(game.c_g_g)))
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
			add_g_b(bookmark)
	elif game.c_v == "cluster":
		var c_i:Dictionary = game.u_i.cluster_data[game.c_c]
		if c_i.has("bookmarked"):
			game.bookmarks.cluster.erase(str(game.c_c))
			cluster_grid_btns.remove_child(cluster_grid_btns.get_node(str(game.c_c)))
			c_i.erase("bookmarked")
		else:
			var bookmark:Dictionary = {
				"name":c_i.name,
				"c_c":game.c_c}
			c_i.bookmarked = true
			game.bookmarks.cluster[str(game.c_c)] = bookmark
			add_c_b(bookmark)

func _on_Bookmarked_mouse_entered():
	if $Bookmarks/Bookmarked.pressed:
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


func _on_Name_mouse_entered():
	renaming = true

func _on_Name_mouse_exited():
	renaming = false


func _on_Name_text_entered(new_text):
	$Top/Name/Name.release_focus()
	if game.c_v == "planet":
		game.planet_data[game.c_p].name = new_text
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


func _on_Dimension_pressed():
	game.switch_view("dimension")


func _on_Dimension_mouse_entered():
	game.show_tooltip(tr("VIEW_DIMENSION"))


func _on_SwitchBtn_mouse_entered():
	var u_i:Dictionary = game.u_i
	var view_str:String = ""
	if game.c_v == "universe":
		view_str = tr("VIEW_DIMENSION")
		if not game.show.has("dimensions"):
			view_str += "\n%s" %tr("CONSTR_TP_TO_UNLOCK")
	elif game.c_v == "supercluster":
		view_str = tr("VIEW_UNIVERSE")
		if u_i.lv < 70:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 70"]]
	elif game.c_v == "cluster":
		view_str = tr("VIEW_SUPERCLUSTER")
		if u_i.lv < 50:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 50"]]
	elif game.c_v == "galaxy":
		view_str = tr("VIEW_CLUSTER")
		if u_i.lv < 35:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 35"]]
	elif game.c_v == "system":
		view_str = tr("VIEW_GALAXY")
		if u_i.lv < 18:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 18"]]
	elif game.c_v == "planet":
		view_str = tr("VIEW_STAR_SYSTEM")
		if u_i.lv < 8:
			view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 8"]]
	game.show_tooltip("%s (%s)" % [view_str, switch_btn.shortcut.shortcut.action])

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
			if u_i.lv >= 35:
				game.switch_view("cluster")
		"cluster":
			if u_i.lv >= 50:
				game.switch_view("supercluster")
		"supercluster":
			if u_i.lv >= 70:
				game.switch_view("universe")
		"universe":
			if game.show.has("dimensions"):
				game.switch_view("dimension")


func _on_Name_gui_input(event):
	get_tree().set_input_as_handled()


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
