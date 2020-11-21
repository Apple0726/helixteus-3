extends Node2D

onready var star_scene = preload("res://Scenes/Decoratives/Star.tscn")
onready var view_scene = preload("res://Scenes/Views/View.tscn")
onready var upgrade_panel_scene = preload("res://Scenes/Panels/UpgradePanel.tscn")
onready var send_ships_panel_scene = preload("res://Scenes/Panels/SendShipsPanel.tscn")
onready var settings_scene = preload("res://Scenes/Panels/Settings.tscn")
onready var planet_HUD_scene = preload("res://Scenes/Planet/PlanetHUD.tscn")
onready var space_HUD_scene = preload("res://Scenes/SpaceHUD.tscn")
onready var planet_details_scene = preload("res://Scenes/Planet/PlanetDetails.tscn")
onready var mining_HUD_scene = preload("res://Scenes/Views/Mining.tscn")
onready var science_tree_scene = preload("res://Scenes/Views/ScienceTree.tscn")
onready var overlay_scene = preload("res://Scenes/Overlay.tscn")
onready var rsrc_scene = preload("res://Scenes/Resource.tscn")
onready var rsrc_stocked_scene = preload("res://Scenes/ResourceStocked.tscn")
onready var cave_scene = preload("res://Scenes/Views/Cave.tscn")
onready var particles_scene = load("res://Scenes/LiquidParticles.tscn")
onready var time_scene = load("res://Scenes/TimeLeft.tscn")
onready var planet_TS = load("res://Resources/PlanetTileSet.tres")
onready var lake_TS = load("res://Resources/LakeTileSet.tres")
onready var obstacles_TS = load("res://Resources/ObstaclesTileSet.tres")
onready var aurora1_texture = load("res://Graphics/Tiles/Aurora1.png")
onready var aurora2_texture = load("res://Graphics/Tiles/Aurora2.png")
onready var slot_scene = preload("res://Scenes/InventorySlot.tscn")

var construct_panel:Control
var shop_panel:Control
var upgrade_panel:Control
var craft_panel:Control
var vehicle_panel:Control
var RC_panel:Control
var MU_panel:Control
var SC_panel:Control
var GF_panel:Control
var send_ships_panel:Control
var inventory:Control
var settings:Control
var dimension:Control
var planet_details:Control
var overlay:Control
onready var tooltip:Control = $Tooltips/Tooltip
onready var adv_tooltip:Control = $Tooltips/AdvTooltip

const SYSTEM_SCALE_DIV = 100.0
const GALAXY_SCALE_DIV = 750.0
const CLUSTER_SCALE_DIV = 1600.0
const SC_SCALE_DIV = 400.0

#HUD shows the player resources at the top
var HUD
#planet_HUD shows the buttons and other things that only shows while viewing a planet surface (e.g. construct)
var planet_HUD
#space_HUD shows things while viewing a system/galaxy/etc.
var space_HUD

#Stores individual tile nodes
var tiles = []
var bldg_blueprints = []#ids of tiles where things will be constructed
var panels = []#Mainly for removing panels in a specific order

#The base node containing things that can be moved/zoomed in/out
var view


############ Save data ############

#Current view
var c_v:String = ""
var l_v:String = ""

#Player resources
var money:float = 80000000
var minerals:float = 0
var mineral_capacity:float = 50
var stone:Dictionary = {}
var energy:float = 200000000
var SP:float = 4000
#Dimension remnants
var DRs:float = 0
var lv:int = 5
var xp:float = 0
var xp_to_lv:float = 10

#id of the universe/supercluster/etc. you're viewing the object in
var c_u:int = 0#c_u: current_universe
var c_sc:int = 0#c_sc: current_supercluster
var c_c:int = 0#etc.
var c_g:int = 0
var c_s:int = 0
var c_p:int = 2
var c_t:int = -1

#Number of items per stack
var stack_size:int = 16

var auto_replace:bool = false

#Stores information of the current pickaxe the player is holding
var pickaxe:Dictionary = {"name":"stick", "speed":10.0, "durability":700}

var mats:Dictionary = {	"coal":0,
						"glass":0,
						"sand":0,
						"clay":0,
						"soil":50,
						"cellulose":0,
						"silicon":2000,
}

var mets:Dictionary = {	"lead":140,
						"copper":0,
						"iron":140,
						"aluminium":0,
						"silver":0,
						"gold":0,
						"amethyst":0,
						"emerald":0,
						"quartz":0,
						"topaz":0,
						"ruby":0,
						"sapphire":0}

#Display help when players see/do things for the first time. true: show help
var help:Dictionary = {"mining":true,
			"plant_something_here":true,
			"boulder_desc":true,
			"aurora_desc":true,
			"cave_desc":true,
			"crater_desc":true,
			"tile_shortcuts":true,
			"inventory_shortcuts":true,
			"hotbar_shortcuts":true,
			"rover_shortcuts":true,
			"rover_inventory_shortcuts":true,
			"abandoned_ship":true,
}

var science_unlocked:Dictionary = {"SA":false, "RC":false, "SCT":false, "OL":false, "YL":false, "GL":false}
var MUs:Dictionary = {	"MV":1,
						"MSMB":1}#Levels of mineral upgrades

#Measures to not overwhelm beginners. false: not visible
var show:Dictionary = {	"minerals":false,
						"stone":false,
						"SP":true,
						"sand":false,
						"mining_layer":false,
						"plant_button":false,
						"vehicles_button":false,
						"materials":false,
						"metals":false,
						"glass":false,
						"clay":false,
						"aluminium":false,
						"silver":false,
						"gold":false,
						"amethyst":false,
						"emerald":false,
						"quartz":false,
						"topaz":false,
						"ruby":false,
						"sapphire":false}

#Stores information of all objects discovered
var universe_data:Array = [{"id":0, "type":0, "name":"Universe", "diff":1, "discovered":false, "supercluster_num":8000, "superclusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
var supercluster_data:Array = [{"id":0, "type":0, "name":"Laniakea Supercluster", "pos":Vector2.ZERO, "diff":1, "dark_energy":1.0, "discovered":false, "parent":0, "cluster_num":600, "clusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
var cluster_data:Array = [{"id":0, "type":0, "class":"group", "name":"Local Group", "pos":Vector2.ZERO, "diff":1, "discovered":false, "parent":0, "galaxy_num":55, "galaxies":[], "view":{"pos":Vector2(640 * 3, 360 * 3), "zoom":0.333}}]
var galaxy_data:Array = [{"id":0, "type":0, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "B_strength":pow10(5, -10), "dark_matter":1.0, "discovered":false, "parent":0, "system_num":2000, "systems":[], "view":{"pos":Vector2(15000 + 1280, 15000 + 720), "zoom":0.5}}]
var system_data:Array = [{"id":0, "name":"Solar system", "pos":Vector2(-15000, -15000), "diff":1, "discovered":false, "parent":0, "planet_num":7, "planets":[], "view":{"pos":Vector2(640, -100), "zoom":1}, "stars":[{"type":"main_sequence", "class":"G2", "size":1, "temperature":5500, "mass":1, "luminosity":1, "pos":Vector2(0, 0)}]}]
var planet_data:Array = []
var tile_data:Array = []
var cave_data:Array = []

#Vehicle data
#var rover_data:Array = [{"c_p":2, "ready":true, "HP":20.0, "atk":5.0, "def":5.0, "weight_cap":8000.0, "inventory":[{"name":"attack", "cooldown":0.2, "damage":2.0}, {"name":"mining", "speed":1.0}, {"name":""}, {"name":""}, {"name":""}], "i_w_w":{}}]
var rover_data:Array = []
var ship_data:Array = []
var ships_c_p:int = 2#Planet that the ships are on
var ships_depart_pos:Vector2 = Vector2.ZERO#Depart position of system/galaxy/etc. depending on view
var ships_dest_pos:Vector2 = Vector2.ZERO#Destination position of system/galaxy/etc. depending on view
var ships_dest_p_id:int = -1#Planet destination id
var ships_travel_view:String = "-"#View in which ships travel
var ships_travel_start_date:int = -1#View in which ships travel
var ships_travel_length:int = -1#View in which ships travel
var satellite_data:Array = []

#Your inventory
var items:Array = [{"name":"speedup1", "num":1, "type":"speedup_info", "directory":"Items/Speedups"}, {"name":"overclock1", "num":1, "type":"overclock_info", "directory":"Items/Overclocks"}, null, null, null, null, null, null, null, null]
#var items:Array = [{"name":"lead_seeds", "num":4}, null, null, null, null, null, null, null, null, null]

var hotbar:Array = []

var overlay_data = {	"galaxy":{"overlay":0, "visible":false, "custom_values":[{"left":2, "right":30}, null, {"left":250, "right":100000}]},
						"cluster":{"overlay":0, "visible":false, "custom_values":[{"left":200, "right":10000}, null, {"left":0.2, "right":5}, {"left":0.8, "right":1.2}]},
}
############ End save data ############

var save_u = false
var save_sc = false
var save_c = false
var save_g = false
var save_s = false
var save_p = false
var save_t = false

var EA_planet_visited = false
var EA_galaxy_visited = false
var EA_cave_visited = false

#Stores data of the item that you clicked in your inventory
var item_to_use = {"name":"", "type":"", "num":0}

var mining_HUD
var science_tree
var science_tree_view = {"pos":Vector2.ZERO, "zoom":1.0}
var cave

var mat_info = {	"coal":{"value":5},#One kg of coal = $10
					"glass":{"value":20},
					"sand":{"value":4},
					"clay":{"value":12},
					"soil":{"value":6},
					"cellulose":{"value":12},
					"silicon":{"value":10},
}
var met_info = {	"lead":{"min_depth":0, "max_depth":500, "amount":20, "rarity":1, "density":11.34, "value":30},
					"copper":{"min_depth":100, "max_depth":750, "amount":20, "rarity":1.3, "density":8.96, "value":60},
					"iron":{"min_depth":200, "max_depth":1000, "amount":20, "rarity":1.7, "density":7.87, "value":95},
					"aluminium":{"min_depth":300, "max_depth":1500, "amount":20, "rarity":2.3, "density":2.7, "value":140},
					"silver":{"min_depth":500, "max_depth":1750, "amount":20, "rarity":2.9, "density":10.49, "value":200},
					"gold":{"min_depth":700, "max_depth":2500, "amount":16, "rarity":4.5, "density":19.3, "value":300},
					"amethyst":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":5.0, "density":2.66, "value":500},
					"emerald":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":5.2, "density":2.70, "value":540},
					"quartz":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":5.4, "density":2.32, "value":580},
					"topaz":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":5.6, "density":3.50, "value":620},
					"ruby":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":5.8, "density":4.01, "value":660},
					"sapphire":{"min_depth":1000, "max_depth":3000, "amount":16, "rarity":6.0, "density":3.99, "value":700},
}

var pickaxe_info = {"stick":{"speed":1.0, "durability":70, "costs":{"money":150}},
					"wooden_pickaxe":{"speed":1.4, "durability":150, "costs":{"money":1300}},
					"stone_pickaxe":{"speed":1.9, "durability":400, "costs":{"money":9000}},
					"lead_pickaxe":{"speed":2.5, "durability":700, "costs":{"money":85000}},
					"copper_pickaxe":{"speed":3.3, "durability":1100, "costs":{"money":600000}},
					"iron_pickaxe":{"speed":4.3, "durability":1600, "costs":{"money":4000000}},
					}

var speedup_info = {	"speedup1":{"costs":{"money":400}, "time":2*60000},
						"speedup2":{"costs":{"money":2800}, "time":15*60000},}

var overclock_info = {	"overclock1":{"costs":{"money":1400}, "mult":1.5, "duration":10*60000},
						"overclock2":{"costs":{"money":8500}, "mult":2, "duration":30*60000}}

var craft_agric_info = {"lead_seeds":{"costs":{"cellulose":20, "lead":20}, "grow_time":3600000, "lake":"water", "produce":60},
						"fertilizer":{"costs":{"cellulose":50, "soil":30}, "speed_up_time":3600000}}

var other_items_info = {"hx_core":{}}

var item_groups = [	{"dict":speedup_info, "path":"Items/Speedups"},
					{"dict":overclock_info, "path":"Items/Overclocks"},
					{"dict":craft_agric_info, "path":"Agriculture"},
					{"dict":other_items_info, "path":"Items/Others"},
					]
#Density is in g/cm^3
var element = {	"Si":{"density":2.329},
				"O":{"density":1.429}}

#Holds information of the tooltip that can be hidden by the player by pressing F7
var help_str:String

var music_player = AudioStreamPlayer.new()

func _ready():
	view = view_scene.instance()
	add_child(view)
	add_child(music_player)
	music_player.bus = "Music"
	#noob
	#AudioServer.set_bus_mute(1,true)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		if config.get_value("audio", "mute", false):
			AudioServer.set_bus_mute(1,true)
		else:
			switch_music(load("res://Audio/title1.ogg"))
		TranslationServer.set_locale(config.get_value("interface", "language", "en"))
		Data.reload()
	config.save("user://settings.cfg")
	var dir = Directory.new()
	dir.remove("user://Save1/main.hx3")
	
	settings = settings_scene.instance()
	settings.visible = false
	$Panels.add_child(settings)
	for i in 80:
		var star = star_scene.instance()
		$Title/Background.add_child(star)
	var tween:Tween = Tween.new()
	add_child(tween)
	tween.interpolate_property($Title/Background, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1)
	tween.interpolate_property($Title/Menu, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.5)
	tween.interpolate_property($Title/Menu, "rect_position", Vector2(44, 464), Vector2(84, 464), 1, Tween.TRANS_CIRC, Tween.EASE_OUT, 0.5)
	tween.interpolate_property($Title/Discord, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_LINEAR, Tween.EASE_IN, 1)
	tween.interpolate_property($Title/Discord, "rect_position", Vector2(0, 13), Vector2(0, -2), 1, Tween.TRANS_CIRC, Tween.EASE_OUT, 1)
	tween.interpolate_property($Title/GitHub, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_LINEAR, Tween.EASE_IN, 1.25)
	tween.interpolate_property($Title/GitHub, "rect_position", Vector2(0, 15), Vector2(0, 0), 1, Tween.TRANS_CIRC, Tween.EASE_OUT, 1.25)
	tween.interpolate_property($Title/Godot, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1, Tween.TRANS_LINEAR, Tween.EASE_IN, 1.5)
	tween.interpolate_property($Title/Godot, "rect_position", Vector2(0, 13), Vector2(0, -2), 1, Tween.TRANS_CIRC, Tween.EASE_OUT, 1.5)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)

func switch_music(src):
	#Music fading
	var tween = Tween.new()
	add_child(tween)
	if music_player.playing:
		tween.interpolate_property(music_player, "volume_db", null, -30, 1, Tween.TRANS_QUAD, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
	music_player.stream = src
	music_player.play()
	tween.interpolate_property(music_player, "volume_db", -20, 0, 2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()

func _load_game():
	$Title.visible = false
	$UI/Settings.visible = true
	#Loads planet scene
	switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	
	dimension = load("res://Scenes/Views/Dimension.tscn").instance()
	inventory = load("res://Scenes/Panels/Inventory.tscn").instance()
	shop_panel = load("res://Scenes/Panels/ShopPanel.tscn").instance()
	construct_panel = load("res://Scenes/Panels/ConstructPanel.tscn").instance()
	craft_panel = load("res://Scenes/Panels/CraftPanel.tscn").instance()
	vehicle_panel = load("res://Scenes/Panels/VehiclePanel.tscn").instance()
	RC_panel = load("res://Scenes/Panels/RCPanel.tscn").instance()
	MU_panel = load("res://Scenes/Panels/MUPanel.tscn").instance()
	SC_panel = load("res://Scenes/Panels/SCPanel.tscn").instance()
	GF_panel = load("res://Scenes/Panels/GFPanel.tscn").instance()
	send_ships_panel = load("res://Scenes/Panels/SendShipsPanel.tscn").instance()
	HUD = load("res://Scenes/HUD.tscn").instance()
	
	construct_panel.visible = false
	$Panels.add_child(construct_panel)

	shop_panel.visible = false
	$Panels.add_child(shop_panel)

	craft_panel.visible = false
	$Panels.add_child(craft_panel)

	vehicle_panel.visible = false
	$Panels.add_child(vehicle_panel)

	RC_panel.visible = false
	$Panels.add_child(RC_panel)

	MU_panel.visible = false
	$Panels.add_child(MU_panel)

	SC_panel.visible = false
	$Panels.add_child(SC_panel)

	GF_panel.visible = false
	$Panels.add_child(GF_panel)

	inventory.visible = false
	$Panels.add_child(inventory)

	dimension.visible = false
	add_child(dimension)
	var save_game = File.new()
	if save_game.file_exists("user://Save1/main.hx3"):
		save_game.open("user://Save1/main.hx3", File.READ)
		c_v = save_game.get_var()
		money = save_game.get_float()
		minerals = save_game.get_float()
		mineral_capacity = save_game.get_float()
		energy = save_game.get_float()
		SP = save_game.get_float()
		DRs = save_game.get_float()
		xp = save_game.get_float()
		xp_to_lv = save_game.get_float()
		c_u = save_game.get_64()
		c_sc = save_game.get_64()
		c_c = save_game.get_64()
		c_g = save_game.get_64()
		c_s = save_game.get_64()
		c_p = save_game.get_64()
		lv = save_game.get_64()
		stack_size = save_game.get_64()
		auto_replace = save_game.get_8()
		pickaxe = save_game.get_var()
		science_unlocked = save_game.get_var()
		mats = save_game.get_var()
		mets = save_game.get_var()
		help = save_game.get_var()
		show = save_game.get_var()
#		universe_data = save_game.get_var()
#		supercluster_data = save_game.get_var()
#		cluster_data = save_game.get_var()
#		galaxy_data = save_game.get_var()
#		system_data = save_game.get_var()
#		planet_data = save_game.get_var()
#		tile_data = save_game.get_var()
		items = save_game.get_var()
		hotbar = save_game.get_var()
		save_game.close()
		add_child(HUD)
		switch_view(c_v, true)
	else:
		var dir = Directory.new()
		dir.make_dir("user://Save1")
		dir.make_dir("user://Save1/Planets")
		generate_planets(0)
		#Home planet information
		planet_data[2]["name"] = tr("HOME_PLANET")
		planet_data[2]["status"] = "conquered"
		planet_data[2]["size"] = rand_range(12000, 12100)
		planet_data[2]["angle"] = PI / 2
		planet_data[2]["tiles"] = []
		planet_data[2]["discovered"] = false
		planet_data[2].pressure = 1
		planet_data[2].lake_1 = "water"
		planet_data[2].erase("lake_2")
		planet_data[2].liq_seed = 4
		planet_data[2].liq_period = 100
		planet_data[2].crust_start_depth = Helper.rand_int(35, 40)
		planet_data[2].mantle_start_depth = Helper.rand_int(25000, 30000)
		planet_data[2].core_start_depth = Helper.rand_int(4000000, 4200000)
		planet_data[2].surface.coal.chance = 0.5
		planet_data[2].surface.coal.amount = 100
		planet_data[2].surface.soil.chance = 0.6
		planet_data[2].surface.soil.amount = 60
		planet_data[2].surface.cellulose.chance = 0.4
		planet_data[2].surface.cellulose.amount = 10
		
		system_data[0].name = tr("SOLAR_SYSTEM")
		galaxy_data[0].name = tr("MILKY_WAY")
		cluster_data[0].name = tr("LOCAL_GROUP")
		supercluster_data[0].name = tr("LANIAKEA")
		
		generate_tiles(2)
		cave_data.append({"num_floors":5, "floor_size":40})
		cave_data.append({"num_floors":8, "floor_size":50})
		
		for u_i in universe_data:
			u_i["epsilon_zero"] = pow10(8.854, -12)#F/m
			u_i["mu_zero"] = pow10(1.257, -6)#H/m
			u_i["planck"] = pow10(6.626, -34)#J.s
			u_i["gravitational"] = pow10(6.674, -11)#m^3/kg/s^2
			u_i["charge"] = pow10(1.602, -19)#C
			u_i["strong_force"] = 1.0
			u_i["weak_force"] = 1.0
			u_i["dark_matter"] = 1.0
			u_i["difficulty"] = 1.0
			u_i["multistar_systems"] = 1.0
			u_i["rare_stars"] = 1.0
			u_i["rare_materials"] = 1.0
			u_i["time_speed"] = 1.0
			u_i["radiation"] = 1.0
			u_i["antimatter"] = 1.0
			u_i["value"] = 1.0
		c_v = "planet"
		add_planet()
		add_child(HUD)
	
	send_ships_panel.visible = false
	$Panels.add_child(send_ships_panel)

	#long_popup("This game is currently in very early access. There is no saving yet, so don't spend too much time playing!\nRead the game description to find (helpful) shortcuts not shown in the game.\nYou also start at level 5 to be able to explore the universe right away.", "Early access note")

func popup(txt, dur):
	var node = $UI/Popup
	node.text = txt
	node.visible = true
	node.modulate.a = 0
	yield(get_tree().create_timer(0), "timeout")
	node.rect_size.x = 0
	var x_pos = 640 - node.rect_size.x / 2
	node.rect_position.x = x_pos
	var tween:Tween = node.get_node("Tween")
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(node, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.15)
	tween.interpolate_property(node, "rect_position", Vector2(x_pos, 83), Vector2(x_pos, 80), 0.15)
	tween.interpolate_property(node, "rect_rotation", 0, 0, dur)
	tween.start()
	yield(tween, "tween_all_completed")
	if not tween.is_active():
		tween.interpolate_property(node, "modulate", null, Color(1, 1, 1, 0), 0.15)
		tween.interpolate_property(node, "rect_position", Vector2(x_pos, 80), Vector2(x_pos, 83), 0.15)
		tween.start()

var dialog:AcceptDialog

func long_popup(txt:String, title:String, other_buttons:Array = [], other_functions:Array = [], ok_txt:String = "OK"):
	hide_adv_tooltip()
	hide_tooltip()
	if dialog:
		$UI.remove_child(dialog)
	dialog = AcceptDialog.new()
	dialog.theme = load("res://Resources/default_theme.tres")
	dialog.popup_exclusive = true
	$UI/PopupBackground.visible = true
	$UI.add_child(dialog)
	dialog.window_title = title
	dialog.dialog_text = txt
	dialog.popup_centered()
	for i in range(0, len(other_buttons)):
# warning-ignore:return_value_discarded
		dialog.add_button(other_buttons[i], false, other_functions[i])
# warning-ignore:return_value_discarded
		dialog.connect("custom_action", self, "popup_action")
# warning-ignore:return_value_discarded
	dialog.connect("popup_hide", self, "popup_close")
	dialog.get_ok().text = ok_txt

func popup_close():
	$UI/PopupBackground.visible = false

func popup_action(action:String):
	call(action)
	dialog.visible = false

func open_shop_pickaxe():
	if not shop_panel.visible:
		panels.push_front(shop_panel)
		fade_in_panel(shop_panel)
	shop_panel._on_Pickaxes_pressed()

func put_bottom_info(txt:String):
	var more_info = $Control/BottomInfo
	more_info.visible = false
	more_info.text = txt
	more_info.modulate.a = 0
	more_info.visible = true
	more_info.rect_size.x = 0#This "trick" lets us resize the label to fit the text
	more_info.rect_position.x = -more_info.get_minimum_size().x / 2.0
	more_info.modulate.a = 1
	move_child($Control, get_child_count())

func fade_in_panel(panel:Control):
	panel.visible = true
	move_child($Panels, get_child_count())
	$Panels.move_child(panel, $Panels.get_child_count())
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 1), 0.1)
	var s = panel.rect_size
	panel.tween.interpolate_property(panel, "rect_position", Vector2(-s.x / 2.0, -s.y / 2.0 + 10), Vector2(-s.x / 2.0, -s.y / 2.0), 0.1)
	if panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.disconnect("tween_all_completed", self, "on_fade_complete")
	panel.tween.start()

func fade_out_panel(panel:Control):
	var s = panel.rect_size
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 0), 0.1)
	panel.tween.interpolate_property(panel, "rect_position", null, Vector2(-s.x / 2.0, -s.y / 2.0 + 10), 0.1)
	panel.tween.start()
	if not panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.connect("tween_all_completed", self, "on_fade_complete", [panel])

func on_fade_complete(panel:Control):
	hide_tooltip()
	panel.visible = false

func add_upgrade_panel(ids:Array):
	if upgrade_panel and is_a_parent_of(upgrade_panel):
		$Panels.remove_child(upgrade_panel)
	upgrade_panel = upgrade_panel_scene.instance()
	upgrade_panel.ids = ids
	panels.push_front(upgrade_panel)
	if upgrade_panel:
		$Panels.add_child(upgrade_panel)
		move_child($Panels, get_child_count())

func remove_upgrade_panel():
	if upgrade_panel:
		$Panels.remove_child(upgrade_panel)
	panels.erase(upgrade_panel)
	upgrade_panel = null

func toggle_panel(panel):
	if not panel.visible:
		panels.push_front(panel)
		fade_in_panel(panel)
		panel.refresh()
	else:
		fade_out_panel(panel)
		panels.erase(panel)

func switch_view(new_view:String, first_time:bool = false):
	hide_tooltip()
	hide_adv_tooltip()
	if not first_time:
		match c_v:
			"planet":
				remove_planet()
			"planet_details":
				remove_child(planet_details)
				planet_details = null
				add_child(HUD)
			"system":
				remove_system()
			"galaxy":
				remove_galaxy()
			"cluster":
				remove_cluster()
			"supercluster":
				remove_supercluster()
			"universe":
				remove_universe()
			"dimension":
				remove_dimension()
			"mining":
				remove_mining()
			"science_tree":
				remove_science_tree()
			"cave":
				add_child(HUD)
				remove_child(cave)
				cave = null
				switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
		if c_v == "science_tree":
			c_v = l_v
		else:
			l_v = c_v
			c_v = new_view
	match c_v:
		"planet":
			add_planet()
		"planet_details":
			planet_details = planet_details_scene.instance()
			add_child(planet_details)
			remove_child(HUD)
		"system":
			add_system()
		"galaxy":
			add_galaxy()
		"cluster":
			add_cluster()
		"supercluster":
			add_supercluster()
		"universe":
			add_universe()
		"dimension":
			add_dimension()
		"mining":
			add_mining()
		"science_tree":
			add_science_tree()
		"cave":
			remove_child(HUD)
			cave = cave_scene.instance()
			add_child(cave)
			switch_music(load("res://Audio/cave1.ogg"))
		"STM":
			pass

func add_science_tree():
	HUD.get_node("Hotbar").visible = false
	add_obj("science_tree")

func add_mining():
	HUD.get_node("CollectAll").visible = false
	HUD.get_node("Hotbar").visible = false
	mining_HUD = mining_HUD_scene.instance()
	add_child(mining_HUD)

func remove_mining():
	HUD.get_node("Hotbar").visible = true
	remove_child(mining_HUD)
	mining_HUD = null

func remove_science_tree():
	HUD.get_node("Hotbar").visible = true
	view.remove_obj("science_tree")

func add_loading():
	var loading_scene = preload("res://Scenes/Loading.tscn")
	var loading = loading_scene.instance()
	loading.position = Vector2(640, 360)
	add_child(loading)
	loading.name = "Loading"

func add_obj(view_str):
	match view_str:
		"planet":
			remove_space_HUD()
			view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
		"system":
			remove_space_HUD()
			view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])
		"galaxy":
			add_space_HUD()
			put_change_view_btn(tr("VIEW_CLUSTER") + " (Z)", "res://Graphics/Buttons/ClusterView.png")
			view.add_obj("Galaxy", galaxy_data[c_g]["view"]["pos"], galaxy_data[c_g]["view"]["zoom"])
		"cluster":
			add_space_HUD()
			put_change_view_btn(tr("VIEW_SUPERCLUSTER") + " (Z)", "res://Graphics/Buttons/SuperclusterView.png")
			view.add_obj("Cluster", cluster_data[c_c]["view"]["pos"], cluster_data[c_c]["view"]["zoom"])
		"supercluster":
			remove_space_HUD()
			view.add_obj("Supercluster", supercluster_data[c_sc]["view"]["pos"], supercluster_data[c_sc]["view"]["zoom"], supercluster_data[c_sc]["view"]["sc_mult"])
		"universe":
			remove_space_HUD()
			view.add_obj("Universe", universe_data[c_u]["view"]["pos"], universe_data[c_u]["view"]["zoom"], universe_data[c_u]["view"]["sc_mult"])
		"science_tree":
			remove_space_HUD()
			view.add_obj("ScienceTree", science_tree_view.pos, science_tree_view.zoom)
			var back_btn = Button.new()
			back_btn.name = "ScienceBackBtn"
			back_btn.text = "<- " + tr("BACK") + " (Z)"
			back_btn.theme = load("res://Resources/default_theme.tres")
			back_btn.margin_left = -640
			back_btn.margin_top = 320
			back_btn.margin_right = -512
			back_btn.margin_bottom = 360
			add_child(back_btn)
			back_btn.rect_position = Vector2(0, 680)
			back_btn.connect("pressed", self, "on_science_back_pressed")

func on_science_back_pressed():
	switch_view("planet")
	remove_child(get_node("ScienceBackBtn"))

func add_space_HUD():
	if not space_HUD or not is_a_parent_of(space_HUD):
		space_HUD = space_HUD_scene.instance()
		add_child(space_HUD)
		add_overlay()

func add_overlay():
	overlay = overlay_scene.instance()
	overlay.visible = false
	overlay.rect_position = Vector2(640, 720)
	add_child(overlay)

func remove_overlay():
	if overlay and is_a_parent_of(overlay):
		remove_child(overlay)
	overlay = null

func remove_space_HUD():
	if space_HUD and is_a_parent_of(space_HUD):
		remove_child(space_HUD)
	space_HUD = null
	remove_overlay()

func add_dimension():
	remove_child(HUD)
	dimension.visible = true

func add_universe():
	put_change_view_btn(tr("VIEW_DIMENSION") + " (Z)", "res://Graphics/Buttons/DimensionView.png")
	if not universe_data[c_u]["discovered"]:
		reset_collisions()
		generate_superclusters(c_u)
	add_obj("universe")

func add_supercluster():
	put_change_view_btn(tr("VIEW_UNIVERSE") + " (Z)", "res://Graphics/Buttons/UniverseView.png")
	if not supercluster_data[c_sc]["discovered"]:
		reset_collisions()
		generate_clusters(c_sc)
	add_obj("supercluster")

func add_cluster():
	if not cluster_data[c_c]["discovered"]:
		add_loading()
		reset_collisions()
		generate_galaxy_part()
	else:
		add_obj("cluster")

func add_galaxy():
	if not galaxy_data[c_g]["discovered"]:
		add_loading()
		reset_collisions()
		gc_remaining = floor(pow(galaxy_data[c_g]["system_num"], 0.8) / 250.0)
		generate_system_part()
	else:
		add_obj("galaxy")

func add_system():
	put_change_view_btn(tr("VIEW_GALAXY") + " (Z)", "res://Graphics/Buttons/GalaxyView.png")
	if not system_data[c_s]["discovered"]:
		generate_planets(c_s)
	add_obj("system")
	HUD.get_node("CollectAll").visible = false

func add_planet():
	if not planet_data[c_p]["discovered"]:
		generate_tiles(c_p)
		if not EA_planet_visited:
			long_popup("Normally you need to fight enemies with ships before being able to visit other planets. But for testing purposes,\nbattle will come much later in the game and you'll be able to visit every planet with a click.", "Early access note")
			EA_planet_visited = true
	add_obj("planet")
	planet_HUD = planet_HUD_scene.instance()
	add_child(planet_HUD)
	HUD.get_node("CollectAll").visible = true

func remove_dimension():
	add_child(HUD)
	dimension.visible = false
	view.dragged = true

func remove_universe():
	remove_child(change_view_btn)
	view.remove_obj("universe")

func remove_supercluster():
	remove_child(change_view_btn)
	view.remove_obj("supercluster")

func remove_cluster():
	remove_child(change_view_btn)
	view.remove_obj("cluster")

func remove_galaxy():
	remove_child(change_view_btn)
	view.remove_obj("galaxy")

func remove_system():
	remove_child(change_view_btn)
	view.remove_obj("system")

func remove_planet():
	Helper.save_tiles(c_p)
	$Control/BottomInfo.visible = false
	view.remove_obj("planet")
	remove_child(planet_HUD)
	planet_HUD = null

#Collision detection of systems, galaxies etc.
var obj_shapes = []
var max_outer_radius = 0
var min_dist_from_center = 0
var max_dist_from_center = 0

#For globular cluster generation
var gc_remaining = 0
var gc_stars_remaining = 0
var gc_center = Vector2.ZERO
#To not put gc near galactic core
var gc_offset = 0
var gc_circles = []

func reset_collisions():
	obj_shapes = []
	max_outer_radius = 0
	min_dist_from_center = 0
	max_dist_from_center = 0
	gc_remaining = 0
	gc_stars_remaining = 0
	gc_center = Vector2.ZERO
	gc_offset = 0
	gc_circles = []

func sort_shapes (a, b):
	if a["outer_radius"] < b["outer_radius"]:
		return true
	return false

func generate_superclusters(id:int):
	randomize()
	var total_sc_num = universe_data[id]["supercluster_num"]
	max_dist_from_center = pow(total_sc_num, 0.5) * 300
	for _i in range(1, total_sc_num):
		var sc_i = {}
		sc_i["status"] = "unconquered"
		sc_i["type"] = Helper.rand_int(0, 0)
		sc_i["parent"] = id
		sc_i["clusters"] = []
		sc_i["cluster_num"] = Helper.rand_int(100, 1000)
		sc_i["discovered"] = false
		var pos
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		sc_i["pos"] = pos
		sc_i.dark_energy = clever_round(max(pow(dist_from_center / 1000.0, 0.1), 1))
		var sc_id = supercluster_data.size()
		sc_i["id"] = sc_id
		sc_i["name"] = tr("SUPERCLUSTER") + " %s" % sc_id
		sc_i["discovered"] = false
		universe_data[id]["superclusters"].append(sc_id)
		supercluster_data.append(sc_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		universe_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	universe_data[id]["discovered"] = true

func generate_clusters(id:int):
	randomize()
	var total_clust_num = supercluster_data[id]["cluster_num"]
	max_dist_from_center = pow(total_clust_num, 0.5) * 500
	for _i in range(1, total_clust_num):
		var c_i = {}
		c_i["status"] = "unconquered"
		c_i["type"] = Helper.rand_int(0, 0)
		c_i["class"] = "group" if randf() < 0.5 else "cluster"
		c_i["parent"] = id
		c_i["galaxies"] = []
		c_i["discovered"] = false
		var c_id = cluster_data.size()
		if c_i["class"] == "group":
			c_i["galaxy_num"] = Helper.rand_int(10, 100)
			c_i.name = tr("GALAXY_GROUP") + " %s" % c_id
		else:
			c_i["galaxy_num"] = Helper.rand_int(500, 5000)
			c_i.name = tr("GALAXY_CLUSTER") + " %s" % c_id
		var pos
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		c_i["pos"] = pos
		c_i["id"] = c_id
		c_i["discovered"] = false
		supercluster_data[id]["clusters"].append(c_id)
		cluster_data.append(c_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		supercluster_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	supercluster_data[id]["discovered"] = true

func generate_galaxy_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_galaxies(c_c)
		$Loading.update_bar(progress, tr("GENERATING_CLUSTER") % [String(cluster_data[c_c]["galaxies"].size()), String(cluster_data[c_c]["galaxy_num"])])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	add_obj("cluster")
	remove_child($Loading)

func generate_galaxies(id:int):
	randomize()
	var total_gal_num = cluster_data[id]["galaxy_num"]
	var galaxy_num = total_gal_num - cluster_data[id]["galaxies"].size()
	var gal_num_to_load = min(500, galaxy_num)
	var progress = 1 - (galaxy_num - gal_num_to_load) / float(total_gal_num)
	var dark_energy = supercluster_data[cluster_data[id].parent].dark_energy
	for i in range(0, gal_num_to_load):
		var g_i = {}
		g_i["status"] = "unconquered"
		g_i["parent"] = id
		g_i["systems"] = []
		g_i["discovered"] = false
		g_i["system_num"] = int(pow(randf(), 2) * 8000) + 2000
		g_i["B_strength"] = clever_round(pow10(1, -9) * rand_range(0.2, 5), 3)#Influences star classes
		g_i.dark_matter = rand_range(0.9, 1.1) + dark_energy - 1 #Influences planet numbers and size
		var rand = randf()
		if rand < 0.02:
			g_i.dark_matter = pow(g_i.dark_matter, 2.5)
		elif rand < 0.2:
			g_i.dark_matter = pow(g_i.dark_matter, 1.8)
		g_i.dark_matter = clever_round(g_i.dark_matter, 3)
		g_i["type"] = Helper.rand_int(0, 5)
		g_i["rotation"] = rand_range(0, 2 * PI)
		if randf() < 0.6: #Dwarf galaxy
			g_i["system_num"] /= 10
		g_i["view"] = {"pos":Vector2(640, 360), "zoom":0.2}
		var pos
		var N = obj_shapes.size()
		if N >= total_gal_num / 6:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.7), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
		
		var radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.7)
		var circle
		var colliding = true
		if min_dist_from_center == 0:
			max_dist_from_center = 5000
		else:
			max_dist_from_center = min_dist_from_center * 1.5
		var outer_radius
		while colliding:
			colliding = false
			var dist_from_center = rand_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
			circle = {"pos":pos, "radius":radius, "outer_radius":outer_radius}
			for star_shape in obj_shapes:
				if pos.distance_to(star_shape["pos"]) < radius + star_shape["radius"]:
					colliding = true
					max_dist_from_center *= 1.2
					break
		if outer_radius > max_outer_radius:
			max_outer_radius = outer_radius
		obj_shapes.append(circle)
		g_i["pos"] = pos
		var g_id = galaxy_data.size()
		g_i["id"] = g_id
		g_i["name"] = tr("GALAXY") + " %s" % g_id
		g_i["discovered"] = false
		var starting_galaxy = c_c == 0 and galaxy_num == total_gal_num and i == 0
		if starting_galaxy:
			g_i = galaxy_data[0]
			radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.5)
			obj_shapes.append({"pos":g_i["pos"], "radius":radius, "outer_radius":g_i["pos"].length() + radius})
			cluster_data[id]["galaxies"].append(0)
		else:
			cluster_data[id]["galaxies"].append(g_id)
			galaxy_data.append(g_i)
	if progress == 1:
		cluster_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			cluster_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	else:
		cluster_data[id]["discovered"] = false
	return progress

func generate_system_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_systems(c_g)
		$Loading.update_bar(progress, tr("GENERATING_GALAXY") % [String(galaxy_data[c_g]["systems"].size()), String(galaxy_data[c_g]["system_num"])])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	add_obj("galaxy")
	remove_child($Loading)
	if not EA_galaxy_visited:
		long_popup("Normally you need to reach a certain level before being able to view other star systems/galaxies/etc., but for testing purposes\nyou can go anywhere without limits.", "Early access note")
		EA_galaxy_visited = true

func generate_systems(id:int):
	randomize()
	var total_sys_num = galaxy_data[id]["system_num"]
	#Systems remaining to load
	var system_num = total_sys_num - galaxy_data[id]["systems"].size()
	
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity

	#Open clusters are
	
	var sys_num_to_load = min(500, system_num)
	var progress = 1 - (system_num - sys_num_to_load) / float(total_sys_num)
	var B = galaxy_data[id].B_strength#Magnetic field strength
	
	for i in range(0, sys_num_to_load):
		var s_i = {}
		s_i["status"] = "unconquered"
		s_i["parent"] = id
		s_i["planets"] = []
		s_i["discovered"] = false
		
		#Checks whether the star is in globular cluster
		var N = obj_shapes.size()
		if N >= total_sys_num / 8:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.9), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
			if gc_remaining > 0 and gc_offset > 1 + int(pow(total_sys_num, 0.1)):
				gc_remaining -= 1
				gc_stars_remaining = int(pow(total_sys_num, 0.5) * rand_range(1, 3))
				gc_center = polar2cartesian(rand_range(min_dist_from_center * 1.25, min_dist_from_center * 1.5), rand_range(0, 2 * PI))
				max_dist_from_center = 100
			gc_offset += 1
		
		var num_stars = 1
#		while randf() < 0.3 / float(num_stars):
#			num_stars += 1
		var stars = []
		for _j in range(0, num_stars):
			var star = {}#Higher a: lower temperature (older) stars
			var a = 1.65 if gc_stars_remaining == 0 else 4.0
			a *= pow(pow10(1, -9) / B, 0.3)
			#Solar masses
			var mass = -log(1 - randf()) / a
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			if mass < 0.08:
				star_size = range_lerp(mass, 0, 0.08, 0.001, 0.1)
				temp = range_lerp(mass, 0, 0.08, 250, 2400)
			if mass >= 0.08 and mass < 0.45:
				star_size = range_lerp(mass, 0.08, 0.45, 0.1, 0.7)
				temp = range_lerp(mass, 0.08, 0.45, 2400, 3700)
			if mass >= 0.45 and mass < 0.8:
				star_size = range_lerp(mass, 0.45, 0.8, 0.7, 0.96)
				temp = range_lerp(mass, 0.45, 0.8, 3700, 5200)
			if mass >= 0.8 and mass < 1.04:
				star_size = range_lerp(mass, 0.8, 1.04, 0.96, 1.15)
				temp = range_lerp(mass, 0.8, 1.04, 5200, 6000)
			if mass >= 1.04 and mass < 1.4:
				star_size = range_lerp(mass, 1.04, 1.4, 1.15, 1.4)
				temp = range_lerp(mass, 1.04, 1.4, 6000, 7500)
			if mass >= 1.4 and mass < 2.1:
				star_size = range_lerp(mass, 1.4, 2.1, 1.4, 1.8)
				temp = range_lerp(mass, 1.4, 2.1, 7500, 10000)
			if mass >= 2.1 and mass < 16:
				star_size = range_lerp(mass, 2.1, 16, 1.8, 6.6)
				temp = range_lerp(mass, 2.1, 16, 10000, 30000)
			if mass >= 16 and mass < 100:
				star_size = range_lerp(mass, 16, 100, 6.6, 22)
				temp = range_lerp(mass, 16, 100, 30000, 70000)
			if mass >= 100 and mass < 1000:
				star_size = range_lerp(mass, 100, 1000, 22, 60)
				temp = range_lerp(mass, 100, 1000, 70000, 120000)
			if mass >= 1000 and mass < 10000:
				star_size = range_lerp(mass, 1000, 10000, 60, 200)
				temp = range_lerp(mass, 1000, 10000, 120000, 210000)
			if mass >= 10000:
				star_size = pow(mass, 1/3.0) * (200 / pow(10000, 1/3.0))
				temp = 210000 * pow(1.45, mass / 10000.0 - 1)
			
			var star_type = ""
			if mass >= 0.08:
				star_type = "main_sequence"
			else:
				star_type = "brown_dwarf"
			
			if mass > 0.2 and mass < 1.3 and randf() < 0.02:
				star_type = "white_dwarf"
				temp = rand_range(4000,10000)
				if randf() < 0.05:
					temp = rand_range(10000, 60000)
				star_size = rand_range(0.006, 0.03)
				mass = rand_range(0.4, 1.2)
			if mass > 0.25 and randf() < 0.08:
				star_type = "giant"
				star_size *= max(rand_range(240000, 280000) / temp, rand_range(1.2, 1.4))
			if star_type == "main-sequence":
				if randf() < 0.01:
					mass = rand_range(10, 50)
					star_type = "supergiant"
					star_size *= max(rand_range(360000, 440000) / temp, rand_range(1.7, 2.1))
				elif randf() < 0.0015:
					mass = rand_range(5, 30)
					star_type = "hypergiant"
					star_size *= max(rand_range(550000, 700000) / temp, rand_range(3.0, 4.0))
					var tier = 1
					while randf() < 0.2:
						tier += 1
						star_type = "hypergiant " + get_roman_num(tier)
						star_size *= 1.2
			
			star_class = get_star_class(temp)
			#star["luminosity"] = pow(mass, rand_range(3, 4))
			star["luminosity"] = clever_round(4 * PI * pow(star_size * pow10(6.957, 8), 2) * pow10(5.67, -8) * pow(temp, 4) / pow10(3.828, 26))
			star["mass"] = clever_round(mass)
			star["size"] = clever_round(star_size)
			star["type"] = star_type
			star["class"] = star_class
			star["temperature"] = clever_round(temp)
			star["pos"] = Vector2.ZERO
			stars.append(star)
		
		var biggest_star_size = 0
#		var combined_star_size = 0
		var combined_star_mass = 0
		for star in stars:
			if star["size"] > biggest_star_size:
				biggest_star_size = star["size"]
#			combined_star_size += star["size"]
			combined_star_mass += star.mass
		var dark_matter = galaxy_data[c_g].dark_matter
		var planet_num:int = max(round(pow(combined_star_mass, 0.3) * Helper.rand_int(3, 12) * dark_matter), 2)
		if planet_num > 30:
			planet_num -= floor((planet_num - 30) / 2)
		s_i["planet_num"] = planet_num
		
		var s_id = system_data.size()
		s_i["id"] = s_id
		s_i["stars"] = stars
		s_i["name"] = tr("STAR_SYSTEM") + " %s" % s_id
		s_i["discovered"] = false
		
		var starting_system = c_g == 0 and system_num == total_sys_num and i == 0
		
		#Collision detection
		var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
		var circle
		var pos
		var colliding = true
		if gc_stars_remaining == 0:
			gc_center = Vector2.ZERO
			if min_dist_from_center == 0:
				max_dist_from_center = 6000
			else:
				max_dist_from_center = min_dist_from_center * pow(total_sys_num, 0.04) * 1.1
		var outer_radius
		var radius_increase_counter = 0
		while colliding:
			colliding = false
			var dist_from_center = rand_range(0, max_dist_from_center)
			if gc_stars_remaining == 0:
				dist_from_center = rand_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI)) + gc_center
			circle = {"pos":pos, "radius":radius, "outer_radius":outer_radius}
			for star_shape in obj_shapes:
				#if Geometry.is_point_in_circle(pos, star_shape.pos, radius + star_shape.radius):
				if pos.distance_to(star_shape["pos"]) < radius + star_shape["radius"]:
					colliding = true
					radius_increase_counter += 1
					if radius_increase_counter > 5:
						max_dist_from_center *= 1.2
						radius_increase_counter = 0
					break
			if not colliding:
				for gc_circle in gc_circles:
					#if Geometry.is_point_in_circle(pos, gc_circle.pos, radius + gc_circle.radius):
					if pos.distance_to(gc_circle["pos"]) < radius + gc_circle["radius"]:
						colliding = true
						radius_increase_counter += 1
						if radius_increase_counter > 5:
							max_dist_from_center *= 1.2
							radius_increase_counter = 0
						break
		if outer_radius > max_outer_radius:
			max_outer_radius = outer_radius
		if gc_stars_remaining > 0:
			gc_stars_remaining -= 1
			gc_circles.append(circle)
			if gc_stars_remaining == 0:
				#Convert globular cluster to a single huge circle for collision detection purposes
				gc_circles.sort_custom(self, "sort_shapes")
				var big_radius = gc_circles[-1]["outer_radius"]
				obj_shapes = [{"pos":gc_center, "radius":big_radius, "outer_radius":gc_center.length() + big_radius}]
				gc_circles = []
		else:
			if not starting_system:
				obj_shapes.append(circle)
		s_i["pos"] = pos
		if starting_system:
			s_i = system_data[0]
			radius = 320 * pow(1 / SYSTEM_SCALE_DIV, 0.3)
			obj_shapes.append({"pos":s_i["pos"], "radius":radius, "outer_radius":s_i["pos"].length() + radius})
			galaxy_data[id]["systems"].append(0)
		else:
			galaxy_data[id]["systems"].append(s_id)
			system_data.append(s_i)
	if progress == 1:
		galaxy_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			galaxy_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	else:
		galaxy_data[id]["discovered"] = false
	return progress

func get_max_star_prop(s_id:int, prop:String):
	var max_star_prop = 0
	for star in system_data[s_id].stars:
		if star[prop] > max_star_prop:
			max_star_prop = star[prop]
	return max_star_prop

func generate_planets(id:int):
	randomize()
	var combined_star_size = 0
	var max_star_temp = get_max_star_prop(id, "temperature")
	var max_star_size = get_max_star_prop(id, "size")
	for star in system_data[id]["stars"]:
		combined_star_size += star["size"]
	var planet_num = system_data[id]["planet_num"]
	var max_distance
	var j = 0
	while pow(1.3, j) * 240 < combined_star_size * 2.63:
		j += 1
	var dark_matter = galaxy_data[c_g].dark_matter
	for i in range(1, planet_num + 1):
		var lakes = ["water", "ammonia", "methane", "co2", "oxygen", "hydrogen"]
		#p_i = planet_info
		var p_i = {}
		p_i["status"] = "unconquered"
		p_i["ring"] = i
		p_i["type"] = Helper.rand_int(3, 10)
		p_i["size"] = int((2000 + rand_range(0, 10000) * (i + 1)) * dark_matter)
		p_i["angle"] = rand_range(0, 2 * PI)
		#p_i["distance"] = pow(1.3,i+(max(1.0,log(combined_star_size*(0.75+0.25/max(1.0,log(combined_star_size)))))/log(1.3)))
		p_i["distance"] = pow(1.3,i + j) * rand_range(240, 270)
		#1 solar radius = 2.63 px = 0.0046 AU
		#569 px = 1 AU = 215.6 solar radii
		max_distance = p_i["distance"]
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		p_i["discovered"] = false
		var p_id = planet_data.size()
		p_i["id"] = p_id
		p_i["name"] = tr("PLANET") + " " + String(p_id)
		system_data[id]["planets"].append(p_id)
		#var temp = 1 / pow(p_i.distance - max_star_size * 2.63, 0.5) * max_star_temp * pow(max_star_size, 0.5)
		var dist_in_km = p_i.distance / 569.0 * pow10(1.5, 8)
		var star_size_in_km = max_star_size * pow10(6.957, 5)#                             V bond albedo
		var temp = max_star_temp * pow(star_size_in_km / (2 * dist_in_km), 0.5) * pow(1 - 0.1, 0.25)
		p_i.temperature = temp# in K
		p_i.pressure = pow10(rand_range(1, 10), Helper.rand_int(-5, int(log(p_i.size) / 2)))# in bars
		p_i.crust = make_planet_composition(temp, "crust")
		p_i.mantle = make_planet_composition(temp, "mantle")
		p_i.core = make_planet_composition(temp, "core")
		p_i.crust_start_depth = Helper.rand_int(50, 450)
		p_i.mantle_start_depth = round(rand_range(0.005, 0.02) * p_i.size * 1000)
		p_i.core_start_depth = round(rand_range(0.4, 0.46) * p_i.size * 1000)
		p_i.surface = add_surface_materials(temp, p_i.crust)
		p_i.liq_seed = randi()
		p_i.liq_period = rand_range(60, 300)
		if p_i.temperature <= 1000:
			if randf() < 0.5:
				var lake = Helper.rand_int(0, len(lakes) - 1)
				p_i.lake_1 = lakes[lake]
				lakes.remove(lake)
			if randf() < 0.5:
				var lake = Helper.rand_int(0, len(lakes) - 1)
				p_i.lake_2 = lakes[lake]
		planet_data.append(p_i)
	
	if id != 0:
		var view_zoom = 400 / max_distance
		system_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	system_data[id]["discovered"] = true

func get_coldest_star_temp(s_id):
	var res = system_data[s_id].stars[0].temperature
	for i in range(1, len(system_data[s_id].stars)):
		if system_data[s_id].stars[i].temperature < res:
			res = system_data[s_id].stars[i].temperature
	return res

func make_lake(tile, state:String, lake:String, which_lake):
	tile.type = "lake"
	tile.tile_str = "%s_%s_%s" % [state, lake, which_lake]

func make_obstacle(tile, type:String):
	tile.type = "obstacle"
	tile.tile_str = type

func generate_tiles(id:int):
	tile_data.clear()
	var p_i:Dictionary = planet_data[id]
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = Helper.get_wid(p_i.size)
	var view_zoom = 3.0 / wid
	p_i.view = {"pos":Vector2(340, 80) / view_zoom, "zoom":view_zoom}
	tile_data.resize(pow(wid, 2))
	#Aurora spawn
	var diff:int = 0
	var tile_from:int = -1
	var tile_to:int = -1
	var rand:float = randf()
	var thiccness:int = ceil(Helper.rand_int(1, 3) * wid / 50.0)
	var pulsation:float = rand_range(0.4, 1)
	var max_star_temp = get_max_star_prop(c_s, "temperature")
	for i in 2:
		if id != 2 and randf() < 0.35:
			#au_int: aurora_intensity
			var au_int = clever_round(rand_range(50000, 100000) * galaxy_data[c_g].B_strength * max_star_temp, 3)
			var au_type = Helper.rand_int(1, 2)
			if tile_from == -1:
				tile_from = Helper.rand_int(0, wid)
				tile_to = Helper.rand_int(0, wid)
			if rand < 0.5:#Vertical
				for j in wid:
					var x_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness / 1.2 * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(x_pos - int(thiccness / 2) + diff, x_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						tile_data[k + j * wid] = {}
						tile_data[k + j * wid].aurora = au_type
						tile_data[k + j * wid].au_int = au_int
			else:#Horizontal
				for j in wid:
					var y_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness / 1.2 * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(y_pos - int(thiccness / 2) + diff, y_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						tile_data[j + k * wid] = {}
						tile_data[j + k * wid].aurora = au_type
						tile_data[j + k * wid].au_int = au_int
			diff = Helper.rand_int(thiccness + 1, wid / 3) * sign(rand_range(-1, 1))
	#We assume that the star system's age is inversely proportional to the coldest star's temperature
	#Age is a factor in crater rarity. Older systems have more craters
	var coldest_star_temp = get_coldest_star_temp(c_s)
	var noise = OpenSimplexNoise.new()
	noise.seed = p_i.liq_seed
	noise.octaves = 1
	noise.period = p_i.liq_period#Higher period = bigger lakes
	var lake_1_phase = "G"
	var lake_2_phase = "G"
	if p_i.has("lake_1"):
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		lake_1_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_1)
	if p_i.has("lake_2"):
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		lake_2_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_2)
	for i in wid:
		for j in wid:
			var level:float = noise.get_noise_2d(i / float(wid) * 512, j / float(wid) * 512)
			var t_id = i % wid + j * wid
			if level > 0.5:
				if lake_1_phase != "G":
					tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
					make_lake(tile_data[t_id], lake_1_phase.to_lower(), p_i.lake_1, 1)
					continue
			if level < -0.5:
				if lake_2_phase != "G":
					tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
					make_lake(tile_data[t_id], lake_2_phase.to_lower(), p_i.lake_2, 2)
					continue
			if p_i.temperature <= 1000 and randf() < 0.001:
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				make_obstacle(tile_data[t_id], "rock")
				continue
			if id == 2:
				continue
			if randf() < 0.1 / pow(wid, 0.9):
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				make_obstacle(tile_data[t_id], "cave")
				tile_data[t_id].cave_id = len(cave_data)
				var floor_size:int = Helper.rand_int(25, 60)
				if wid > 15:
					floor_size *= 1.3
				if wid > 75:
					floor_size *= 1.3
				if wid > 150:
					floor_size *= 1.3
				cave_data.append({"num_floors":Helper.rand_int(1, wid / 3), "floor_size":floor_size})
				continue
			var crater_size = max(0.25, pow(p_i.pressure, 0.3))
			if randf() < 25 / crater_size / pow(coldest_star_temp, 0.8):
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				make_obstacle(tile_data[t_id], "crater")
				tile_data[t_id].crater_variant = Helper.rand_int(1, 3)
				var depth = ceil(pow(10, rand_range(2, 3)) * pow(crater_size, 0.8))
				tile_data[t_id].init_depth = depth
				tile_data[t_id].depth = depth
				tile_data[t_id].crater_metal = "lead"
				for met in met_info:
					if met == "lead":
						continue
					if randf() < 0.3 / pow(met_info[met].rarity, 1.3):
						tile_data[t_id].crater_metal = met
	if lake_1_phase == "G":
		p_i.erase("lake_1")
	if lake_2_phase == "G":
		p_i.erase("lake_2")
	planet_data[id]["discovered"] = true
	if id == 2:
		tile_data[42] = {}
		make_obstacle(tile_data[42], "cave")
		tile_data[42].cave_id = 0
		tile_data[315] = {}
		make_obstacle(tile_data[315], "cave")
		tile_data[315].cave_id = 1
		var curr_time = OS.get_system_time_msecs()
		tile_data[110] = {}
		tile_data[110].tile_str = "RCC"
		tile_data[110].is_constructing = false
		tile_data[110].construction_date = curr_time
		tile_data[110].construction_length = 10
		tile_data[110].type = "bldg"
		tile_data[110].XP = 0
		tile_data[110].path_1 = 1
		tile_data[110].path_1_value = Data.path_1.RCC.value
		tile_data[111] = {}
		tile_data[111].tile_str = "GF"
		tile_data[111].is_constructing = false
		tile_data[111].construction_date = curr_time
		tile_data[111].construction_length = 10
		tile_data[111].type = "bldg"
		tile_data[111].XP = 0
		tile_data[111].path_1 = 1
		tile_data[111].path_2 = 1
		tile_data[111].path_1_value = Data.path_1.GF.value
		tile_data[111].path_2_value = Data.path_2.GF.value
		tile_data[112] = {}
		tile_data[112].type = "obstacle"
		tile_data[112].tile_str = "ship"
	Helper.save_tiles(id)
	tile_data.clear()

func make_planet_composition(temp:float, depth:String):
	randomize()
	var common_elements = {}
	var uncommon_elements = {}
	if temp > -100:
		if depth == "crust":
			common_elements["O"] = rand_range(0.1, 0.19)
			common_elements["Si"] = common_elements["O"] * rand_range(3.9, 4)
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"Mg":0.2,
									"K":0.2,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"U":0.02,
									"Np":0.004,
									"Pu":0.0003
								}
		elif depth == "mantle":
			common_elements["O"] = rand_range(0.15, 0.19)
			common_elements["Si"] = common_elements["O"] * rand_range(3.9, 4)
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"U":0.25,
									"Mg":0.2,
									"K":0.2,
									"Np":0.1,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"Pu":0.01
								}
		else:
			common_elements["Fe"] = rand_range(0.5, 0.95)
			common_elements["Ni"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			common_elements["S"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			uncommon_elements = {	"Cr":0.3,
									"Ta":0.2,
									"W":0.2,
									"Os":0.1,
									"Ir":0.1,
									"Ti":0.1,
									"Co":0.1,
									"Mn":0.1
								}
	else:
		if depth == "crust" or depth == "mantle":
			common_elements["N"] = randf()
			common_elements["H"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["O"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["C"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["S"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["He"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"U":0.25,
									"Mg":0.2,
									"K":0.2,
									"Np":0.1,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"Pu":0.01
								}
		else:
			common_elements["Fe"] = rand_range(0.5, 0.95)
			common_elements["Ni"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			common_elements["S"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			uncommon_elements = {	"Cr":0.3,
									"Ta":0.2,
									"W":0.2,
									"Os":0.1,
									"Ir":0.1,
									"Ti":0.1,
									"Co":0.1,
									"Mn":0.1
								}
	var remaining = 1 - Helper.get_sum_of_dict(common_elements)
	var uncommon_element_count = 0
	for u_el in uncommon_elements.keys():
		if randf() < uncommon_elements[u_el] * 5.0:
			uncommon_element_count += 1
			uncommon_elements[u_el] = 1
	var ucr = [0, 1]#uncommon element ratios
	for _i in range(0, uncommon_element_count - 1):
		ucr.append(randf())
	ucr.sort()
	var result = {}
	var index = 1
	for u_el in uncommon_elements.keys():
		if uncommon_elements[u_el] == 1:
			result[u_el] = (ucr[index] - ucr[index - 1]) * remaining
			index += 1
	for c_el in common_elements.keys():
		result[c_el] = common_elements[c_el]
	return result

func add_surface_materials(temp:float, crust_comp:Dictionary):#Amount in kg
	var surface_mat_info = {	"coal":{"chance":rand_range(0.1, 0.7), "amount":rand_range(50, 150)},
								"glass":{"chance":0.1, "amount":1},
								"sand":{"chance":0.8, "amount":50},
								"clay":{"chance":rand_range(0.05, 0.3), "amount":rand_range(30, 80)},
								"soil":{"chance":rand_range(0.1, 0.8), "amount":rand_range(30, 100)},
								"cellulose":{"chance":rand_range(0.01, 0.5), "amount":rand_range(1, 20)}
	}
	surface_mat_info.sand.chance = pow(crust_comp.Si + crust_comp.O, 0.1) if crust_comp.has_all(["Si", "O"]) else 0.0
	var sand_glass_ratio = clamp(atan(0.01 * (temp + 273 - 1500)) * 1.05 / PI + 1/2, 0, 1)
	surface_mat_info.glass.chance = surface_mat_info.sand.chance * sand_glass_ratio
	surface_mat_info.sand.chance *= (1 - sand_glass_ratio)
	for mat in surface_mat_info:
		surface_mat_info[mat].chance = clever_round(surface_mat_info[mat].chance, 3)
		surface_mat_info[mat].amount = clever_round(surface_mat_info[mat].amount, 3)
	return surface_mat_info

func show_tooltip(txt:String, hide:bool = true):
	if hide:
		hide_tooltip()
	tooltip.text = txt
	if hide:
		tooltip.modulate.a = 0
	tooltip.visible = true
	tooltip.rect_size = Vector2.ZERO
	if tooltip.rect_size.x > 400:
		tooltip.autowrap = true
		yield(get_tree().create_timer(0), "timeout")
		tooltip.rect_size.x = 400
	yield(get_tree().create_timer(0), "timeout")
	tooltip.modulate.a = 1

func hide_tooltip():
	tooltip.visible = false
	tooltip.autowrap = false

func show_adv_tooltip(txt:String, imgs:Array, size:int = 17):
	adv_tooltip.visible = false
	adv_tooltip.text = ""
	adv_tooltip.visible = true
	adv_tooltip.modulate.a = 0
	add_text_icons(adv_tooltip, txt, imgs, size, true)
	yield(get_tree().create_timer(0.02), "timeout")
	adv_tooltip.modulate.a = 1

func hide_adv_tooltip():
	adv_tooltip.visible = false

func add_text_icons(RTL:RichTextLabel, txt:String, imgs:Array, size:int = 17, _tooltip:bool = false):
	RTL.text = ""
	var arr = txt.split("@i")#@i: where images are placed
	var i = 0
	for st in arr:
# warning-ignore:return_value_discarded
		RTL.append_bbcode(st)
		if i != len(imgs):
			RTL.add_image(imgs[i], 0, size)
		i += 1
	if _tooltip:
		var arr2 = txt.split("\n")
		var max_width = 0
		for st in arr2:
			var width = RTL.get_font("Font").get_string_size(st).x * 1.37
			if width > max_width:
				max_width = width
		RTL.rect_min_size.x = max_width + 20
		RTL.rect_size.x = max_width + 20
	yield(get_tree().create_timer(0), "timeout")
	RTL.rect_min_size.y = RTL.get_content_height()
	RTL.rect_size.y = RTL.get_content_height()

var change_view_btn

func put_change_view_btn (info_str, icon_str):
	change_view_btn = TextureButton.new()
	var change_view_icon = load(icon_str)
	change_view_btn.texture_normal = change_view_icon
	add_child(change_view_btn)
	change_view_btn.rect_position = Vector2(-1, 720 - 63)
	change_view_btn.connect("mouse_entered", self, "on_change_view_over", [info_str])
	change_view_btn.connect("mouse_exited", self, "hide_tooltip")
	change_view_btn.connect("pressed", self, "on_change_view_click")

func on_change_view_over (view_str):
	show_tooltip(view_str)

func on_change_view_click ():
	$click.play()
	match c_v:
		"system":
			switch_view("galaxy")
		"galaxy":
			switch_view("cluster")
		"cluster":
			switch_view("supercluster")
		"supercluster":
			switch_view("universe")
		"universe":
			switch_view("dimension")

func YNPanel(text:String):
	var YN = ConfirmationDialog.new()
	$Control.add_child(YN)
	YN.dialog_text = text
	YN.popup_centered()

func add_items(item:String, num:int = 1):
	var cycles = 0
	while num > 0 and cycles < 2:
		var i:int = 0
		for st in items:
			if num <= 0:
				break
			if st != null and st.name == item and st.num != stack_size or st == null:
				if st == null:
					items[i] = {"name":item, "num":0, "type":Helper.get_type_from_name(item), "directory":Helper.get_dir_from_name(item)}
				var sum = items[i].num + num
				var diff = stack_size - items[i].num
				items[i].num = min(stack_size, sum)
				num = max(num - diff, 0)
			i += 1
		cycles += 1
	return num

func remove_items(item:String, num:int = 1):
	while num > 0:
		for st in items:
			if st != null and st.name == item:
				var diff = st.num - num
				st.num = max(0, diff)
				if st.num == 0:
					items[items.find(st)] = null
				if diff == 0:
					return get_item_num(item)
# warning-ignore:narrowing_conversion
				num -= min(abs(diff), num)
	return get_item_num(item)

func get_item_num(item:String):
	var n = 0
	for st in items:
		if st and st.name == item:
			n += st.num
	return n

func get_star_class (temp):
	var cl = ""
	if temp < 600:
		cl = "Y" + String(floor(10 - (temp - 250) / 350 * 10))
	elif temp < 1400:
		cl = "T" + String(floor(10 - (temp - 600) / 800 * 10))
	elif temp < 2400:
		cl = "L" + String(floor(10 - (temp - 1400) / 1000 * 10))
	elif temp < 3700:
		cl = "M" + String(floor(10 - (temp - 2400) / 1300 * 10))
	elif temp < 5200:
		cl = "K" + String(floor(10 - (temp - 3700) / 1500 * 10))
	elif temp < 6000:
		cl = "G" + String(floor(10 - (temp - 5200) / 800 * 10))
	elif temp < 7500:
		cl = "F" + String(floor(10 - (temp - 6000) / 1500 * 10))
	elif temp < 10000:
		cl = "A" + String(floor(10 - (temp - 7500) / 2500 * 10))
	elif temp < 30000:
		cl = "B" + String(floor(10 - (temp - 10000) / 20000 * 10))
	elif temp < 70000:
		cl = "O" + String(floor(10 - (temp - 30000) / 40000 * 10))
	elif temp < 120000:
		cl = "Q" + String(floor(10 - (temp - 70000) / 50000 * 10))
	elif temp < 210000:
		cl = "R" + String(floor(10 - (temp - 120000) / 90000 * 10))
	else:
		cl = "Z"
	return cl

func get_star_modulate (star_class:String):
	var w = int(star_class[1]) / 10.0#weight for lerps
	var m
	var Y9 = Color(25, 0, 0, 255) / 255.0
	var Y0 = Color(66, 0, 0, 255) / 255.0
	var T0 = Color(117, 0, 0, 255) / 255.0
	var L0 = Color(189, 32, 23, 255) / 255.0
	var M0 = Color(255, 181, 108, 255) / 255.0
	var K0 = Color(255, 218, 181, 255) / 255.0
	var G0 = Color(255, 237, 227, 255) / 255.0
	var F0 = Color(249, 245, 255, 255) / 255.0
	var A0 = Color(213, 224, 255, 255) / 255.0
	var B0 = Color(162, 192, 255, 255) / 255.0
	var O0 = Color(140, 177, 255, 255) / 255.0
	var Q0 = Color(134, 255, 117, 255) / 255.0
	var R0 = Color(255, 151, 255, 255) / 255.0
	match star_class[0]:
		"Y":
			m = lerp(Y0, Y9, w)
		"T":
			m = lerp(T0, Y0, w)
		"L":
			m = lerp(L0, T0, w)
		"M":
			m = lerp(M0, L0, w)
		"K":
			m = lerp(K0, M0, w)
		"G":
			m = lerp(G0, K0, w)
		"F":
			m = lerp(F0, G0, w)
		"A":
			m = lerp(A0, F0, w)
		"B":
			m = lerp(B0, A0, w)
		"O":
			m = lerp(O0, B0, w)
		"Q":
			m = lerp(Q0, O0, w)
		"R":
			m = lerp(R0, Q0, w)
		"Z":
			m = Color(0.05, 0.05, 0.05, 1)
	return m

#Checks if player has enough resources to buy/craft/build something
func check_enough(costs):
	var enough = true
	for cost in costs:
		if cost == "money" and money < costs[cost]:
			enough = false
		if cost == "energy" and energy < costs[cost]:
			enough = false
		if mats.has(cost) and mats[cost] < costs[cost]:
			enough = false
		if mets.has(cost) and mets[cost] < costs[cost]:
			enough = false
		if not enough:
			break
	return enough

func deduct_resources(costs):
	for cost in costs:
		if cost == "money":
			money -= costs.money
		if cost == "energy":
			energy -= costs.energy
		if mats.has(cost):
			mats[cost] -= costs[cost]
		if mets.has(cost):
			mets[cost] -= costs[cost]
	HUD.refresh()

func add_resources(costs):
	for cost in costs:
		if cost == "money":
			money += costs.money
		if cost == "energy":
			energy += costs.energy
		if mats.has(cost):
			mats[cost] += costs[cost]
		if mets.has(cost):
			show.metals = true
			mets[cost] += costs[cost]
		if show.has(cost):
			show[cost] = true
	HUD.refresh()

func get_roman_num(num:int):
	if num > 3999:
		return String(num)
	var strs = [["","I","II","III","IV","V","VI","VII","VIII","IX"],["","X","XX","XXX","XL","L","LX","LXX","LXXX","XC"],["","C","CC","CCC","CD","D","DC","DCC","DCCC","CM"],["","M","MM","MMM"]];
	var num_str:String = String(num)

	var res = ""
	var n = num_str.length()
	var c = 0;
	while c < n:
		res = strs[c][int(num_str[n - c - 1])] + res
		c += 1
	return res

func e_notation(num:float):#e notation
	var e = floor(Helper.log10(num))
	var n = num * pow(10, -e)
	return String(clever_round(n)) + "e" + String(e)

func clever_round (num:float, sd:int = 4):#sd: significant digits
	var e = floor(Helper.log10(abs(num)))
	if sd < e + 1:
		return round(num)
	return stepify(num, pow(10, e - sd + 1))

func pow10(n, e):
	return n * pow(10, e)

var quadrant_top_left:PoolVector2Array = [Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]
var quadrant_top_right:PoolVector2Array = [Vector2(640, 0), Vector2(1280, 0), Vector2(1280, 360), Vector2(640, 360)]
var quadrant_bottom_left:PoolVector2Array = [Vector2(0, 360), Vector2(640, 360), Vector2(640, 720), Vector2(0, 720)]
var quadrant_bottom_right:PoolVector2Array = [Vector2(640, 360), Vector2(1280, 360), Vector2(1280, 720), Vector2(640, 720)]
onready var fps_text = $UI/FPS

func _process(delta):
	if delta != 0:
		fps_text.text = String(round(1 / delta)) + " FPS"

var mouse_pos = Vector2.ZERO
onready var item_cursor = $ItemCursor

func sell_all_minerals():
	if minerals > 0:
		money += minerals * (MUs.MV + 4)
		popup(tr("MINERAL_SOLD") % [minerals, minerals * (MUs.MV + 4)], 2)
		minerals = 0
		HUD.refresh()

var cmd_history:Array = []
var cmd_history_index:int = -1

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if Geometry.is_point_in_polygon(mouse_pos, quadrant_top_left):
			tooltip.rect_position = mouse_pos + Vector2(4, 4)
			adv_tooltip.rect_position = mouse_pos + Vector2(4, 4)
		elif Geometry.is_point_in_polygon(mouse_pos, quadrant_top_right):
			tooltip.rect_position = mouse_pos - Vector2(tooltip.rect_size.x + 4, -4)
			adv_tooltip.rect_position = mouse_pos - Vector2(adv_tooltip.rect_size.x + 4, -4)
		elif Geometry.is_point_in_polygon(mouse_pos, quadrant_bottom_left):
			tooltip.rect_position = mouse_pos - Vector2(-4, tooltip.rect_size.y)
			adv_tooltip.rect_position = mouse_pos - Vector2(-4, adv_tooltip.rect_size.y)
		elif Geometry.is_point_in_polygon(mouse_pos, quadrant_bottom_right):
			tooltip.rect_position = mouse_pos - tooltip.rect_size
			adv_tooltip.rect_position = mouse_pos - adv_tooltip.rect_size
		if item_cursor.visible:
			item_cursor.position = mouse_pos

	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen

	#Press Z to view galaxy the system is in, etc. or go back
	if Input.is_action_just_released("change_view"):
		if c_v == "planet_details" and not planet_details.renaming:
			switch_view("system")
		elif c_v == "science_tree":
			on_science_back_pressed()
		elif not has_node("Loading"):
			on_change_view_click()

	if Input.is_action_just_released("right_click"):
		item_to_use.num = 0
		update_item_cursor()
		if len(panels) != 0:
			if c_v != "":
				if not panels[0].polygon:
					panels[0].visible = false
					panels.pop_front()
				elif panels[0] == upgrade_panel:
					remove_upgrade_panel()
				else:
					toggle_panel(panels[0])
			else:
				toggle_panel(panels[0])
			hide_tooltip()
			hide_adv_tooltip()
	
	#F3 to toggle overlay
	if Input.is_action_just_released("toggle"):
		if overlay:
			overlay._on_CheckBox_pressed()
	
	#F7 to hide help
	if Input.is_action_just_released("hide_help"):
		help[help_str] = false
		hide_tooltip()
		hide_adv_tooltip()
	
	if Input.is_action_pressed("shift"):
		#Sell all minerals by pressing Shift C
		if Input.is_action_just_released("construct"):
			sell_all_minerals()
		#Collect all by pressing Shift V
		if Input.is_action_just_released("vehicles"):
			if c_v == "planet":
				view.obj.collect_all()
	
	var cmd_node = $UI/Command
	#/ to type a command
	if Input.is_action_just_released("command") and not cmd_node.visible:
		cmd_node.visible = true
		cmd_node.text = "/"
		cmd_node.call_deferred("grab_focus")
		cmd_node.caret_position = 1
	
	if Input.is_action_just_released("cancel"):
		hide_adv_tooltip()
		hide_tooltip()
		cmd_node.visible = false
	
	if Input.is_action_just_released("enter") and cmd_node.visible:
		cmd_node.visible = false
		cmd_history_index = -1
		var arr:Array = cmd_node.text.substr(1).to_lower().split(" ")
		var cmd:String = arr[0]
		match cmd:
			"setmoney":
				money = arr[1]
			"setmin":
				minerals = arr[1]
			"setmincap":
				mineral_capacity = arr[1]
			"setenergy":
				energy = arr[1]
			"setsp":
				SP = arr[1]
			"setmat":
				mats[arr[2].to_lower()] = arr[1]
			"setmet":
				mets[arr[2].to_lower()] = arr[1]
			"finconstr":
				for tile in tile_data:
					if tile and tile.has("construction_length"):
						var diff_time = tile.construction_date + tile.construction_length - OS.get_system_time_msecs()
						tile.construction_length = 1
						if tile.has("collect_date"):
							tile.collect_date -= diff_time
			"setmulv":
				MUs[arr[2].to_upper()] = arr[1]
		popup("Command executed", 1.5)
		cmd_history.append(cmd_node.text)
		HUD.refresh()
	
	if Input.is_action_just_released("up") and len(cmd_history) > 0 and cmd_node.visible:
		if cmd_history_index < len(cmd_history) - 1:
			cmd_history_index += 1
		cmd_node.text = cmd_history[cmd_history_index]
		cmd_node.caret_position = cmd_node.text.length()
	
	if Input.is_action_just_released("down") and len(cmd_history) > 0 and cmd_node.visible:
		if cmd_history_index > 0:
			cmd_history_index -= 1
		else:
			cmd_history_index = 0
		cmd_node.text = cmd_history[cmd_history_index]
		cmd_node.caret_position = cmd_node.text.length()
	
	if Input.is_action_just_released("hotbar_1") and len(hotbar) > 0:
		var name = hotbar[0]
		if get_item_num(name) > 0:
			inventory.on_slot_press(name, Helper.get_type_from_name(name), Helper.get_dir_from_name(name))
	
	var hotbar_presses = [Input.is_action_just_released("hotbar_1"), Input.is_action_just_released("hotbar_2"), Input.is_action_just_released("hotbar_3"), Input.is_action_just_released("hotbar_4"), Input.is_action_just_released("hotbar_5")]
	for i in 5:
		if len(hotbar) > i and hotbar_presses[i]:
			var name = hotbar[i]
			if get_item_num(name) > 0:
				inventory.on_slot_press(name, Helper.get_type_from_name(name), Helper.get_dir_from_name(name))
#	if Input.is_action_just_released("ui_down") and Input.is_action_pressed("ctrl"):
#		var save_game = File.new()
#		save_game.open("user://Save1/main.hx3", File.WRITE)
#		save_game.store_var(c_v)
#		save_game.store_float(money)
#		save_game.store_float(minerals)
#		save_game.store_float(mineral_capacity)
#		save_game.store_float(energy)
#		save_game.store_float(SP)
#		save_game.store_float(DRs)
#		save_game.store_float(xp)
#		save_game.store_float(xp_to_lv)
#		save_game.store_64(c_u)
#		save_game.store_64(c_sc)
#		save_game.store_64(c_c)
#		save_game.store_64(c_g)
#		save_game.store_64(c_s)
#		save_game.store_64(c_p)
#		save_game.store_64(lv)
#		save_game.store_64(stack_size)
#		save_game.store_8(auto_replace)
#		save_game.store_var(pickaxe)
#		save_game.store_var(science_unlocked)
#		save_game.store_var(mats)
#		save_game.store_var(mets)
#		save_game.store_var(help)
#		save_game.store_var(show)
#		save_game.store_var(universe_data)
#		save_game.store_var(supercluster_data)
#		save_game.store_var(cluster_data)
#		save_game.store_var(galaxy_data)
#		save_game.store_var(system_data)
#		save_game.store_var(planet_data)
#		save_game.store_var(tile_data)
#		save_game.store_var(items)
#		save_game.store_var(hotbar)
#		save_game.close()
#		popup(tr("GAME_SAVED"), 1.2)

func show_item_cursor(texture):
	item_cursor.get_node("Sprite").texture = texture
	update_item_cursor()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	item_cursor.position = mouse_pos
	item_cursor.visible = true

func update_item_cursor():
	if item_to_use.num == 0:
		item_cursor.visible = false
		item_to_use = {"name":"", "type":"", "num":0}
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$Control/BottomInfo.visible = false
	else:
		item_cursor.get_node("Num").text = "x " + String(item_to_use.num)
	if HUD:
		HUD.update_hotbar()
	move_child(item_cursor, get_child_count())

func hide_item_cursor():
	item_cursor.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func cancel_building():
	view.obj.bldg_to_construct = ""
	$Control/BottomInfo.visible = false
	for id in bldg_blueprints:
		tiles[id]._on_Button_button_out()

func change_language():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("interface", "language", TranslationServer.get_locale())
	config.save("user://settings.cfg")
	Data.reload()

func _on_lg_pressed(extra_arg_0):
	TranslationServer.set_locale(extra_arg_0)
	change_language()

func _on_lg_mouse_entered(extra_arg_0):
	show_tooltip(extra_arg_0)

func _on_lg_mouse_exited():
	hide_tooltip()

func _on_Settings_mouse_entered():
	show_tooltip(tr("SETTINGS") + " (P)")

func _on_Settings_mouse_exited():
	hide_tooltip()

func _on_Settings_pressed():
	$click.play()
	toggle_panel(settings)

func _on_NewGame_pressed():
	$Title/Menu/VBoxContainer/NewGame.disconnect("pressed", self, "_on_NewGame_pressed")
	var tween:Tween = Tween.new()
	add_child(tween)
	tween.interpolate_property($Title, "modulate", null, Color(1, 1, 1, 0), 0.5)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)
	_load_game()

func _on_Title_Button_pressed(URL:String):
	OS.shell_open(URL)
