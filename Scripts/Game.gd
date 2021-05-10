extends Node2D

const TEST:bool = true
const SYS_NUM:int = 400

var generic_panel_scene = preload("res://Scenes/Panels/GenericPanel.tscn")
var star_scene = preload("res://Scenes/Decoratives/Star.tscn")
var upgrade_panel_scene = preload("res://Scenes/Panels/UpgradePanel.tscn")
var planet_HUD_scene = preload("res://Scenes/Planet/PlanetHUD.tscn")
var space_HUD_scene = preload("res://Scenes/SpaceHUD.tscn")
var planet_details_scene = preload("res://Scenes/Planet/PlanetDetails.tscn")
var mining_HUD_scene = preload("res://Scenes/Views/Mining.tscn")
var science_tree_scene = preload("res://Scenes/Views/ScienceTree.tscn")
var overlay_scene = preload("res://Scenes/Overlay.tscn")
var annotator_scene = preload("res://Scenes/Annotator.tscn")
var rsrc_scene = preload("res://Scenes/Resource.tscn")
var rsrc_stocked_scene = preload("res://Scenes/ResourceStocked.tscn")
var cave_scene = preload("res://Scenes/Views/Cave.tscn")
var ruins_scene = preload("res://Scenes/Views/Ruins.tscn")
var STM_scene = preload("res://Scenes/Views/ShipTravelMinigame.tscn")
var battle_scene = preload("res://Scenes/Views/Battle.tscn")
var particles_scene = preload("res://Scenes/LiquidParticles.tscn")
var time_scene = preload("res://Scenes/TimeLeft.tscn")
var planet_TS = preload("res://Resources/PlanetTileSet.tres")
var lake_TS = preload("res://Resources/LakeTileSet.tres")
var obstacles_TS = preload("res://Resources/ObstaclesTileSet.tres")
var aurora_scene = preload("res://Scenes/Aurora.tscn")
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var white_rect_scene = preload("res://Scenes/WhiteRect.tscn")
var mass_build_rect = preload("res://Scenes/MassBuildRect.tscn")
var orbit_scene = preload("res://Scenes/Orbit.tscn")
var surface_BG = preload("res://Graphics/Decoratives/Surface.jpg")
var crust_BG = preload("res://Graphics/Decoratives/Crust.jpg")
var mantle_BG = preload("res://Graphics/Decoratives/Mantle.jpg")

var tutorial:Node2D

var construct_panel:Control
var megastructures_panel:Control
var shop_panel:Control
var ship_panel:Control
var upgrade_panel:Control
var craft_panel:Control
var vehicle_panel:Control
var RC_panel:Control
var MU_panel:Control
var SC_panel:Control
var production_panel:Control
var send_ships_panel:Control
var send_fighters_panel:Control
var send_probes_panel:Control
var terraform_panel:Control
var greenhouse_panel:Panel
var shipyard_panel:Panel
var PC_panel:Panel
var AMN_panel:Control
var SPR_panel:Control
var inventory:Control
var settings:Control
var dimension:Control
var planet_details:Control
var overlay:Control
var annotator:Control
onready var tooltip:Control = $Tooltips/Tooltip
onready var adv_tooltip:Control = $Tooltips/AdvTooltip
onready var YN_panel:ConfirmationDialog = $UI/ConfirmationDialog

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
var active_panel

#The base node containing things that can be moved/zoomed in/out
var view


############ Save data ############

#Current view
var c_v:String
var l_v:String

#Player resources
var money:float
var minerals:float
var mineral_capacity:float
var stone:Dictionary
var energy:float
var SP:float
#Dimension remnants
var DRs:float
var lv:int
var xp:float
var xp_to_lv:float

#id of the universe/supercluster/etc. you're viewing the object in
var c_u:int#c_u: current_universe
var c_sc:int#c_sc: current_supercluster
var c_c:int#etc.
var c_c_g:int#etc.
var c_g:int
var c_g_g:int
var c_s:int
var c_s_g:int
var c_p:int
var c_p_g:int
var c_t:int

#Number of items per stack
var stack_size:int

var auto_replace:bool

#Stores information of the current pickaxe the player is holding
var pickaxe:Dictionary

var mats:Dictionary
var mets:Dictionary
var atoms:Dictionary
var particles:Dictionary

#Display help when players see/do things for the first time. true: show help
var help:Dictionary

var science_unlocked:Dictionary
var infinite_research:Dictionary
var MUs:Dictionary#Levels of mineral upgrades
#Measures to not overwhelm beginners. false: not visible
var show:Dictionary

#Stores information of all objects discovered
var universe_data:Array
var supercluster_data:Array
var cluster_data:Array
var galaxy_data:Array# = [{"id":0, "l_id":0, "type":0, "modulate":Color.white, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "B_strength":e(5, -10), "dark_matter":1.0, "discovered":false, "conquered":false, "parent":0, "system_num":SYS_NUM, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(15000 + 1280, 15000 + 720), "zoom":0.5}}]
var system_data:Array
var planet_data:Array
var tile_data:Array
var cave_data:Array

#Vehicle data
var rover_data:Array
var fighter_data:Array
var probe_data:Array
var ship_data:Array
var second_ship_hints:Dictionary
var third_ship_hints:Dictionary
var fourth_ship_hints:Dictionary
var ships_c_coords:Dictionary#Local coords of the planet that the ships are on
var ships_c_g_coords:Dictionary#ship global coordinates (current)
var ships_dest_coords:Dictionary#Local coords of the destination planet
var ships_dest_g_coords:Dictionary#ship global coordinates (destination)
var ships_depart_pos:Vector2#Depart position of system/galaxy/etc. depending on view
var ships_dest_pos:Vector2#Destination position of system/galaxy/etc. depending on view
var ships_travel_view:String#View in which ships travel
var ships_travel_start_date:int
var ships_travel_length:int
var satellite_data:Array

#Your inventory
var items:Array
#var items:Array = [{"name":"lead_seeds", "num":4}, null, null, null, null, null, null, null, null, null]

var hotbar:Array

var STM_lv:int#ship travel minigame level
var rover_id:int#Rover id when in cave

var p_num:int
var s_num:int
var g_num:int#Total number of galaxies generated
var c_num:int

var stats:Dictionary

enum ObjectiveType {BUILD, SAVE, MINE, CONQUER, CRUST, CAVE, LEVEL, WORMHOLE, SIGNAL, DAVID, COLLECT_PARTS, MANIPULATORS, EMMA}
var objective:Dictionary# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}

############ End save data ############
var overlay_CS:float = 0.5
var overlay_data = {	"galaxy":{"overlay":0, "visible":false, "custom_values":[{"left":2, "right":30, "modified":false}, null, null, {"left":0.5, "right":15, "modified":false}, {"left":250, "right":100000, "modified":false}, {"left":1, "right":1, "modified":false}, {"left":1, "right":1, "modified":false}, null]},
						"cluster":{"overlay":0, "visible":false, "custom_values":[{"left":200, "right":10000, "modified":false}, null, {"left":1, "right":100, "modified":false}, {"left":0.2, "right":5, "modified":false}, {"left":0.8, "right":1.2, "modified":false}]},
}
var collect_speed_lag_ratio:int = 1

#Stores data of the item that you clicked in your inventory
var item_to_use = {"name":"", "type":"", "num":0}

var mining_HUD
var science_tree_view = {"pos":Vector2.ZERO, "zoom":1.0}
var cave
var ruins
var STM
var battle
var is_conquering_all:bool = false

var mat_info = {	"coal":{"value":10},#One kg of coal = $10
					"glass":{"value":100},
					"sand":{"value":4},
					#"clay":{"value":12},
					"soil":{"value":6},
					"cellulose":{"value":30},
					"silicon":{"value":50},
}
#Changing length of met_info changes cave rng!
var met_info = {	"lead":{"min_depth":0, "max_depth":500, "amount":20, "rarity":1, "density":11.34, "value":30},
					"copper":{"min_depth":100, "max_depth":750, "amount":20, "rarity":1.7, "density":8.96, "value":55},
					"iron":{"min_depth":200, "max_depth":1000, "amount":20, "rarity":2.6, "density":7.87, "value":85},
					"aluminium":{"min_depth":300, "max_depth":1500, "amount":20, "rarity":4.5, "density":2.7, "value":140},
					"silver":{"min_depth":400, "max_depth":1750, "amount":20, "rarity":7.2, "density":10.49, "value":200},
					"gold":{"min_depth":500, "max_depth":2500, "amount":16, "rarity":10.0, "density":19.3, "value":300},
					"amethyst":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":14.5, "density":2.66, "value":500},
					"emerald":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":14.7, "density":2.70, "value":540},
					"quartz":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":15.0, "density":2.32, "value":580},
					"topaz":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":15.3, "density":3.50, "value":620},
					"ruby":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":15.6, "density":4.01, "value":660},
					"sapphire":{"min_depth":600, "max_depth":3000, "amount":16, "rarity":15.9, "density":3.99, "value":700},
					"platinum":{"min_depth":1000, "max_depth":4000, "amount":14, "rarity":20.0, "density":21.45, "value":1000},
					"titanium":{"min_depth":1400, "max_depth":6000, "amount":14, "rarity":28.5, "density":4.51, "value":1450},
					"diamond":{"min_depth":1800, "max_depth":9000, "amount":14, "rarity":42.0, "density":4.20, "value":2200},
					"nanocrystal":{"min_depth":2400, "max_depth":14000, "amount":12, "rarity":67.5, "density":1.5, "value":3000},
					"mythril":{"min_depth":3000, "max_depth":20000, "amount":12, "rarity":99.4, "density":13.4, "value":4000},
}

var pickaxes_info = {"stick":{"speed":1.0, "durability":140, "costs":{"money":300}},
					"wooden_pickaxe":{"speed":1.5, "durability":300, "costs":{"money":1200}},
					"stone_pickaxe":{"speed":2.1, "durability":500, "costs":{"money":5000}},
					"lead_pickaxe":{"speed":2.9, "durability":650, "costs":{"money":35000}},
					"copper_pickaxe":{"speed":4.3, "durability":800, "costs":{"money":180000}},
					"iron_pickaxe":{"speed":5.9, "durability":1100, "costs":{"money":840000}},
					"aluminium_pickaxe":{"speed":8.8, "durability":1400, "costs":{"money":3500000}},
					"silver_pickaxe":{"speed":12.7, "durability":1700, "costs":{"money":15000000}},
					"gold_pickaxe":{"speed":90.0, "durability":140, "costs":{"money":32500000}},
					"gemstone_pickaxe":{"speed":55.0, "durability":2000, "costs":{"money":e(1.56, 8)}},
					"platinum_pickaxe":{"speed":95.0, "durability":1500, "costs":{"money":e(5.5, 8)}},
					"titanium_pickaxe":{"speed":150.0, "durability":2500, "costs":{"money":e(1.45, 9)}},
					"diamond_pickaxe":{"speed":375.0, "durability":3000, "costs":{"money":e(4.4, 9)}},
					"nanocrystal_pickaxe":{"speed":980.0, "durability":770, "costs":{"money":e(2.2, 10)}},
					"mythril_pickaxe":{"speed":3400.0, "durability":5000, "costs":{"money":e(6.4, 11)}},
}

var speedups_info = {	"speedup1":{"costs":{"money":400}, "time":2*60000},
						"speedup2":{"costs":{"money":2800}, "time":15*60000},
						"speedup3":{"costs":{"money":11000}, "time":60*60000},
						"speedup4":{"costs":{"money":65000}, "time":6*60*60000},
						"speedup5":{"costs":{"money":255000}, "time":24*60*60000},
						"speedup6":{"costs":{"money":1750000}, "time":7*24*60*60000},
}

var overclocks_info = {	"overclock1":{"costs":{"money":1400}, "mult":1.5, "duration":10*60000},
						"overclock2":{"costs":{"money":8500}, "mult":2, "duration":30*60000},
						"overclock3":{"costs":{"money":50000}, "mult":3, "duration":60*60000},
						"overclock4":{"costs":{"money":170000}, "mult":4, "duration":2*60*60000},
						"overclock5":{"costs":{"money":850000}, "mult":6, "duration":6*60*60000},
						"overclock6":{"costs":{"money":9000000}, "mult":10, "duration":24*60*60000},
}

var craft_agriculture_info = {"lead_seeds":{"costs":{"cellulose":10, "lead":20}, "grow_time":3600000, "lake":"H2O", "produce":60},
							"copper_seeds":{"costs":{"cellulose":10, "copper":20}, "grow_time":4800000, "lake":"H2O", "produce":60},
							"iron_seeds":{"costs":{"cellulose":10, "iron":20}, "grow_time":6000000, "lake":"H2O", "produce":60},
							"aluminium_seeds":{"costs":{"cellulose":10, "aluminium":20}, "grow_time":9000000, "lake":"He", "produce":60},
							"silver_seeds":{"costs":{"cellulose":10, "silver":20}, "grow_time":14000000, "lake":"He", "produce":60},
							"gold_seeds":{"costs":{"cellulose":10, "gold":20}, "grow_time":26000000, "lake":"CH4", "produce":60},
							"fertilizer":{"costs":{"cellulose":50, "soil":30}, "speed_up_time":3600000}}

var other_items_info = {"hx_core":{"XP":6}, "hx_core2":{"XP":50}, "hx_core3":{"XP":480}, "ship_locator":{}}

var item_groups = [	{"dict":speedups_info, "path":"Items/Speedups"},
					{"dict":overclocks_info, "path":"Items/Overclocks"},
					{"dict":craft_agriculture_info, "path":"Agriculture"},
					{"dict":other_items_info, "path":"Items/Others"},
					]
#Density is in g/cm^3
var element = {	"Si":{"density":2.329},
				"O":{"density":1.429}}

#Holds information of the tooltip that can be hidden by the player by pressing F7
var help_str:String
var bottom_info_action:String = ""
var autosave_interval:int = 10
var autosell:bool = true

var music_player = AudioStreamPlayer.new()

var dialog:AcceptDialog
var metal_textures:Dictionary = {}
func _ready():
	for metal in met_info:
		metal_textures[metal] = load("res://Graphics/Metals/%s.png" % [metal])
	if TranslationServer.get_locale() != "es":
		TranslationServer.set_locale("en")
	AudioServer.set_bus_volume_db(0, -40)
	YN_panel.connect("popup_hide", self, "popup_close")
	view = load("res://Scenes/Views/View.tscn").instance()
	add_child(view)
	add_child(music_player)
	music_player.bus = "Music"
	#noob
	#AudioServer.set_bus_mute(1,true)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == 7:
		config.save("user://settings.cfg")
		err = config.load("user://settings.cfg")
	if err == OK:
		switch_music(load("res://Audio/Title.ogg"))
		TranslationServer.set_locale(config.get_value("interface", "language", "en"))
		OS.vsync_enabled = config.get_value("graphics", "vsync", true)
		$Autosave.wait_time = config.get_value("saving", "autosave", 10)
		autosave_interval = 10
		if OS.get_name() == "HTML5" and not config.get_value("misc", "HTML5", false):
			long_popup("You're playing the browser version of Helixteus 3. While it's convenient, it has\nmany issues not present in the executables:\n\n - High RAM usage (Firefox: ~1.2 GB, Chrome/Edge: ~700 MB, Windows: ~400 MB)\n - Less FPS\n - Saving delay (5-10 seconds)\n - Some settings do not work\n - Audio glitches", "Browser version", [], [], "I understand")
			config.set_value("misc", "HTML5", true)
		autosell = config.get_value("game", "autosell", false)
		collect_speed_lag_ratio = config.get_value("game", "collect_speed", 1)
		config.save("user://settings.cfg")
	Data.reload()
	var file = Directory.new()
	if file.file_exists("user://Save1/main.hx3"):
		$Title/Menu/VBoxContainer/LoadGame.disabled = false
	settings = load("res://Scenes/Panels/Settings.tscn").instance()
	settings.visible = false
	$Panels/Control.add_child(settings)
	if TEST:
		$Title.visible = false
		HUD = load("res://Scenes/HUD.tscn").instance()
		new_game(false)
		lv = 100
		money = 1000000000000
		mats.soil = 50000
		mats.glass = 1000000
		mets.nanocrystal = 10000000
		show.plant_button = true
		show.mining = true
		show.shop = true
		show.vehicles_button = true
		show.minerals = true
		energy = 2000000000000
		SP = 2000000000000
		science_unlocked.RC = true
		science_unlocked.CD = true
		science_unlocked.SCT = true
		science_unlocked.SA = true
		science_unlocked.EGH = true
		science_unlocked.ATM = true
		science_unlocked.MAE = true
		science_unlocked.FTL = true
		science_unlocked.TF = true
		science_unlocked.FG = true
		stone.O = 800000000
		mats.silicon = 400000
		mats.cellulose = 1000
		mats.coal = 100
		mets.copper = 250000
		mets.iron = 1600000
		mets.aluminium = 500000
		mets.titanium = 50000
		mets.topaz = 50
		show.SP = true
		show.stone = true
		show.glass = true
		show.materials = true
		show.metals = true
		show.atoms = true
		atoms.C = 100
		atoms.Xe = 10000
		items[2] = {"name":"hx_core", "type":"other_items_info", "num":5}
		items[3] = {"name":"lead_seeds", "num":500}
		items[4] = {"name":"fertilizer", "num":500}
		pickaxe = {"name":"stick", "speed":3400, "durability":700}
		rover_data = [{"c_p":2, "ready":true, "HP":200000.0, "atk":5000.0, "def":50000.0, "spd":3.0, "weight_cap":80000.0, "inventory":[{"type":"rover_weapons", "name":"gammaray_laser"}, {"type":"rover_mining", "name":"UV_mining_laser"}, {"type":""}, {"type":""}, {"type":""}], "i_w_w":{}}]
		ship_data = [{"lv":1, "HP":30, "total_HP":30, "atk":10, "def":10, "acc":10, "eva":10, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}, {"lv":1, "HP":30, "total_HP":30, "atk":10, "def":10, "acc":10, "eva":10, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}, {"lv":1, "HP":30, "total_HP":30, "atk":10, "def":10, "acc":10, "eva":10, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
		add_panels()
		$Autosave.start()
	else:
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
		tween.queue_free()

func switch_music(src, pitch:float = 1.0):
	#Music fading
	var tween = Tween.new()
	add_child(tween)
	if music_player.playing:
		tween.interpolate_property(music_player, "volume_db", null, -30, 1, Tween.TRANS_QUAD, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
	music_player.stream = src
	music_player.pitch_scale = pitch
	music_player.play()
	tween.interpolate_property(music_player, "volume_db", -20, 0, 2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)
	tween.queue_free()

func load_game():
	var save_sc = File.new()
	if save_sc.file_exists("user://Save1/supercluster_data.hx3"):
		save_sc.open("user://Save1/supercluster_data.hx3", File.READ)
		supercluster_data = save_sc.get_var()
		save_sc.close()
	var save_game = File.new()
	if save_game.file_exists("user://Save1/main.hx3"):
		save_game.open("user://Save1/main.hx3", File.READ)
		c_v = save_game.get_var()
		l_v = save_game.get_var()
		money = save_game.get_float()
		minerals = save_game.get_float()
		mineral_capacity = save_game.get_float()
		stone = save_game.get_var()
		energy = save_game.get_float()
		SP = save_game.get_float()
		DRs = save_game.get_float()
		xp = save_game.get_float()
		xp_to_lv = save_game.get_float()
		c_u = save_game.get_64()
		c_sc = save_game.get_64()
		c_c = save_game.get_64()
		c_c_g = save_game.get_64()
		c_g = save_game.get_64()
		c_g_g = save_game.get_64()
		c_s = save_game.get_64()
		c_s_g = save_game.get_64()
		c_p = save_game.get_64()
		c_p_g = save_game.get_64()
		c_t = save_game.get_64()
		lv = save_game.get_64()
		stack_size = save_game.get_64()
		auto_replace = save_game.get_8()
		pickaxe = save_game.get_var()
		science_unlocked = save_game.get_var()
		if science_unlocked.CI:
			stack_size = 32
		if science_unlocked.CI2:
			stack_size = 64
		if science_unlocked.CI3:
			stack_size = 128
		science_unlocked.RMK2 = true
		science_unlocked.RMK3 = true
		infinite_research = save_game.get_var()
		mats = save_game.get_var()
		mets = save_game.get_var()
		atoms = save_game.get_var()
		particles = save_game.get_var()
		help = save_game.get_var()
		show = save_game.get_var()
		universe_data = save_game.get_var()
		cave_data = save_game.get_var()
		items = save_game.get_var()
		hotbar = save_game.get_var()
		MUs = save_game.get_var()
		STM_lv = save_game.get_64()
		rover_id = save_game.get_64()
		rover_data = save_game.get_var()
		fighter_data = save_game.get_var()
		probe_data = save_game.get_var()
		ship_data = save_game.get_var()
		second_ship_hints = save_game.get_var()
		third_ship_hints = save_game.get_var()
		fourth_ship_hints = save_game.get_var()
		ships_c_coords = save_game.get_var()
		ships_dest_coords = save_game.get_var()
		ships_depart_pos = save_game.get_var()
		ships_dest_pos = save_game.get_var()
		ships_travel_view = save_game.get_var()
		ships_c_g_coords = save_game.get_var()
		ships_dest_g_coords = save_game.get_var()
		ships_travel_start_date = save_game.get_64()
		ships_travel_length = save_game.get_64()
		p_num = save_game.get_64()
		s_num = save_game.get_64()
		g_num = save_game.get_64()
		c_num = save_game.get_64()
		stats = save_game.get_var()
		objective = save_game.get_var()
		save_game.close()
		if help.tutorial >= 1 and help.tutorial <= 25:
			new_game(true)
		else:
			tile_data = open_obj("Planets", c_p_g)
			if c_v == "mining":
				c_v = "planet"
			$UI.add_child(HUD)
			view.set_process(true)
			var file = Directory.new()
			if file.file_exists("user://Save1/Systems/%s.hx3" % [c_s_g]):
				planet_data = open_obj("Systems", c_s_g)
			if file.file_exists("user://Save1/Galaxies/%s.hx3" % [c_g_g]):
				system_data = open_obj("Galaxies", c_g_g)
			if file.file_exists("user://Save1/Clusters/%s.hx3" % [c_c_g]):
				galaxy_data = open_obj("Clusters", c_c_g)
			else:
				galaxy_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "modulate":Color.white, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "B_strength":e(5, -10), "dark_matter":1.0, "discovered":false, "conquered":false, "parent":0, "system_num":SYS_NUM, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(7500 + 1280, 7500 + 720), "zoom":0.5}}]
				Helper.save_obj("Clusters", 0, galaxy_data)
			if file.file_exists("user://Save1/Superclusters/%s.hx3" % [c_sc]):
				cluster_data = open_obj("Superclusters", c_sc)
			if help.tutorial >= 26:
				tutorial = load("res://Scenes/Tutorial.tscn").instance()
				tutorial.visible = false
				tutorial.tut_num = help.tutorial
				$UI.add_child(tutorial)
			switch_view(c_v, true)
	else:
		popup("load error", 1.5)

func remove_files(dir:Directory):
	dir.list_dir_begin(true)
	var file_name = dir.get_next()
	while file_name != "":
		dir.remove(file_name)
		file_name = dir.get_next()

func new_game(tut:bool):
	var file = File.new()
	var dir = Directory.new()
	if file.file_exists("user://Save1/supercluster_data.hx3"):
		dir.remove("user://Save1/supercluster_data.hx3")
	if dir.open("user://Save1/Planets") == OK:
		remove_files(dir)
	if dir.open("user://Save1/Systems") == OK:
		remove_files(dir)
	if dir.open("user://Save1/Galaxies") == OK:
		remove_files(dir)
	if dir.open("user://Save1/Clusters") == OK:
		remove_files(dir)
	if dir.open("user://Save1/Superclusters") == OK:
		remove_files(dir)
	dir.make_dir("user://Save1")
	dir.make_dir("user://Save1/Planets")
	dir.make_dir("user://Save1/Systems")
	dir.make_dir("user://Save1/Galaxies")
	dir.make_dir("user://Save1/Clusters")
	dir.make_dir("user://Save1/Superclusters")
	c_v = ""
	l_v = ""

	#Player resources
	money = 800
	minerals = 0
	mineral_capacity = 200
	stone = {}
	energy = 200
	SP = 0
	#Dimension remnants
	DRs = 0
	lv = 1
	xp = 0
	xp_to_lv = 10

	#id of the universe/supercluster/etc. you're viewing the object in
	c_u = 0#c_u: current_universe
	c_sc = 0#c_sc: current_supercluster
	c_c = 0#etc.
	c_c_g = 0#etc.
	c_g = 0
	c_g_g = 0
	c_s = 0
	c_s_g = 0
	c_p = 2
	c_p_g = 2
	c_t = -1

	#Number of items per stack
	stack_size = 16

	auto_replace = false

	#Stores information of the current pickaxe the player is holding
	pickaxe = {}

	for sc in Data.science_unlocks:
		science_unlocked[sc] = false
	for sc in Data.infinite_research_sciences:
		infinite_research[sc] = 0
	mats = {	"coal":0,
				"glass":0,
				"sand":0,
				"clay":0,
				"soil":0,
				"cellulose":0,
				"silicon":0,
				#"he3mix":0,
				#"graviton":0,
	}

	mets = {	"lead":0,
				"copper":0,
				"iron":0,
				"aluminium":0,
				"silver":0,
				"gold":0,
				"amethyst":0,
				"emerald":0,
				"quartz":0,
				"topaz":0,
				"ruby":0,
				"sapphire":0,
				"platinum":0,
				"titanium":0,
				"diamond":0,
				"nanocrystal":0,
				"mythril":0,
	}

	atoms = {	"H":0,
				"He":0,
				"C":0,
				"N":0,
				"O":0,
				"F":0,
				"Ne":0,
				"Na":0,
				#"Mg":0,
				"Al":0,
				"Si":0,
				#"P":0,
				#"S":0,
				#"K":0,
				#"Ca":0,
				"Ti":0,
				#"Cr":0,
				#"Mn":0,
				"Fe":0,
				#"Co":0,
				#"Ni":0,
				"Xe":0,
				#"Ta":0,
				#"W":0,
				#"Os":0,
				#"Ir":0,
				#"U":0,
				#"Np":0,
				#"Pu":0,
	}

	particles = {	"proton":0,
					"neutron":0,
					"electron":0,
	}

	#Display help when players see/do things for the first time. true: show help
	help = {
			"tutorial":1 if tut else -1,
			"close_btn1":true,
			"close_btn2":true,
			"mining":true,
			"STM":true,
			"battle":true,
			"plant_something_here":true,
			"boulder_desc":true,
			"aurora_desc":true,
			"cave_desc":true,
			"crater_desc":true,
			"autosave_light_desc":true,
			"tile_shortcuts":true,
			"inventory_shortcuts":true,
			"hotbar_shortcuts":true,
			"rover_shortcuts":true,
			"mass_buy":true,
			"rover_inventory_shortcuts":true,
			"planet_details":true,
			"mass_build":true,
			"abandoned_ship":true,
			"science_tree":true,
			"sprint_mode":true,
			"cave_controls":true,
			"active_wormhole":true,
			"inactive_wormhole":true,
			"cave_diff_info":true,
	}

	MUs = {	"MV":1,
			"MSMB":1,
			"IS":1,
			"AIE":1,
			"STMB":1,
			"SHSR":1,
	}#Levels of mineral upgrades

	#Measures to not overwhelm beginners. false: not visible
	show = {	"minerals":false,
				"stone":false,
				"mining":false,
				"shop":false,
				"SP":false,
				"mining_layer":false,
				"construct_button":not tut,
				"plant_button":false,
				"vehicles_button":false,
				"materials":false,
				"metals":false,
				"atoms":false,
				"particles":false,
				"auroras":false,
	}
	for mat in mats:
		show[mat] = false
	for met in mets:
		show[met] = false
	for atom in atoms:
		show[atom] = false
	for particle in particles:
		show[particle] = false

	#Stores information of all objects discovered
	universe_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "name":"Universe", "diff":1, "discovered":false, "conquered":false, "supercluster_num":8000, "superclusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
	supercluster_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "name":"Laniakea Supercluster", "pos":Vector2.ZERO, "diff":1, "dark_energy":1.0, "discovered":false, "conquered":false, "parent":0, "cluster_num":600, "clusters":[0], "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}}]
	cluster_data = [{"id":0, "l_id":0, "visible":true, "type":0, "shapes":[], "class":"group", "name":"Local Group", "pos":Vector2.ZERO, "diff":1, "discovered":false, "conquered":false, "parent":0, "galaxy_num":55, "galaxies":[], "view":{"pos":Vector2(640 * 3, 360 * 3), "zoom":0.333}}]
	galaxy_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "modulate":Color.white, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "B_strength":e(5, -10), "dark_matter":1.0, "discovered":false, "conquered":false, "parent":0, "system_num":SYS_NUM, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(7500 + 1280, 7500 + 720), "zoom":0.5}}]
	system_data = [{"id":0, "l_id":0, "name":"Solar system", "pos":Vector2(-7500, -7500), "diff":1, "discovered":false, "conquered":false, "parent":0, "planet_num":7, "planets":[], "view":{"pos":Vector2(640, -100), "zoom":1}, "stars":[{"type":"main_sequence", "class":"G2", "size":1, "temperature":5500, "mass":1, "luminosity":1, "pos":Vector2(0, 0)}]}]
	planet_data = []
	tile_data = []
	cave_data = []

	#Vehicle data
	rover_data = []
	fighter_data = []
	probe_data = []
	ship_data = []
	second_ship_hints = {"spawned_at":-1, "spawned_at_p":-1, "ship_locator":false}
	third_ship_hints = {"spawn_galaxy":-1, "map_found_at":-1, "map_pos":Vector2.ZERO, "ship_sys_id":-1, "ship_part_id":-1, "ship_spawned_at_p":-1, "part_spawned_at_p":-1, "parts":[false, false, false, false, false]}
	fourth_ship_hints = {	"ruins_spawned":false,
							"hypergiant_system_spawn_galaxy":-1,
							"dark_matter_spawn_galaxy":-1,
							"hypergiant_system_spawn_system":-1,
							"dark_matter_spawn_system":-1,
							"SE_constructed":true,
							"op_grill_planet":-1,
							"op_grill_cave_spawn":-1,
							"manipulators":[false, false, false, false, false, false],
							"boss_planet":-1,
							"barrier_broken":false,
							"boss_rekt":false,
							"artifact_found":false,
	}
	ships_c_coords = {"sc":0, "c":0, "g":0, "s":0, "p":2}#Local coords of the planet that the ships are on
	ships_c_g_coords = {"c":0, "g":0, "s":0}#ship global coordinates (current)
	ships_dest_coords = {"sc":0, "c":0, "g":0, "s":0, "p":2}#Local coords of the destination planet
	ships_dest_g_coords = {"c":0, "g":0, "s":0}#ship global coordinates (destination)
	ships_depart_pos = Vector2.ZERO#Depart position of system/galaxy/etc. depending on view
	ships_dest_pos = Vector2.ZERO#Destination position of system/galaxy/etc. depending on view
	ships_travel_view = "-"#View in which ships travel
	ships_travel_start_date = -1
	ships_travel_length = -1
	satellite_data = []

	items = [{"name":"speedup1", "num":1, "type":"speedups_info"}, {"name":"overclock1", "num":1, "type":"overclocks_info"}, null, null, null, null, null, null, null, null]

	hotbar = []

	STM_lv = 1#ship travel minigame level
	rover_id = -1#Rover id when in cave

	p_num = 0
	s_num = 0
	g_num = 0#Total number of galaxies generated
	c_num = 0

	stats = {	"bldgs_built":0,
				"wormholes_activated":0,
				"planets_conquered":1,
				}

	objective = {}# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}

	generate_planets(0)
	#Home planet information
	planet_data[2]["name"] = tr("HOME_PLANET")
	planet_data[2]["conquered"] = true
	planet_data[2]["size"] = rand_range(12000, 12100)
	planet_data[2]["angle"] = PI / 2
	planet_data[2]["tiles"] = []
	planet_data[2]["discovered"] = false
	planet_data[2].pressure = 1
	planet_data[2].lake_1 = "H2O"
	planet_data[2].erase("lake_2")
	planet_data[2].liq_seed = 4
	planet_data[2].liq_period = 100
	planet_data[2].crust_start_depth = Helper.rand_int(25, 30)
	planet_data[2].mantle_start_depth = Helper.rand_int(25000, 30000)
	planet_data[2].core_start_depth = Helper.rand_int(4000000, 4200000)
	planet_data[2].surface.coal.chance = 0.5
	planet_data[2].surface.coal.amount = 100
	planet_data[2].surface.soil.chance = 0.6
	planet_data[2].surface.soil.amount = 60
	planet_data[2].surface.cellulose.chance = 0.4
	planet_data[2].surface.cellulose.amount = 10
	Helper.save_obj("Systems", 0, planet_data)
	
	system_data[0].name = tr("SOLAR_SYSTEM")
	galaxy_data[0].name = tr("MILKY_WAY")
	cluster_data[0].name = tr("LOCAL_GROUP")
	supercluster_data[0].name = tr("LANIAKEA")
	
	generate_tiles(2)
	cave_data.append({"num_floors":5, "floor_size":30})
	cave_data.append({"num_floors":8, "floor_size":35})
	
	for u_i in universe_data:
		u_i["epsilon_zero"] = e(8.854, -12)#F/m
		u_i["mu_zero"] = e(1.257, -6)#H/m
		u_i["planck"] = e(6.626, -34)#J.s
		u_i["gravitational"] = e(6.674, -11)#m^3/kg/s^2
		u_i["charge"] = e(1.602, -19)#C
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
		u_i["shapes"] = []
	c_v = "planet"
	Helper.save_obj("Galaxies", 0, system_data)
	Helper.save_obj("Clusters", 0, galaxy_data)
	Helper.save_obj("Superclusters", 0, cluster_data)
	var save_sc = File.new()
	save_sc.open("user://Save1/supercluster_data.hx3", File.WRITE)
	save_sc.store_var(supercluster_data)
	save_sc.close()
	$UI.add_child(HUD)
	if tut:
		tutorial = load("res://Scenes/Tutorial.tscn").instance()
		tutorial.visible = false
		tutorial.tut_num = 1
		$UI.add_child(tutorial)
	add_planet()
	$Autosave.start()
	var init_time = OS.get_system_time_msecs()
	add_panels()
	view.modulate.a = 0
	view.first_zoom = true
	view.zoom_factor = 1.03
	view.zooming = "in"
	view.set_process(true)

func add_panels():
	inventory = load("res://Scenes/Panels/Inventory.tscn").instance()
	shop_panel = generic_panel_scene.instance()
	shop_panel.set_script(load("Scripts/ShopPanel.gd"))
	ship_panel = load("res://Scenes/Panels/ShipPanel.tscn").instance()
	construct_panel = generic_panel_scene.instance()
	construct_panel.set_script(load("Scripts/ConstructPanel.gd"))
	megastructures_panel = load("res://Scenes/Panels/MegastructuresPanel.tscn").instance()
	craft_panel = generic_panel_scene.instance()
	craft_panel.set_script(load("Scripts/CraftPanel.gd"))
	vehicle_panel = load("res://Scenes/Panels/VehiclePanel.tscn").instance()
	RC_panel = load("res://Scenes/Panels/RCPanel.tscn").instance()
	MU_panel = load("res://Scenes/Panels/MUPanel.tscn").instance()
	SC_panel = load("res://Scenes/Panels/SCPanel.tscn").instance()
	production_panel = load("res://Scenes/Panels/ProductionPanel.tscn").instance()
	send_ships_panel = load("res://Scenes/Panels/SendShipsPanel.tscn").instance()
	send_fighters_panel = load("res://Scenes/Panels/SendFightersPanel.tscn").instance()
	send_probes_panel = load("res://Scenes/Panels/SendProbesPanel.tscn").instance()
	terraform_panel = load("res://Scenes/Panels/TerraformPanel.tscn").instance()
	greenhouse_panel = load("res://Scenes/Panels/GreenhousePanel.tscn").instance()
	shipyard_panel = load("res://Scenes/Panels/ShipyardPanel.tscn").instance()
	PC_panel = load("res://Scenes/Panels/PCPanel.tscn").instance()
	AMN_panel = load("res://Scenes/Panels/ReactionsPanel.tscn").instance()
	AMN_panel.set_script(load("Scripts/AMNPanel.gd"))
	SPR_panel = load("res://Scenes/Panels/ReactionsPanel.tscn").instance()
	SPR_panel.set_script(load("Scripts/SPRPanel.gd"))
	
	AMN_panel.visible = false
	$Panels/Control.add_child(AMN_panel)
	
	SPR_panel.visible = false
	$Panels/Control.add_child(SPR_panel)
	
	send_ships_panel.visible = false
	$Panels/Control.add_child(send_ships_panel)
	
	send_fighters_panel.visible = false
	$Panels/Control.add_child(send_fighters_panel)
	
	send_probes_panel.visible = false
	$Panels/Control.add_child(send_probes_panel)
	
	terraform_panel.visible = false
	$Panels/Control.add_child(terraform_panel)
	
	greenhouse_panel.visible = false
	$Panels/Control.add_child(greenhouse_panel)
	
	shipyard_panel.visible = false
	$Panels/Control.add_child(shipyard_panel)
	
	PC_panel.visible = false
	$Panels/Control.add_child(PC_panel)
	
	construct_panel.visible = false
	$Panels/Control.add_child(construct_panel)

	megastructures_panel.visible = false
	$Panels/Control.add_child(megastructures_panel)

	shop_panel.visible = false
	$Panels/Control.add_child(shop_panel)

	ship_panel.visible = false
	$Panels/Control.add_child(ship_panel)

	craft_panel.visible = false
	$Panels/Control.add_child(craft_panel)

	vehicle_panel.visible = false
	$Panels/Control.add_child(vehicle_panel)

	RC_panel.visible = false
	$Panels/Control.add_child(RC_panel)

	MU_panel.visible = false
	$Panels/Control.add_child(MU_panel)

	SC_panel.visible = false
	$Panels/Control.add_child(SC_panel)

	production_panel.visible = false
	$Panels/Control.add_child(production_panel)

	inventory.visible = false
	$Panels/Control.add_child(inventory)

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


func long_popup(txt:String, title:String, other_buttons:Array = [], other_functions:Array = [], ok_txt:String = "OK"):
	hide_adv_tooltip()
	hide_tooltip()
	if dialog and $UI.is_a_parent_of(dialog):
		$UI.remove_child(dialog)
		dialog.queue_free()
	dialog = AcceptDialog.new()
	dialog.theme = load("res://Resources/default_theme.tres")
	dialog.popup_exclusive = true
	dialog.visible = false
	$UI.add_child(dialog)
	$UI/PopupBackground.visible = true
	dialog.window_title = title
	dialog.dialog_text = txt
	dialog.visible = true
	dialog.rect_size = Vector2.ZERO
	dialog.popup_centered()
	for i in range(0, len(other_buttons)):
		dialog.add_button(other_buttons[i], false, other_functions[i])
		if other_functions[i] != "":
			dialog.connect("custom_action", self, "popup_action")
	dialog.connect("popup_hide", self, "popup_close")
	dialog.get_ok().text = ok_txt

func popup_close():
	$UI/PopupBackground.visible = false
	if dialog:
		dialog.visible = false
		if dialog.is_connected("custom_action", self, "popup_action"):
			dialog.disconnect("custom_action", self, "popup_action")
		if dialog.is_connected("popup_hide", self, "popup_close"):
			dialog.disconnect("popup_hide", self, "popup_close")

func popup_action(action:String):
	call(action)
	popup_close()

func open_shop_pickaxe():
	if not shop_panel.visible:
		toggle_panel(shop_panel)
	shop_panel._on_btn_pressed("Pickaxes")

func put_bottom_info(txt:String, action:String, on_close:String = ""):
	if $UI/BottomInfo.visible:
		_on_BottomInfo_close_button_pressed()
	$UI/BottomInfo.visible = true
	$UI.move_child($UI/BottomInfo, $UI.get_child_count())
	var more_info = $UI/BottomInfo/Text
	more_info.visible = false
	more_info.text = txt
	more_info.modulate.a = 0
	more_info.visible = true
	more_info.rect_size.x = 0#This "trick" lets us resize the label to fit the text
	more_info.rect_position.x = -more_info.get_minimum_size().x / 2.0
	more_info.modulate.a = 1
	bottom_info_action = action
	$UI/BottomInfo/CloseButton.on_close = on_close

func fade_in_panel(panel:Control):
	panel.visible = true
	$Panels/Control.move_child(panel, $Panels/Control.get_child_count())
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
	if view:
		view.scroll_view = true
		view.move_view = true

func add_upgrade_panel(ids:Array, planet:Dictionary = {}):
	if active_panel and active_panel != upgrade_panel:
		fade_out_panel(active_panel)
	if upgrade_panel and is_a_parent_of(upgrade_panel):
		remove_upgrade_panel()
	upgrade_panel = upgrade_panel_scene.instance()
	if planet.empty():
		upgrade_panel.ids = ids.duplicate(true)
	else:
		upgrade_panel.planet = planet
	active_panel = upgrade_panel
	if upgrade_panel:
		$Panels/Control.add_child(upgrade_panel)

func remove_upgrade_panel():
	if upgrade_panel:
		$Panels/Control.remove_child(upgrade_panel)
	active_panel = null
	upgrade_panel = null
	if view:
		view.scroll_view = true
		view.move_view = true

func toggle_panel(_panel):
	if active_panel:
		fade_out_panel(active_panel)
		if active_panel == _panel:
			active_panel = null
			return
	active_panel = _panel
	fade_in_panel(_panel)
	_panel.refresh()

func set_home_coords():
	c_u = 0
	c_sc = 0
	c_c = 0
	c_c_g = 0
	c_g = 0
	c_g_g = 0
	c_s = 0
	c_s_g = 0
	c_p = 2
	c_p_g = 2

func set_to_ship_coords():
	c_sc = ships_dest_coords.sc
	c_c_g = ships_dest_g_coords.c
	c_c = ships_dest_coords.c
	c_g_g = ships_dest_g_coords.g
	c_g = ships_dest_coords.g
	c_s_g = ships_dest_g_coords.s
	c_s = ships_dest_coords.s

func set_to_fighter_coords(i:int):
	c_sc = fighter_data[i].c_sc
	c_c_g = fighter_data[i].c_c_g
	c_c = fighter_data[i].c_c
	c_g_g = fighter_data[i].c_g_g
	c_g = fighter_data[i].c_g

func set_to_probe_coords(sc:int):
	c_sc = sc

func set_planet_ids(l_id:int, g_id:int):
	c_p = l_id
	c_p_g = g_id

func set_g_id(l_id:int, g_id:int):
	c_g = l_id
	c_g_g = g_id
#															V function to execute after removing objects but before adding new ones
func switch_view(new_view:String, first_time:bool = false, fn:String = "", fn_args:Array = [], save_zooms:bool = true):
	hide_tooltip()
	hide_adv_tooltip()
	_on_BottomInfo_close_button_pressed()
	$UI/Panel.visible = false
	if not first_time:
		match c_v:
			"planet":
				remove_planet(save_zooms)
			"planet_details":
				remove_child(planet_details)
				planet_details = null
				$UI.add_child(HUD)
			"system":
				remove_system()
				remove_space_HUD()
			"galaxy":
				remove_galaxy()
				remove_space_HUD()
			"cluster":
				remove_cluster()
				remove_space_HUD()
			"supercluster":
				remove_supercluster()
				remove_space_HUD()
			"universe":
				remove_universe()
				remove_space_HUD()
			"dimension":
				remove_dimension()
			"mining":
				remove_mining()
			"science_tree":
				$UI/Help.visible = false
				remove_science_tree()
			"cave":
				$UI.add_child(HUD)
				remove_child(cave)
				cave = null
				switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
			"ruins":
				$UI.add_child(HUD)
				remove_child(ruins)
				ruins = null
				switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
			"STM":
				$UI.add_child(HUD)
				remove_child(STM)
				STM = null
			"battle":
				$UI.add_child(HUD)
				HUD.refresh()
				remove_child(battle)
				battle = null
		if c_v in  ["science_tree", "STM"]:
			c_v = l_v
		else:
			l_v = c_v
			c_v = new_view
	if fn != "":
		callv(fn, fn_args)
	match c_v:
		"planet":
			add_planet()
			HUD.refresh()
		"planet_details":
			planet_details = planet_details_scene.instance()
			add_child(planet_details)
			$UI.remove_child(HUD)
		"system":
			add_space_HUD()
			add_system()
		"galaxy":
			add_space_HUD()
			add_galaxy()
		"cluster":
			add_space_HUD()
			add_cluster()
		"supercluster":
			add_space_HUD()
			add_supercluster()
		"universe":
			add_space_HUD()
			add_universe()
		"dimension":
			add_dimension()
		"mining":
			add_mining()
		"science_tree":
			add_science_tree()
			if help.science_tree:
				$UI/Help.visible = true
				$UI/Help.text = tr("SC_TREE_ZOOM")
				view.obj.get_node("Help").visible = true
				help.science_tree = false
		"cave":
			$UI.remove_child(HUD)
			cave = cave_scene.instance()
			add_child(cave)
			cave.rover_data = rover_data[rover_id]
			cave.set_rover_data()
			switch_music(load("res://Audio/cave1.ogg"), 0.95 if tile_data[c_t].has("aurora") else 1.0)
		"ruins":
			$UI.remove_child(HUD)
			ruins = ruins_scene.instance()
			ruins.ruins_id = tile_data[c_t].ruins
			add_child(ruins)
			ruins.rover_data = rover_data[rover_id]
			switch_music(load("res://Audio/cave1.ogg"), 0.9)
		"STM":
			$Ship.visible = false
			$UI.remove_child(HUD)
			STM = STM_scene.instance()
			add_child(STM)
		"battle":
			$Ship.visible = false
			$UI.remove_child(HUD)
			battle = battle_scene.instance()
			add_child(battle)
	if not first_time:
		fn_save_game(true)

func add_science_tree():
	HUD.get_node("Panel/CollectAll").visible = false
	HUD.get_node("Hotbar").visible = false
	add_obj("science_tree")

func add_mining():
	HUD.get_node("Panel/CollectAll").visible = false
	HUD.get_node("Hotbar").visible = false
	mining_HUD = mining_HUD_scene.instance()
	add_child(mining_HUD)

func remove_mining():
	Helper.save_obj("Planets", c_p_g, tile_data)
	if is_instance_valid(tutorial) and tutorial.tut_num == 15 and objective.empty():
		tutorial.fade()
	HUD.get_node("Panel/CollectAll").visible = true
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

func open_obj(type:String, id:int):
	var arr:Array = []
	var save:File = File.new()
	var file_path:String = "user://Save1/%s/%s.hx3" % [type, id]
	if save.file_exists(file_path):
		save.open(file_path, File.READ)
		arr = save.get_var()
		save.close()
	return arr
	
func obj_exists(type:String, id:int):
	var save:File = File.new()
	var file_path:String = "user://Save1/%s/%s.hx3" % [type, id]
	if save.file_exists(file_path):
		return true
	return false
	
func add_obj(view_str):
	match view_str:
		"planet":
			tile_data = open_obj("Planets", c_p_g)
			view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
		"system":
			view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])
		"galaxy":
			view.shapes_data = galaxy_data[c_g].shapes
			view.add_obj("Galaxy", galaxy_data[c_g]["view"]["pos"], galaxy_data[c_g]["view"]["zoom"])
		"cluster":
			view.shapes_data = cluster_data[c_c].shapes
			view.add_obj("Cluster", cluster_data[c_c]["view"]["pos"], cluster_data[c_c]["view"]["zoom"])
		"supercluster":
			view.shapes_data = supercluster_data[c_sc].shapes
			view.add_obj("Supercluster", supercluster_data[c_sc]["view"]["pos"], supercluster_data[c_sc]["view"]["zoom"], supercluster_data[c_sc]["view"]["sc_mult"])
		"universe":
			view.shapes_data = universe_data[c_u].shapes
			view.add_obj("Universe", universe_data[c_u]["view"]["pos"], universe_data[c_u]["view"]["zoom"], universe_data[c_u]["view"]["sc_mult"])
		"science_tree":
			view.add_obj("ScienceTree", science_tree_view.pos, science_tree_view.zoom)
			var back_btn = Button.new()
			back_btn.name = "ScienceBackBtn"
			back_btn.theme = load("res://Resources/default_theme.tres")
			back_btn.margin_left = -640
			back_btn.margin_top = 320
			back_btn.margin_right = -512
			back_btn.margin_bottom = 360
			back_btn.shortcut_in_tooltip = false
			back_btn.shortcut = ShortCut.new()
			back_btn.shortcut.shortcut = InputEventAction.new()
			add_child(back_btn)
			back_btn.rect_position = Vector2(0, 680)
			back_btn.connect("pressed", self, "on_science_back_pressed")
			Helper.set_back_btn(back_btn)
	view.update()

func on_science_back_pressed():
	switch_view("planet")
	if is_instance_valid(tutorial) and tutorial.tut_num == 26:
		tutorial.begin()
	remove_child(get_node("ScienceBackBtn"))

func add_space_HUD():
	if not is_instance_valid(space_HUD) or not is_a_parent_of(space_HUD):
		space_HUD = space_HUD_scene.instance()
		$UI.add_child(space_HUD)
		if c_v in ["galaxy", "cluster"]:
			space_HUD.get_node("VBoxContainer/Overlay").visible = true
			add_overlay()
		if c_v in ["galaxy", "cluster", "supercluster", "universe"]:
			space_HUD.get_node("VBoxContainer/Annotate").visible = true
			add_annotator()
		space_HUD.get_node("VBoxContainer/Megastructures").visible = c_v == "system" and science_unlocked.MAE
		space_HUD.get_node("ConquerAll").visible = c_v == "system" and lv >= 32 and not system_data[c_s].conquered and ships_c_g_coords.s == c_s_g
		space_HUD.get_node("SendFighters").visible = c_v == "galaxy" and science_unlocked.FG and not galaxy_data[c_g].conquered
		space_HUD.get_node("SendProbes").visible = c_v == "supercluster"

func add_overlay():
	overlay = overlay_scene.instance()
	overlay.visible = false
	#overlay.rect_position = Vector2(640, 720)
	$UI.add_child(overlay)

func remove_overlay():
	if is_instance_valid(overlay) and is_a_parent_of(overlay):
		$UI.remove_child(overlay)
		overlay.free()

func add_annotator():
	annotator = annotator_scene.instance()
	annotator.visible = false
	#annotator.rect_position += Vector2(640, 720)
	$UI.add_child(annotator)

func remove_annotator():
	if is_instance_valid(annotator) and is_a_parent_of(annotator):
		$UI.remove_child(annotator)
		annotator.free()

func remove_space_HUD():
	if is_instance_valid(space_HUD) and is_a_parent_of(space_HUD):
		$UI.remove_child(space_HUD)
		space_HUD.queue_free()
	remove_overlay()
	remove_annotator()

func add_dimension():
	$UI.remove_child(HUD)
	if is_instance_valid(dimension):
		dimension.visible = true
	else:
		dimension = load("res://Scenes/Views/Dimension.tscn").instance()
		add_child(dimension)

func add_universe():
	var view_str:String = tr("VIEW_DIMENSION")
	if lv < 100:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 100"]]
	put_change_view_btn(view_str, "res://Graphics/Buttons/DimensionView.png")
	if not universe_data[c_u]["discovered"]:
		reset_collisions()
		generate_superclusters(c_u)
	add_obj("universe")
	HUD.get_node("Panel/CollectAll").visible = false

func add_supercluster():
	var view_str:String = tr("VIEW_UNIVERSE")
	if lv < 70:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 70"]]
	put_change_view_btn(view_str, "res://Graphics/Buttons/UniverseView.png")
	if obj_exists("Superclusters", c_sc):
		cluster_data = open_obj("Superclusters", c_sc)
	if not supercluster_data[c_sc]["discovered"]:
		reset_collisions()
		if c_sc != 0:
			cluster_data.clear()
		generate_clusters(c_sc)
	add_obj("supercluster")
	HUD.get_node("Panel/CollectAll").visible = false

func add_cluster():
	var view_str:String = tr("VIEW_SUPERCLUSTER")
	if lv < 50:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 50"]]
	put_change_view_btn(view_str, "res://Graphics/Buttons/SuperclusterView.png")
	if obj_exists("Superclusters", c_sc):
		cluster_data = open_obj("Superclusters", c_sc)
	if obj_exists("Clusters", c_c_g):
		galaxy_data = open_obj("Clusters", c_c_g)
	if not cluster_data[c_c]["discovered"]:
		add_loading()
		reset_collisions()
		if c_c_g != 0:
			galaxy_data.clear()
		generate_galaxy_part()
	else:
		add_obj("cluster")
	HUD.get_node("Panel/CollectAll").visible = false

func add_galaxy():
	var view_str:String = tr("VIEW_CLUSTER")
	if lv < 35:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 35"]]
	put_change_view_btn(view_str, "res://Graphics/Buttons/ClusterView.png")
	if obj_exists("Clusters", c_c_g):
		galaxy_data = open_obj("Clusters", c_c_g)
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	if not galaxy_data[c_g]["discovered"]:
		yield(start_system_generation(), "completed")
	add_obj("galaxy")
	HUD.get_node("Panel/CollectAll").visible = true

func start_system_generation():
	yield(get_tree(), "idle_frame")
	add_loading()
	reset_collisions()
	gc_remaining = floor(pow(galaxy_data[c_g]["system_num"], 0.8) / 250.0)
	if c_g_g != 0:
		system_data.clear()
	yield(generate_system_part(), "completed")
	
func add_system():
	var view_str:String = tr("VIEW_GALAXY")
	if lv < 18:
		view_str += "\n%s" % [tr("REACH_X_TO_UNLOCK") % [tr("LV") + " 18"]]
	put_change_view_btn(view_str, "res://Graphics/Buttons/GalaxyView.png")
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	planet_data = open_obj("Systems", c_s_g)
	if not system_data[c_s]["discovered"] or planet_data.empty():
		if c_s_g != 0:
			planet_data.clear()
		generate_planets(c_s)
	add_obj("system")
	HUD.get_node("Panel/CollectAll").visible = true

func add_planet():
	planet_data = open_obj("Systems", c_s_g)
	if not planet_data[c_p].discovered:
		generate_tiles(c_p)
	add_obj("planet")
	view.obj.icons_hidden = view.scale.x >= 0.25
	planet_HUD = planet_HUD_scene.instance()
	add_child(planet_HUD)
	HUD.get_node("Panel/CollectAll").visible = true

func remove_dimension():
	$UI.add_child(HUD)
	dimension.visible = false
	view.dragged = true

func remove_universe():
	$UI.remove_child(change_view_btn)
	change_view_btn.queue_free()
	view.remove_obj("universe")

func remove_supercluster():
	view.remove_obj("supercluster")
	Helper.save_obj("Superclusters", c_sc, cluster_data)
	$UI.remove_child(change_view_btn)
	change_view_btn.queue_free()

func remove_cluster():
	view.remove_obj("cluster")
	Helper.save_obj("Superclusters", c_sc, cluster_data)
	Helper.save_obj("Clusters", c_c_g, galaxy_data)
	$UI.remove_child(change_view_btn)
	change_view_btn.queue_free()

func remove_galaxy():
	view.remove_obj("galaxy")
	Helper.save_obj("Clusters", c_c_g, galaxy_data)
	Helper.save_obj("Galaxies", c_g_g, system_data)
	$UI.remove_child(change_view_btn)
	change_view_btn.queue_free()

func remove_system():
	view.remove_obj("system")
	Helper.save_obj("Galaxies", c_g_g, system_data)
	Helper.save_obj("Systems", c_s_g, planet_data)
	$UI.remove_child(change_view_btn)
	change_view_btn.queue_free()

func remove_planet(save_zooms:bool = true):
	view.remove_obj("planet", save_zooms)
	vehicle_panel.tile_id = -1
	Helper.save_obj("Systems", c_s_g, planet_data)
	Helper.save_obj("Planets", c_p_g, tile_data)
	_on_BottomInfo_close_button_pressed()
	#$UI/BottomInfo.visible = false
	remove_child(planet_HUD)
	planet_HUD.queue_free()

#Collision detection of systems, galaxies etc.
var obj_shapes = []
var obj_shapes2 = []
var max_outer_radius = 0
var min_dist_from_center = 0
var max_dist_from_center = 0
var stars_failed:Array = []

#For globular cluster generation
var gc_remaining = 0
var gc_stars_remaining = 0
var gc_center = Vector2.ZERO
#To not put gc near galactic core
var gc_offset = 0
var gc_circles = []

func reset_collisions():
	obj_shapes.clear()
	max_outer_radius = 0
	min_dist_from_center = 0
	max_dist_from_center = 0
	gc_remaining = 0
	gc_stars_remaining = 0
	gc_center = Vector2.ZERO
	gc_offset = 0
	gc_circles.clear()
	stars_failed.clear()

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
		sc_i["conquered"] = false
		sc_i["type"] = Helper.rand_int(0, 0)
		sc_i["parent"] = id
		sc_i["clusters"] = []
		sc_i["shapes"] = []
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
		sc_i.diff = clever_round(universe_data[id].difficulty * pos.length(), 3)
		universe_data[id]["superclusters"].append(sc_id)
		supercluster_data.append(sc_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		universe_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	universe_data[id]["discovered"] = true
	var save_sc = File.new()
	save_sc.open("user://Save1/supercluster_data.hx3", File.WRITE)
	save_sc.store_var(supercluster_data)
	save_sc.close()

func generate_clusters(id:int):
	randomize()
	var total_clust_num = supercluster_data[id]["cluster_num"]
	max_dist_from_center = pow(total_clust_num, 0.5) * 500
	for _i in range(0, total_clust_num):
		if id == 0 and _i == 0:
			continue
		var c_i = {}
		c_i["conquered"] = false
		c_i["type"] = Helper.rand_int(0, 0)
		c_i["class"] = "group" if randf() < 0.5 else "cluster"
		c_i["parent"] = id
		c_i["visible"] = TEST
		c_i["galaxies"] = []
		c_i["shapes"] = []
		c_i["discovered"] = false
		var c_id = cluster_data.size()
		if c_i["class"] == "group":
			c_i["galaxy_num"] = Helper.rand_int(10, 100)
			c_i.name = tr("GALAXY_GROUP") + " %s" % c_id
		else:
			c_i["galaxy_num"] = Helper.rand_int(500, 5000)
			c_i.name = tr("GALAXY_CLUSTER") + " %s" % c_id
		var pos
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center + 160
		if id == 0 and _i == 1:
			dist_from_center = 150
			c_i.class = "group"
			c_i.galaxy_num = Helper.rand_int(80, 100)
		if id == 0 and _i == 3:
			dist_from_center = 300
			c_i.name = "%s 3" % tr("CLUSTER")
			c_i.class = "group"
			c_i.galaxy_num = Helper.rand_int(80, 100)
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		c_i["pos"] = pos
		c_i["id"] = c_id + c_num
		c_i["l_id"] = c_id
		c_i["discovered"] = false
		if id == 0:
			c_i.diff = clever_round(1 + pos.length(), 3)
		else:
			c_i.diff = clever_round(supercluster_data[id].diff * rand_range(0.8, 1.2), 3)
		supercluster_data[id]["clusters"].append(c_id)
		cluster_data.append(c_i)
	if id != 0:
		var view_zoom = 500.0 / max_dist_from_center
		supercluster_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom, "sc_mult":1.0}
	supercluster_data[id]["discovered"] = true
	c_num += total_clust_num
	Helper.save_obj("Superclusters", c_sc, cluster_data)

func generate_galaxy_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_galaxies(c_c)
		$Loading.update_bar(progress, tr("GENERATING_CLUSTER") % [cluster_data[c_c]["galaxies"].size(), cluster_data[c_c]["galaxy_num"]])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	g_num += cluster_data[c_c].galaxy_num
	Helper.save_obj("Clusters", c_c_g, galaxy_data)
	Helper.save_obj("Superclusters", c_sc, cluster_data)
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
		g_i["conquered"] = false
		g_i["parent"] = id
		g_i["systems"] = []
		g_i["discovered"] = false
		g_i["shapes"] = []
		g_i["type"] = Helper.rand_int(0, 6)
		var rand = randf()
		if g_i.type == 6:
			g_i["system_num"] = int(5000 + 15000 * pow(randf(), 2))
			g_i["B_strength"] = clever_round(e(1, -9) * rand_range(2, 10), 3)#Influences star classes
			g_i.dark_matter = rand_range(0.8, 1) + dark_energy - 1 #Influences planet numbers and size
			var sat:float = rand_range(0, 0.5)
			var hue:float = rand_range(sat / 5.0, 1 - sat / 5.0)
			g_i.modulate = Color().from_hsv(hue, sat, 1.0)
		else:
			g_i["system_num"] = int(pow(randf(), 2) * 8000) + 2000
			g_i["B_strength"] = clever_round(e(1, -9) * rand_range(0.5, 5) * pow(dark_energy, 2), 3)
			g_i.dark_matter = rand_range(0.9, 1.1) + dark_energy - 1
			if randf() < 0.6: #Dwarf galaxy
				g_i["system_num"] /= 10
				if c_c_g == 1 and fourth_ship_hints.hypergiant_system_spawn_galaxy == -1:
					fourth_ship_hints.hypergiant_system_spawn_galaxy = i
					g_i.B_strength = e(5, -9)
				if c_c_g == 3 and fourth_ship_hints.dark_matter_spawn_galaxy == -1:
					fourth_ship_hints.dark_matter_spawn_galaxy = i
					g_i.dark_matter = 2.7
					rand = 1
		if rand < 0.02:
			g_i.dark_matter = pow(g_i.dark_matter, 2.5)
		elif rand < 0.2:
			g_i.dark_matter = pow(g_i.dark_matter, 1.8)
		g_i.dark_matter = clever_round(g_i.dark_matter, 3)
		g_i["rotation"] = rand_range(0, 2 * PI)
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
		g_i["id"] = g_id + g_num
		g_i["l_id"] = g_id
		g_i["name"] = tr("GALAXY") + " %s" % [g_id + g_num]
		g_i["discovered"] = false
		var starting_galaxy = c_c == 0 and galaxy_num == total_gal_num and i == 0
		if starting_galaxy:
			g_i = galaxy_data[0]
			radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.7)
			obj_shapes.append({"pos":g_i["pos"], "radius":radius, "outer_radius":g_i["pos"].length() + radius})
			cluster_data[id]["galaxies"].append(0)
		else:
			if id == 0:#if the galaxies are in starting cluster
				g_i.diff = clever_round(1 + pos.distance_to(galaxy_data[0].pos) / 70, 3)
			else:
				g_i.diff = clever_round(cluster_data[id].diff * rand_range(120, 150) / max(100, pow(pos.length(), 0.5)), 3)
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

func update_loading_bar(curr:float, total:float, txt:String):
	$Loading.update_bar(curr / total, txt % [curr, total])
	#yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	
func generate_system_part():
	generate_systems(c_g)
	var N:int = galaxy_data[c_g].system_num
	if galaxy_data[c_g].type == 6:
		var r:float = N / 20.0
		var init_th:float = rand_range(0, PI)
		var th:float = init_th
		update_loading_bar(0, N, tr("GENERATING_GALAXY"))
		#yield(get_tree().create_timer(5),"timeout")
		var N_init:int = systems_collision_detection2(c_g, 0, 0, 0, true)#Generate stars at the center
		var N_progress:int = N_init
		while N_progress < (N + N_init) / 2.0:#Arm #1
			var progress:float = inverse_lerp(N_init, (N + N_init) / 2.0, N_progress)
			N_progress = systems_collision_detection2(c_g, N_progress, r, th)
			th += 0.4 - lerp(0, 0.33, progress)
			r += (1 - lerp(0, 0.8, progress)) * 1280 * lerp(1.3, 4, inverse_lerp(5000, 20000, N))
			update_loading_bar(N_progress - len(stars_failed), N, tr("GENERATING_GALAXY"))
			yield(get_tree().create_timer(0.0000000000001),"timeout")
		th = init_th + PI
		r = N / 20.0
		while N_progress < N:#Arm #2
			var progress:float = inverse_lerp((N + N_init) / 2.0, N, N_progress)
			N_progress = systems_collision_detection2(c_g, N_progress, r, th)
			th += 0.4 - lerp(0, 0.33, progress)
			r += (1 - lerp(0, 0.8, progress)) * 1280 * lerp(1.3, 4, inverse_lerp(5000, 20000, N))
			update_loading_bar(N_progress - len(stars_failed), N, tr("GENERATING_GALAXY"))
			yield(get_tree().create_timer(0.0000000000001),"timeout")
		for i in len(stars_failed):#Put stars that failed to pass the collision tests above
			var attempts:int = 0
			var s_i = system_data[stars_failed[i]]
			var biggest_star_size = get_biggest_star_size(stars_failed[i])
			#Collision detection
			var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
			r = rand_range(0, max_outer_radius)
			th = rand_range(0, 2 * PI)
			var pos:Vector2 = polar2cartesian(r, th)
			var coll:bool = true
			while coll:
				coll = false
				for circ in obj_shapes + obj_shapes2:
					if pos.distance_to(circ.pos) < circ.radius + radius:
						coll = true
						r = rand_range(0, max_outer_radius)
						th = rand_range(0, 2 * PI)
						pos = polar2cartesian(r, th)
						break
				attempts += 1
				if attempts > 20:
					max_outer_radius *= 1.1
					attempts = 0
			s_i.pos = pos
			s_i.diff = get_sys_diff(pos, c_g, s_i)
			obj_shapes2.append({"pos":pos, "radius":radius})
			if i % 100 == 0:
				update_loading_bar(N - len(stars_failed) + i, N, tr("GENERATING_GALAXY"))
				yield(get_tree().create_timer(0.0000000000001),"timeout")
		if c_g != 0:
			var view_zoom = 500.0 / max_outer_radius
			galaxy_data[c_g]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	else:
		for i in range(0, N, 500):
			systems_collision_detection(c_g, i)
			update_loading_bar(i, N, tr("GENERATING_GALAXY"))
			yield(get_tree().create_timer(0.0000000000001),"timeout")
	if c_g_g == 0 and second_ship_hints.spawned_at == -1:
		#Second ship can only appear in a system in the rectangle formed by solar system and center of galaxy
		var rect:Rect2 = Rect2(Vector2.ZERO, system_data[0].pos)
		rect = rect.abs()
		for system in system_data:
			if system.id == 0:
				continue
			if rect.has_point(system.pos) and randf() < 0.1:
				system.second_ship = Helper.rand_int(1, system.planet_num)
				second_ship_hints.spawned_at = system.id
				break
	s_num += galaxy_data[c_g].system_num
	Helper.save_obj("Galaxies", c_g_g, system_data)
	Helper.save_obj("Clusters", c_c_g, galaxy_data)
	remove_child($Loading)

func systems_collision_detection2(id:int, N_init:int, r, th, center:bool = false):
	var N:int = galaxy_data[id].system_num
	var circ_size = pow(N * 1.5, 0.95)# + N_init
	var N_fin:int = min(N_init + lerp(100, 400, inverse_lerp(5000, 20000, N)), N)
	if center:
		N_fin += circ_size / 20.0
	for i in range(N_init, N_fin):
		var s_i = system_data[i]
		var starting_system = c_g_g == 0 and i == 0
		var biggest_star_size = get_biggest_star_size(i)
		#Collision detection
		var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
		var r2 = rand_range(0, circ_size)
		var th2 = rand_range(0, 2 * PI)
		var pos:Vector2 = polar2cartesian(r, th) + polar2cartesian(r2, th2)
		var coll:bool = true
		var attempts:int = 0
		var cont:bool = true
		while coll:
			coll = false
			if attempts > 10:
				coll = false
				cont = false
				stars_failed.append(i)
				break
			for circ in obj_shapes + obj_shapes2:
				if pos.distance_to(circ.pos) < circ.radius + radius:
					coll = true
					attempts += 1
					r2 = rand_range(0, circ_size)
					th2 = rand_range(0, 2 * PI)
					pos = polar2cartesian(r, th) + polar2cartesian(r2, th2)
					break
		if cont:
			if pos.length() > max_outer_radius:
				max_outer_radius = pos.length()
			if starting_system:
				obj_shapes2.append({"pos":system_data[0].pos, "radius":radius})
			else:
				s_i.pos = pos
				s_i.diff = get_sys_diff(pos, id, s_i)
				obj_shapes2.append({"pos":pos, "radius":radius})
	obj_shapes.append({"pos":polar2cartesian(r, th), "radius":circ_size})
	obj_shapes2.clear()
	return N_fin

func systems_collision_detection(id:int, N_init:int):
	var total_sys_num = galaxy_data[id]["system_num"]
	var N_fin:int = min(N_init + 500, total_sys_num)
	for i in range(N_init, N_fin):
		var s_i = system_data[i]
		var starting_system = c_g_g == 0 and i == 0
		var N = obj_shapes.size()
		#Whether to move on to a new "ring" for collision detection
		if N >= total_sys_num / 8:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.9), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
			#								V this condition makes sure globular clusters don't spawn near the center
			if gc_remaining > 0 and gc_offset > 1 + int(pow(total_sys_num, 0.1)):
				gc_remaining -= 1
				gc_stars_remaining = int(pow(total_sys_num, 0.5) * rand_range(1, 3))
				gc_center = polar2cartesian(min_dist_from_center, rand_range(0, 2 * PI))
				max_dist_from_center = 100
			gc_offset += 1
		
		var biggest_star_size = get_biggest_star_size(i)
		#Collision detection
		var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
		var circle
		var pos
		var colliding = true
		if gc_stars_remaining == 0:
			gc_center = Vector2.ZERO
			if min_dist_from_center == 0:
				max_dist_from_center = 3000
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
		if starting_system:
			radius = 320 * pow(1 / SYSTEM_SCALE_DIV, 0.3)
			obj_shapes.append({"pos":s_i["pos"], "radius":radius, "outer_radius":s_i["pos"].length() + radius})
		else:
			s_i["pos"] = pos
			s_i.diff = get_sys_diff(pos, id, s_i)
	if c_g_g != 0 and N_fin == total_sys_num:
		var view_zoom = 500.0 / max_outer_radius
		galaxy_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}

func get_sys_diff(pos:Vector2, id:int, s_i:Dictionary):
	var stars = s_i.stars
	var combined_star_mass = 0
	for star in stars:
		combined_star_mass += star.mass
	if c_g_g == 0:
		return clever_round(1 + pos.distance_to(system_data[0].pos) * pow(combined_star_mass, 0.5) / 5000, 3)
	else:
		return clever_round(galaxy_data[id].diff * pow(combined_star_mass, 0.4) * rand_range(120, 150) / max(100, pow(pos.length(), 0.5)), 3)
	
func generate_systems(id:int):
	randomize()
	var total_sys_num = galaxy_data[id]["system_num"]
	var spiral:bool = galaxy_data[id].type == 6
	
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity

	#Open clusters are
	var B = galaxy_data[id].B_strength#Magnetic field strength
	
	for i in range(0, total_sys_num):
		if c_g_g == 0 and i == 0:
			continue
		var s_i = {}
		s_i["conquered"] = false
		s_i["parent"] = id
		s_i["planets"] = []
		s_i["discovered"] = false
		
		var num_stars = 1
#		while randf() < 0.3 / float(num_stars):
#			num_stars += 1
		var stars = []
		var hypergiant_system:bool = c_c_g == 1 and fourth_ship_hints.hypergiant_system_spawn_galaxy == id and fourth_ship_hints.hypergiant_system_spawn_system == -1
		var dark_matter_system:bool = c_c_g == 3 and fourth_ship_hints.dark_matter_spawn_galaxy == id and fourth_ship_hints.dark_matter_spawn_system == -1
		for _j in range(0, num_stars):
			var star = {}#Higher a: lower temperature (older) stars
			var a = 1.65 if gc_stars_remaining == 0 else 4.0
			a *= pow(e(1, -9) / B, 0.3)#Higher B: hotter stars
			#Solar masses
			var mass:float = -log(1 - randf()) / a
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			if mass < 0.08:
				star_size = range_lerp(mass, 0, 0.08, 0.01, 0.1)
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
			if not dark_matter_system:
				if mass > 0.2 and mass < 1.3 and randf() < 0.05:
					star_type = "white_dwarf"
					temp = 4000 + exp(10 * randf())
					star_size = rand_range(0.008, 0.02)
					mass = rand_range(0.4, 0.8)
				else:
					if mass > 0.25 and randf() < 0.08:
						star_type = "giant"
						star_size *= max(rand_range(240000, 280000) / temp, rand_range(1.2, 1.4))
					if star_type == "main_sequence":
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
			if hypergiant_system:
				fourth_ship_hints.hypergiant_system_spawn_system = system_data.size() + s_num
				star_type = "hypergiant XV"
				mass = rand_range(4, 4.05)
				temp = range_lerp(mass, 2.1, 16, 10000, 30000)
				star_size = range_lerp(mass, 2.1, 16, 1.8, 6.6) * pow(1.2, 15) * 15
			star_class = get_star_class(temp)
			star["luminosity"] = clever_round(4 * PI * pow(star_size * e(6.957, 8), 2) * e(5.67, -8) * pow(temp, 4) / e(3.828, 26))
			star["mass"] = clever_round(mass)
			star["size"] = clever_round(star_size)
			star["type"] = star_type
			star["class"] = star_class
			star["temperature"] = clever_round(temp)
			star["pos"] = Vector2.ZERO
			stars.append(star)
		var combined_star_mass = 0
		for star in stars:
			combined_star_mass += star.mass
		var dark_matter = galaxy_data[c_g].dark_matter
		var planet_num:int = max(round(pow(combined_star_mass, 0.3) * Helper.rand_int(3, 9) * dark_matter), 2)
		if planet_num > 30:
			planet_num -= floor((planet_num - 30) / 2)
		if planet_num > 40:
			planet_num -= floor((planet_num - 40) / 2)
		if hypergiant_system:
			planet_num = 5
		elif dark_matter_system:
			fourth_ship_hints.dark_matter_spawn_system = system_data.size() + s_num
			planet_num = 1
		s_i["planet_num"] = planet_num
		
		var s_id = system_data.size()
		s_i["id"] = s_id + s_num
		s_i["l_id"] = s_id
		s_i["stars"] = stars
		s_i["name"] = tr("SYSTEM") + " %s" % s_id
		s_i["discovered"] = false
		s_i.pos = Vector2.ZERO
		galaxy_data[id]["systems"].append({"global":s_i.id, "local":s_i.l_id})
		system_data.append(s_i)
	galaxy_data[id]["discovered"] = true
	if third_ship_hints.spawn_galaxy == -1 and c_c_g == 0 and c_g_g != 0 and total_sys_num < 2000:
		third_ship_hints.spawn_galaxy = c_g
		third_ship_hints.ship_sys_id = Helper.rand_int(1, galaxy_data[c_g].system_num) - 1
		third_ship_hints.ship_part_id = Helper.rand_int(1, galaxy_data[c_g].system_num) - 1
		third_ship_hints.g_g_id = c_g_g
		third_ship_hints.g_l_id = c_g
		long_popup(tr("TELEGRAM_TEXT"), tr("TELEGRAM"))

func get_max_star_prop(s_id:int, prop:String):
	var max_star_prop = 0	
	for star in system_data[s_id].stars:
		if star[prop] > max_star_prop:
			max_star_prop = star[prop]
	return max_star_prop

func generate_planets(id:int):#local id
	randomize()
	var combined_star_size = 0
	var combined_star_mass = 0
	var max_star_temp = get_max_star_prop(id, "temperature")
	var max_star_size = get_max_star_prop(id, "size")
	var star_size_in_km = max_star_size * e(6.957, 5)
	for star in system_data[id]["stars"]:
		combined_star_size += star["size"]
		combined_star_mass += star.mass
	var planet_num = system_data[id]["planet_num"]
	var max_distance
	var j = 0
	while pow(1.3, j) * 240 < combined_star_size * 2.63:
		j += 1
	var dark_matter = galaxy_data[c_g].dark_matter
	system_data[id]["planets"].clear()
	var hypergiant_system:bool = c_s_g == fourth_ship_hints.hypergiant_system_spawn_system
	var dark_matter_system:bool = c_s_g == fourth_ship_hints.dark_matter_spawn_system
	for i in range(1, planet_num + 1):
		#p_i = planet_info
		var p_i = {}
		p_i["conquered"] = system_data[id].conquered
		p_i["ring"] = i
		p_i["type"] = Helper.rand_int(3, 10)
		if p_num == 0:#Starting solar system has smaller planets
			p_i["size"] = int((2000 + rand_range(0, 7000) * (i + 1) / 2.0))
			p_i.pressure = pow(10, rand_range(-3, log(p_i.size / 5.0) / log(10) - 3))
		else:
			p_i["size"] = int((2000 + rand_range(0, 12000) * (i + 1) / 2.0) * dark_matter)
			if hypergiant_system:
				if i == 1:
					p_i.size = 6000
					p_i.pressure = rand_range(400, 500)
				elif i == 2:
					p_i.size = 11000
					p_i.pressure = rand_range(150, 200)
				elif i == 3:
					p_i.size = 17000
					p_i.pressure = pow(10, rand_range(-3, log(p_i.size) / log(10) - 2))
				elif i == 4:
					p_i.size = 25000
					p_i.pressure = pow(10, rand_range(-3, log(p_i.size) / log(10) - 2))
				elif i == 5:
					p_i.size = 32000
					p_i.type = 8
					p_i.pressure = pow(10, rand_range(-3, log(p_i.size) / log(10) - 2))
				p_i.conquered = true
			elif dark_matter_system:
				p_i.size = 1000
				p_i.conquered = true
				p_i.pressure = pow(10, rand_range(-3, log(p_i.size) / log(10) - 2))
		p_i["angle"] = rand_range(0, 2 * PI)
		#p_i["distance"] = pow(1.3,i+(max(1.0,log(combined_star_size*(0.75+0.25/max(1.0,log(combined_star_size)))))/log(1.3)))
		p_i["distance"] = pow(1.3,i + j) * rand_range(240, 270)
		if hypergiant_system:
			p_i.distance *= 60
		#1 solar radius = 2.63 px = 0.0046 AU
		#569 px = 1 AU = 215.6 solar radii
		max_distance = p_i["distance"]
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		p_i["discovered"] = false
		var p_id = planet_data.size()
		p_i["id"] = p_id + p_num
		p_i["l_id"] = p_id
		system_data[id]["planets"].append({"local":p_id, "global":p_id + p_num})
		var dist_in_km = p_i.distance / 569.0 * e(1.5, 8)#                             V bond albedo
		var temp = max_star_temp * pow(star_size_in_km / (2 * dist_in_km), 0.5) * pow(1 - 0.1, 0.25)
		p_i.temperature = temp# in K
		var gas_giant:bool = p_i.size >= max(18000, 40000 * pow(combined_star_mass, 0.3))
		if gas_giant:
			p_i.crust_start_depth = 0
			p_i.mantle_start_depth = 0
			if p_i.temperature > 100:
				p_i.type = 12
			else:
				p_i.type = 11
			p_i.name = "%s %s" % [tr("GAS_GIANT"), p_id]
		else:
			p_i["name"] = tr("PLANET") + " " + String(p_id)
			p_i.crust_start_depth = Helper.rand_int(50, 450)
			p_i.mantle_start_depth = round(rand_range(0.005, 0.02) * p_i.size * 1000)
		p_i.atmosphere = make_atmosphere_composition(temp, p_i.pressure)
		p_i.crust = make_planet_composition(temp, "crust", p_i.size, gas_giant)
		p_i.mantle = make_planet_composition(temp, "mantle", p_i.size, gas_giant)
		p_i.core = make_planet_composition(temp, "core", p_i.size, gas_giant)
		p_i.core_start_depth = round(rand_range(0.4, 0.46) * p_i.size * 1000)
		p_i.surface = add_surface_materials(temp, p_i.crust)
		p_i.liq_seed = randi()
		p_i.liq_period = rand_range(60, 300)
		var lakes = Data.elements.duplicate(true)
		if id + s_num == 0:#Only water in solar system
			if randf() < 0.2:
				p_i.lake_1 = "H2O"
			if randf() < 0.2:
				p_i.lake_2 = "H2O"
		elif p_i.temperature <= 1000:
			p_i.lake_1 = get_random_element(lakes)
			p_i.lake_2 = get_random_element(lakes)
			if hypergiant_system and i == 1:
				p_i.lake_1 = "Xe"
				p_i.lake_2 = "Xe"
		p_i.HX_data = []
		var power:float = system_data[id].diff * pow(p_i.size / 1500.0, 0.5)
		var num:int = 0
		if not p_i.conquered:
			while num < 12:
				num += 1
				var lv = ceil(pow(rand_range(0.5, 1), 1.2) * log(power) / log(1.2))
				if p_num == 0 and lv > 3:
					lv = 3
				if num == 12:
					lv = ceil(0.9 * log(power) / log(1.2))
				var HP = round(rand_range(0.8, 1.2) * 25 * pow(1.16, lv - 1))
				var def = Helper.rand_int(3, 10)
				var atk = round(rand_range(0.8, 1.2) * (18 - def) * pow(1.15, lv - 1))
				var acc = round(rand_range(0.8, 1.2) * 10 * pow(1.15, lv - 1))
				var eva = round(rand_range(0.8, 1.2) * 10 * pow(1.15, lv - 1))
				var _money = round(rand_range(0.4, 2) * pow(1.3, lv - 1) * 50000)
				var XP = round(pow(1.25, lv - 1) * 5)
				p_i.HX_data.append({"type":Helper.rand_int(1, 4), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva, "money":_money, "XP":XP})
				power -= floor(pow(1.15, lv))
				if power <= 1:
					break
			p_i.HX_data.shuffle()
		if system_data[id].has("second_ship") and i == system_data[id].second_ship:
			if p_i.type in [11, 12]:
				planet_data[0].second_ship = true
			else:
				p_i.second_ship = true
		var wid:int = Helper.get_wid(p_i.size)
		var view_zoom = 3.0 / wid
		p_i.view = {"pos":Vector2(340, 80) / view_zoom, "zoom":view_zoom}
		planet_data.append(p_i)
	if c_s_g != 0:
		var view_zoom = 400 / max_distance
		system_data[id]["view"] = {"pos":Vector2(640, 360) / view_zoom, "zoom":view_zoom}
	system_data[id]["discovered"] = true
	p_num += planet_num
	Helper.save_obj("Systems", c_s_g, planet_data)
	Helper.save_obj("Galaxies", c_g_g, system_data)

func get_random_element(elements:Dictionary):
	var S:float = 0.0
	var els:Array = []
	var numbers:Array = []
	for el in elements:
		els.append(el)
		numbers.append(elements[el] + S)
		S += elements[el]
	var rand = randf() * S
	var chosen_el:String = els[0]
	for k in range(1, len(numbers)):
		if rand < numbers[k - 1]:
			break
		chosen_el = els[k]
	return chosen_el

func get_coldest_star_temp(s_id):
	var res = system_data[s_id].stars[0].temperature
	for i in range(1, len(system_data[s_id].stars)):
		if system_data[s_id].stars[i].temperature < res:
			res = system_data[s_id].stars[i].temperature
	return res

func get_biggest_star_size(s_id):
	var res = system_data[s_id].stars[0].size
	for i in range(1, len(system_data[s_id].stars)):
		if system_data[s_id].stars[i].size > res:
			res = system_data[s_id].stars[i].size
	return res

func get_brightest_star_luminosity(s_id):
	var res = system_data[s_id].stars[0].luminosity
	for i in range(1, len(system_data[s_id].stars)):
		if system_data[s_id].stars[i].luminosity > res:
			res = system_data[s_id].stars[i].luminosity
	return res

func make_lake(tile, state:String, lake:String, which_lake):
	tile.lake = {"state":state, "element":lake, "type":which_lake}#type: 1 or 2

func generate_tiles(id:int):
	tile_data.clear()
	var p_i:Dictionary = planet_data[id]
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = Helper.get_wid(p_i.size)
	tile_data.resize(pow(wid, 2))
	if p_i.id == 2:
		var view_zoom = 3.0 / wid
		p_i.view = {"pos":Vector2(340, 80) / view_zoom, "zoom":view_zoom}
		p_i.type = 5
	#Aurora spawn
	var diff:int = 0
	var tile_from:int = -1
	var tile_to:int = -1
	var rand:float = randf()
	var thiccness:int = ceil(Helper.rand_int(1, 3) * wid / 50.0)
	var pulsation:float = rand_range(0.4, 1)
	var amplitude:float = 0.85
	var max_star_temp = get_max_star_prop(c_s, "temperature")
	var ship_signal:bool = second_ship_hints.spawned_at_p == -1 and len(ship_data) == 1 and c_g_g == 0 and c_s_g != 0
	var hypergiant_system:bool = c_s_g == fourth_ship_hints.hypergiant_system_spawn_system
	var dark_matter_system:bool = c_s_g == fourth_ship_hints.dark_matter_spawn_system
	var op_aurora:bool = hypergiant_system and id == 3
	var cross_aurora:bool = hypergiant_system and id == 4
	var num_auroras:int = 2
	if op_aurora:
		fourth_ship_hints.op_grill_planet = c_p_g
		thiccness = 1
		num_auroras = 5
	if cross_aurora:
		fourth_ship_hints.boss_planet = c_p_g
		pulsation = 0.5
		thiccness = 1
		amplitude = 1.3
	if dark_matter_system:
		num_auroras = 0
	for i in num_auroras:
		if c_p_g != 2 and (randf() < 0.35 * pow(p_i.pressure, 0.15) or ship_signal or op_aurora or cross_aurora):
			#au_int: aurora_intensity
			var au_int = clever_round((rand_range(80000, 85000) if cross_aurora else rand_range(80000, 160000)) * galaxy_data[c_g].B_strength * max_star_temp, 3)
			if op_aurora:
				au_int = clever_round(rand_range(25, 26))
			if tile_from == -1:
				if cross_aurora:
					tile_from = wid / 2
					tile_to = wid / 2
				else:
					tile_from = Helper.rand_int(0, 1 if ship_signal else wid)
					tile_to = Helper.rand_int(0, wid)
			if rand < 0.5:#Vertical
				for j in wid:
					var x_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness * amplitude * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(x_pos - int(thiccness / 2) + diff, x_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						show.auroras = true
						tile_data[k + j * wid] = {}
						tile_data[k + j * wid].aurora = {"au_int":au_int}
			else:#Horizontal
				for j in wid:
					var y_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness * amplitude * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(y_pos - int(thiccness / 2) + diff, y_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						show.auroras = true
						tile_data[j + k * wid] = {}
						tile_data[j + k * wid].aurora = {"au_int":au_int}
			diff = Helper.rand_int(thiccness + 1, wid / 3) * sign(rand_range(-1, 1))
			if cross_aurora:
				rand = 1 - rand
				diff = 0
	#We assume that the star system's age is inversely proportional to the coldest star's temperature
	#Age is a factor in crater rarity. Older systems have more craters
	var coldest_star_temp = get_coldest_star_temp(c_s)
	var noise = OpenSimplexNoise.new()
	noise.seed = p_i.liq_seed
	noise.octaves = 1
	noise.period = p_i.liq_period#Higher period = bigger lakes
	var lake_1_phase = "G"
	var lake_2_phase = "G"
	if cross_aurora:
		p_i.erase("lake_1")
		p_i.erase("lake_2")
	if p_i.has("lake_1"):
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1 + ".tscn")
		var phase_1 = phase_1_scene.instance()
		lake_1_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_1)
		phase_1.free()
	if p_i.has("lake_2"):
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2 + ".tscn")
		var phase_2 = phase_2_scene.instance()
		lake_2_phase = Helper.get_state(p_i.temperature, p_i.pressure, phase_2)
		phase_2.free()
	var second_ship_cave_placed:bool = false
	var relic_cave_id:int = -1
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
#			if p_i.temperature <= 1000 and randf() < 0.001:
#				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
#				tile_data[t_id].rock = {}
#				continue
			if c_p_g == 2:
				continue
			var normal_cond:bool = not op_aurora and not cross_aurora and randf() < 0.1 / pow(wid, 0.9)
			var op_aurora_cond:bool = op_aurora and tile_data[t_id] and tile_data[t_id].has("aurora")
			var ship_cond:bool = (ship_signal and not second_ship_cave_placed and tile_data[t_id] and tile_data[t_id].has("aurora"))
			var boss_cave:bool = cross_aurora and t_id == wid * wid / 2
			if normal_cond or op_aurora_cond or ship_cond or boss_cave:#Spawn cave
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				tile_data[t_id].cave = {}
				tile_data[t_id].cave.id = len(cave_data)
				var floor_size:int = Helper.rand_int(25, int(40 * rand_range(1, 1 + wid / 50.0)))
				var num_floors:int = Helper.rand_int(1, wid / 3) + 2
				if ship_cond:
					relic_cave_id = t_id
					second_ship_cave_placed = true
					floor_size = 20
					num_floors = 3
				if boss_cave:
					tile_data[t_id].aurora.au_int *= tile_data[t_id].aurora.au_int
					cave_data.append({"num_floors":5, "floor_size":25, "special_cave":4})
				else:
					cave_data.append({"num_floors":num_floors, "floor_size":floor_size})
				continue
			var crater_size = max(0.25, pow(p_i.pressure, 0.3))
			if not cross_aurora and randf() < 25 / crater_size / pow(coldest_star_temp, 0.8):
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				tile_data[t_id].crater = {}
				tile_data[t_id].crater.variant = Helper.rand_int(1, 3)
				var depth = ceil(pow(10, rand_range(2, 3)) * pow(crater_size, 0.8))
				tile_data[t_id].crater.init_depth = depth
				tile_data[t_id].depth = depth
				tile_data[t_id].crater.metal = "lead"
				for met in met_info:
					if met == "lead":
						continue
					if randf() < 0.3 / pow(met_info[met].rarity, 1.3):
						if c_s_g == 0 and met_info[met].rarity > 6:
							continue
						tile_data[t_id].crater.metal = met
	if relic_cave_id != -1:
		erase_tile(relic_cave_id + wid)
		tile_data[relic_cave_id + wid].ship_locator_depth = Helper.rand_int(4, 7)
	if p_i.has("second_ship"):
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		tile_data[random_tile].ship = true
	elif len(ship_data) == 2 and c_c_g == 0:
		if third_ship_hints.ship_sys_id == c_s and third_ship_hints.ship_spawned_at_p == -1:
			var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
			while random_tile / wid in [0, wid - 1] or random_tile % wid in [0, wid - 1]:
				random_tile = Helper.rand_int(1, len(tile_data)) - 1
			objective = {"type":ObjectiveType.COLLECT_PARTS, "id":-1, "current":0, "goal":5}
			if third_ship_hints.parts[4]:
				objective.current = 1
			erase_tile(random_tile)
			tile_data[random_tile].ship = true
			erase_tile(random_tile - wid)
			tile_data[random_tile - wid].cave = {"id":len(cave_data)}
			cave_data.append({"floor_size":36, "num_floors":9, "special_cave":0})#Normal cave, except... you're tiny
			erase_tile(random_tile + wid)
			tile_data[random_tile + wid].cave = {"id":len(cave_data)}
			cave_data.append({"floor_size":16, "num_floors":30, "special_cave":1})#A super deep cave devoid of everything
			erase_tile(random_tile - 1)
			tile_data[random_tile - 1].cave = {"id":len(cave_data)}
			cave_data.append({"floor_size":77, "num_floors":3, "special_cave":2})#Huge cave
			erase_tile(random_tile + 1)
			tile_data[random_tile + 1].cave = {"id":len(cave_data)}
			cave_data.append({"floor_size":50, "num_floors":5, "special_cave":3})#Big maze cave where minimap is disabled
			third_ship_hints.ship_spawned_at_p = c_p_g
		elif third_ship_hints.ship_part_id == c_s and third_ship_hints.part_spawned_at_p == -1:
			var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
			erase_tile(random_tile)
			tile_data[random_tile].ship_part = true
			third_ship_hints.part_spawned_at_p = c_p_g
			p_i.mantle_start_depth = Helper.rand_int(25000, 27000)
	elif hypergiant_system and id == 2:
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		tile_data[random_tile].artifact = true
	elif dark_matter_system:
		erase_tile(12)
		tile_data[12].diamond_tower = true
	elif c_c_g != 0 and p_i.temperature < 500 and p_i.size < 20000 and p_i.pressure > 50 and not fourth_ship_hints.ruins_spawned:
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		tile_data[random_tile].ruins = 1
		long_popup(tr("UNIQUE_STRUCTURE_NOTICE"), tr("UNIQUE_STRUCTURE"))
	elif hypergiant_system and id == 1:
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		tile_data[random_tile].ruins = 2
	if p_i.id == 6:#Guaranteed wormhole spawn on furthest planet in solar system
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		var dest_id:int = Helper.rand_int(1, SYS_NUM - 1)#				local_destination_system_id		global_dest_s_id
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id}
		p_i.wormhole = true
	elif c_s_g != 0 and not second_ship_cave_placed and randf() < 0.1:#10% chance to spawn a wormhole on a planet outside solar system
		var random_tile:int = Helper.rand_int(1, len(tile_data)) - 1
		erase_tile(random_tile)
		var dest_id:int = Helper.rand_int(1, len(system_data)) - 1
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id + system_data[0].id}
		p_i.wormhole = true#								new: whether the wormhole should generate a new wormhole on another planet
	if lake_1_phase == "G":
		p_i.erase("lake_1")
	if lake_2_phase == "G":
		p_i.erase("lake_2")
	planet_data[id]["discovered"] = true
	if c_p_g == 2:
		tile_data[42] = {}
		tile_data[42].cave = {}
		tile_data[42].cave.id = 0
		tile_data[215] = {}
		tile_data[215].cave = {}
		tile_data[215].cave.id = 1
		if TEST:
			var curr_time = OS.get_system_time_msecs()
			tile_data[107] = {}
			tile_data[107].bldg = {}
			tile_data[107].bldg.name = "PCC"
			tile_data[107].bldg.is_constructing = false
			tile_data[107].bldg.construction_date = curr_time
			tile_data[107].bldg.construction_length = 10
			tile_data[107].bldg.XP = 0
			tile_data[107].bldg.IR_mult = 1
			tile_data[108] = {}
			tile_data[108].bldg = {}
			tile_data[108].bldg.name = "RCC"
			tile_data[108].bldg.is_constructing = false
			tile_data[108].bldg.construction_date = curr_time
			tile_data[108].bldg.construction_length = 10
			tile_data[108].bldg.XP = 0
			tile_data[108].bldg.path_1 = 1
			tile_data[108].bldg.path_1_value = Data.path_1.SPR.value
			tile_data[108].bldg.IR_mult = 1
			tile_data[109] = {}
			tile_data[109].bldg = {}
			tile_data[109].bldg.name = "SPR"
			tile_data[109].bldg.is_constructing = false
			tile_data[109].bldg.construction_date = curr_time
			tile_data[109].bldg.construction_length = 10
			tile_data[109].bldg.XP = 0
			tile_data[109].bldg.path_1 = 1
			tile_data[109].bldg.path_1_value = Data.path_1.SPR.value
			tile_data[109].bldg.IR_mult = 1
			tile_data[110] = {}
			tile_data[110].bldg = {}
			tile_data[110].bldg.name = "AMN"
			tile_data[110].bldg.is_constructing = false
			tile_data[110].bldg.construction_date = curr_time
			tile_data[110].bldg.construction_length = 10
			tile_data[110].bldg.XP = 0
			tile_data[110].bldg.path_1 = 1
			tile_data[110].bldg.path_1_value = Data.path_1.AMN.value
			tile_data[110].bldg.IR_mult = 1
			tile_data[111] = {}
			tile_data[111].bldg = {}
			tile_data[111].bldg.name = "SY"
			tile_data[111].bldg.is_constructing = false
			tile_data[111].bldg.construction_date = curr_time
			tile_data[111].bldg.construction_length = 10
			tile_data[111].bldg.XP = 0
			tile_data[111].bldg.path_1 = 1
			tile_data[111].bldg.path_1_value = Data.path_1.SY.value
			tile_data[111].bldg.IR_mult = 1
		else:
			tile_data[112] = {}
			tile_data[112].ship = true
	Helper.save_obj("Planets", c_p_g, tile_data)
	Helper.save_obj("Systems", c_s_g, planet_data)
	tile_data.clear()
	if ship_signal:
		objective = {"type":ObjectiveType.SIGNAL, "id":10, "current":0, "goal":1}
		long_popup(tr("SHIP_SIGNAL"), tr("SIGNAL_DETECTED"))
		second_ship_hints.spawned_at_p = c_p_g

func erase_tile(random_tile:int):
	if not tile_data[random_tile] or not tile_data[random_tile].has("aurora"):
		tile_data[random_tile] = {}
	else:
		tile_data[random_tile] = {"aurora":tile_data[random_tile].aurora}

func make_atmosphere_composition(temp:float, pressure:float):
	var atm = {}
	var S:float = 0
	for el in Data.elements:
		var phase_scene = load("res://Scenes/PhaseDiagrams/" + el + ".tscn")
		var phase = phase_scene.instance()
		var rand = Data.elements[el] / (1 - randf())
		if Helper.get_state(temp, pressure, phase) == "L":
			rand *= 0.2
		elif Helper.get_state(temp, pressure, phase) == "SC":
			rand *= 0.5
		elif Helper.get_state(temp, pressure, phase) == "S":
			rand *= 0.05
		atm[el] = rand
		S += rand
		phase.free()
	for el in atm:
		atm[el] /= S
	return atm

func make_planet_composition(temp:float, depth:String, size:float, gas_giant:bool = false):
	randomize()
	var common_elements = {}
	var uncommon_elements = {}
	var big_planet_factor:float = lerp(1, 5, inverse_lerp(12500, 45000, size))
	if not gas_giant or depth == "core":
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
									"H":0.1 * big_planet_factor,
									"C":0.1 * big_planet_factor,
									"He":0.03 * big_planet_factor,
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
									"H":0.1 * big_planet_factor,
									"C":0.1 * big_planet_factor,
									"Ti":0.05,
									"He":0.03 * big_planet_factor,
									"P":0.02,
									"Pu":0.01
								}
		else:
			common_elements["Fe"] = rand_range(0.5, 0.95)
			common_elements["Ni"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.9)
			common_elements["O"] = (1 - Helper.get_sum_of_dict(common_elements)) * rand_range(0, 0.19)
			common_elements["Si"] = common_elements["O"] * rand_range(3.9, 4)
			uncommon_elements = {	"S":0.5,
									"Cr":0.3,
									"Ta":0.2,
									"W":0.2,
									"Os":0.1,
									"Ir":0.1,
									"Ti":0.1,
									"Co":0.1,
									"Mn":0.1
								}
	else:
		if depth == "crust":
			return {}
		if depth == "mantle":
			common_elements["H"] = randf()
			common_elements["N"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["He"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			common_elements["C"] = (1 - Helper.get_sum_of_dict(common_elements)) * randf()
			uncommon_elements = {	"Al":0.5,
									"Fe":0.35,
									"Ca":0.3,
									"Na":0.25,
									"U":0.25,
									"S":0.2,
									"Mg":0.2,
									"K":0.2,
									"Np":0.1,
									"Ti":0.05,
									"H":0.02,
									"P":0.02,
									"Pu":0.01
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
	#temp in K
	var surface_mat_info = {	"coal":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":rand_range(50, 150)},
								"glass":{"chance":0.1, "amount":1},
								"sand":{"chance":0.8, "amount":50},
								#"clay":{"chance":rand_range(0.05, 0.3), "amount":rand_range(30, 80)},
								"soil":{"chance":rand_range(0.1, 0.8), "amount":rand_range(30, 100)},
								"cellulose":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":rand_range(3, 15)}
	}
	if abs(temp - 273) > 80:
		surface_mat_info.erase("cellulose")
		surface_mat_info.erase("coal")
	surface_mat_info.sand.chance = pow(crust_comp.Si + crust_comp.O, 0.1) if crust_comp.has_all(["Si", "O"]) else 0.0
	var sand_glass_ratio = clamp(atan(0.01 * (temp + 273 - 1500)) * 1.05 / PI + 1/2, 0, 1)
	surface_mat_info.glass.chance = surface_mat_info.sand.chance * sand_glass_ratio
	surface_mat_info.sand.chance *= (1 - sand_glass_ratio)
	if sand_glass_ratio == 0:
		surface_mat_info.erase("glass")
	elif sand_glass_ratio == 1:
		surface_mat_info.erase("sand")
	for mat in surface_mat_info:
		surface_mat_info[mat].chance = clever_round(surface_mat_info[mat].chance, 3)
		surface_mat_info[mat].amount = clever_round(surface_mat_info[mat].amount, 3)
	return surface_mat_info

func show_tooltip(txt:String, hide:bool = true):
	if hide:
		hide_tooltip()
		hide_adv_tooltip()
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
		if RTL.append_bbcode(st) != OK:
			return
		if i != len(imgs) and imgs[i]:
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
	if RTL:
		RTL.rect_min_size.y = RTL.get_content_height()
		RTL.rect_size.y = RTL.get_content_height()

var change_view_btn

func put_change_view_btn (info_str, icon_str):
	change_view_btn = TextureButton.new()
	var change_view_icon = load(icon_str)
	change_view_btn.texture_normal = change_view_icon
	$UI.add_child(change_view_btn)
	change_view_btn.shortcut = ShortCut.new()
	change_view_btn.shortcut.shortcut = InputEventAction.new()
	Helper.set_back_btn(change_view_btn, false)
	change_view_btn.shortcut_in_tooltip = false
	change_view_btn.rect_position = Vector2(-1, 720 - 63)
	change_view_btn.connect("mouse_entered", self, "on_change_view_over", [info_str])
	change_view_btn.connect("mouse_exited", self, "hide_tooltip")
	change_view_btn.connect("pressed", self, "on_change_view_click")

func on_change_view_over (view_str):
	show_tooltip("%s (%s)" % [view_str, change_view_btn.shortcut.shortcut.action])

func on_change_view_click ():
	$click.play()
	match c_v:
		"system":
			if lv >= 18:
				switch_view("galaxy")
		"galaxy":
			if lv >= 35:
				switch_view("cluster")
		"cluster":
			if lv >= 50:
				switch_view("supercluster")
		"supercluster":
			if lv >= 70:
				switch_view("universe")
		"universe":
			if lv >= 100:
				switch_view("dimension")

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
	if get_item_num(item) == 0:
		return 0
	while num > 0:
		for st in items:
			if st != null and st.name == item:
				st.num -= num
				if st.num <= 0:
					num = -st.num
					items[items.find(st)] = null
				else:
					return get_item_num(item)
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
			return false
		if cost == "energy" and energy < costs[cost]:
			return false
		if mats.has(cost) and mats[cost] < costs[cost]:
			return false
		if mets.has(cost) and mets[cost] < costs[cost]:
			return false
		if atoms.has(cost) and atoms[cost] < atoms[cost]:
			return false
		if cost == "stone" and Helper.get_sum_of_dict(stone) < costs.stone:
			return false
	return true

func deduct_resources(costs):
	for cost in costs:
		if cost == "money":
			money -= costs.money
		if cost == "energy":
			energy -= costs.energy
		if cost == "stone":
			var ratio:float = 1 - costs.stone / float(Helper.get_sum_of_dict(stone))
			for el in stone:
				stone[el] *= ratio
		if mats.has(cost):
			mats[cost] = max(0, mats[cost] - costs[cost])
		if mets.has(cost):
			mets[cost] = max(0, mets[cost] - costs[cost])
		if atoms.has(cost):
			atoms[cost] = max(0, atoms[cost] - costs[cost])
		if particles.has(cost):
			particles[cost] = max(0, particles[cost] - costs[cost])
	HUD.refresh()

func add_resources(costs):
	for cost in costs:
		if cost == "money":
			money += costs.money
		elif cost == "energy":
			energy += costs.energy
		elif cost == "SP":
			SP += costs.SP
		elif cost == "stone":
			for comp in costs.stone:
				if stone.has(comp):
					stone[comp] += costs.stone[comp]
				else:
					stone[comp] = costs.stone[comp]
		elif mats.has(cost):
			mats[cost] += costs[cost]
		elif mets.has(cost):
			show.metals = true
			mets[cost] += costs[cost]
		elif atoms.has(cost):
			show.atoms = true
			atoms[cost] += costs[cost]
		elif particles.has(cost):
			show.particles = true
			particles[cost] += costs[cost]
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

func clever_round (num:float, sd:int = 4):#sd: significant digits
	var e = floor(Helper.log10(abs(num)))
	if sd < e + 1:
		return round(num)
	return stepify(num, pow(10, e - sd + 1))

func e(n, e):
	return n * pow(10, e)

var quadrant_top_left:PoolVector2Array = [Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]
var quadrant_top_right:PoolVector2Array = [Vector2(640, 0), Vector2(1280, 0), Vector2(1280, 360), Vector2(640, 360)]
var quadrant_bottom_left:PoolVector2Array = [Vector2(0, 360), Vector2(640, 360), Vector2(640, 720), Vector2(0, 720)]
var quadrant_bottom_right:PoolVector2Array = [Vector2(640, 360), Vector2(1280, 360), Vector2(1280, 720), Vector2(640, 720)]
onready var fps_text = $Tooltips/FPS

func _process(delta):
	if delta != 0:
		fps_text.text = String(round(1 / delta)) + " FPS"
		$UI.move_child($UI/Settings, $UI.get_child_count())

var mouse_pos = Vector2.ZERO
onready var item_cursor = $UI/ItemCursor

func sell_all_minerals():
	if minerals > 0:
		money += minerals * (MUs.MV + 4)
		popup(tr("MINERAL_SOLD") % [round(minerals), round(minerals * (MUs.MV + 4))], 2)
		minerals = 0
		show.shop = true
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
		if ship_locator:
			ship_locator.position = mouse_pos
			var ship_pos:Vector2 = system_data[second_ship_hints.spawned_at].pos
			var local_mouse_pos:Vector2 = view.obj.to_local(mouse_pos)
			ship_locator.get_node("Arrow").rotation = atan2(ship_pos.y - local_mouse_pos.y, ship_pos.x - local_mouse_pos.x)
		if c_v == "STM" and event.get_relative() != Vector2.ZERO:
			STM.move_ship_inst = true

	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		settings.get_node("Fullscreen").pressed = OS.window_fullscreen

	#Press Z to view galaxy the system is in, etc. or go back
	if OS.get_latin_keyboard_variant() == "QWERTY" and Input.is_action_just_released("Z") or OS.get_latin_keyboard_variant() == "AZERTY" and Input.is_action_just_released("W"):
		if not has_node("Loading"):
			on_change_view_click()
	if c_v == "science_tree":
		Helper.set_back_btn(get_node("ScienceBackBtn"))

	if is_instance_valid(change_view_btn):
		Helper.set_back_btn(change_view_btn, false)
	if Input.is_action_just_released("right_click"):
		if bottom_info_action != "":
			if not c_v in ["STM", ""]:
				item_to_use.num = 0
				update_item_cursor()
		elif not tutorial or tutorial.tut_num >= 26:
			if active_panel:
				if c_v != "":
					if not active_panel.polygon:
						active_panel.visible = false
					elif active_panel == upgrade_panel:
						remove_upgrade_panel()
					else:
						fade_out_panel(active_panel)
					active_panel = null
				else:
					toggle_panel(active_panel)
				hide_tooltip()
				hide_adv_tooltip()
	
	#F3 to toggle overlay
	if Input.is_action_just_released("toggle"):
		if overlay:
			overlay._on_CheckBox_pressed()
	
	#J to hide help
	if Input.is_action_just_released("hide_help"):
		help[help_str] = false
		hide_tooltip()
		hide_adv_tooltip()
		$UI/Panel.visible = false
	
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
		var fail:bool = false
		match cmd:
			"setmoney":
				money = float(arr[1])
			"setmin":
				minerals = float(arr[1])
			"setmincap":
				mineral_capacity = float(arr[1])
			"setenergy":
				energy = float(arr[1])
			"setsp":
				SP = float(arr[1])
			"setmat":
				if mats.has(arr[1].to_lower()):
					mats[arr[1].to_lower()] = float(arr[2])
				else:
					popup("No such material", 1.5)
			"setmet":
				if mets.has(arr[1].to_lower()):
					mets[arr[1].to_lower()] = float(arr[2])
				else:
					popup("No such metal", 1.5)
			"setatom":
				if atoms.has(arr[1].capitalize()):
					atoms[arr[1].capitalize()] = float(arr[2])
				else:
					popup("No such atom", 1.5)
			"setpart":
				if particles.has(arr[1].to_lower()):
					particles[arr[1].to_lower()] = float(arr[2])
				else:
					popup("No such particle", 1.5)
			"fc":
				for tile in tile_data:
					if tile and tile.has("bldg") and tile.bldg.is_constructing:
						var diff_time = tile.bldg.construction_date + tile.bldg.construction_length - OS.get_system_time_msecs()
						tile.bldg.construction_length = 1
						if tile.bldg.has("collect_date"):
							tile.bldg.collect_date -= diff_time
						if tile.bldg.has("start_date"):
							tile.bldg.start_date -= diff_time
						if tile.bldg.has("overclock_date"):
							tile.bldg.overclock_date -= diff_time
			"setmulv":
				MUs[arr[1].to_upper()] = int(arr[2])
			"setlv":
				lv = int(arr[1])
			"switchview":
				if c_v == "cave":
					cave.exit_cave()
				else:
					switch_view(arr[1])
			_:
				fail = true
		if not fail:
			popup("Command executed", 1.5)
		else:
			popup("Command \"%s\" does not exist" % [cmd], 2)
		cmd_history.push_front(cmd_node.text)
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
	
	var hotbar_presses = [Input.is_action_just_released("1"), Input.is_action_just_released("2"), Input.is_action_just_released("3"), Input.is_action_just_released("4"), Input.is_action_just_released("5")]
	if not c_v in ["battle", "cave", ""] and not cmd_node.visible and not shop_panel.visible and not craft_panel.visible and not shipyard_panel.visible and not upgrade_panel and not overlay:
		for i in 5:
			if len(hotbar) > i and hotbar_presses[i]:
				var _name = hotbar[i]
				if get_item_num(_name) > 0:
					inventory.on_slot_press(_name)
	if Input.is_action_just_released("S") and Input.is_action_pressed("ctrl"):
		fn_save_game(false)

func fn_save_game(autosave:bool):
	var save_game = File.new()
	save_game.open("user://Save1/main.hx3", File.WRITE)
	if c_v == "cave":
		var c_d = cave_data[cave.id]
		c_d.seeds = cave.seeds.duplicate(true)
		c_d.tiles_mined = cave.tiles_mined.duplicate(true)
		c_d.enemies_rekt = cave.enemies_rekt.duplicate(true)
		c_d.chests_looted = cave.chests_looted.duplicate(true)
		c_d.partially_looted_chests = cave.partially_looted_chests.duplicate(true)
		c_d.hole_exits = cave.hole_exits.duplicate(true)
	save_game.store_var(c_v)
	save_game.store_var(l_v)
	save_game.store_float(money)
	save_game.store_float(minerals)
	save_game.store_float(mineral_capacity)
	save_game.store_var(stone)
	save_game.store_float(energy)
	save_game.store_float(SP)
	save_game.store_float(DRs)
	save_game.store_float(xp)
	save_game.store_float(xp_to_lv)
	save_game.store_64(c_u)
	save_game.store_64(c_sc)
	save_game.store_64(c_c)
	save_game.store_64(c_c_g)
	save_game.store_64(c_g)
	save_game.store_64(c_g_g)
	save_game.store_64(c_s)
	save_game.store_64(c_s_g)
	save_game.store_64(c_p)
	save_game.store_64(c_p_g)
	save_game.store_64(c_t)
	save_game.store_64(lv)
	save_game.store_64(stack_size)
	save_game.store_8(auto_replace)
	save_game.store_var(pickaxe)
	save_game.store_var(science_unlocked)
	save_game.store_var(infinite_research)
	save_game.store_var(mats)
	save_game.store_var(mets)
	save_game.store_var(atoms)
	save_game.store_var(particles)
	save_game.store_var(help)
	save_game.store_var(show)
	save_game.store_var(universe_data)
	save_game.store_var(cave_data)
	save_game.store_var(items)
	save_game.store_var(hotbar)
	save_game.store_var(MUs)
	save_game.store_64(STM_lv)
	save_game.store_64(rover_id)
	save_game.store_var(rover_data)
	save_game.store_var(fighter_data)
	save_game.store_var(probe_data)
	save_game.store_var(ship_data)
	save_game.store_var(second_ship_hints)
	save_game.store_var(third_ship_hints)
	save_game.store_var(fourth_ship_hints)
	save_game.store_var(ships_c_coords)
	save_game.store_var(ships_dest_coords)
	save_game.store_var(ships_depart_pos)
	save_game.store_var(ships_dest_pos)
	save_game.store_var(ships_travel_view)
	save_game.store_var(ships_c_g_coords)
	save_game.store_var(ships_dest_g_coords)
	save_game.store_64(ships_travel_start_date)
	save_game.store_64(ships_travel_length)
	save_game.store_64(p_num)
	save_game.store_64(s_num)
	save_game.store_64(g_num)
	save_game.store_64(c_num)
	save_game.store_var(stats)
	save_game.store_var(objective)
	save_game.close()
	if view.obj:
		view.save_zooms(c_v)
	if c_v in ["planet", "mining"]:
		Helper.save_obj("Planets", c_p_g, tile_data)
		Helper.save_obj("Systems", c_s_g, planet_data)
	elif c_v == "system":
		Helper.save_obj("Galaxies", c_g_g, system_data)
	elif c_v == "galaxy":
		Helper.save_obj("Clusters", c_c_g, galaxy_data)
	elif c_v == "cluster":
		Helper.save_obj("Superclusters", c_sc, cluster_data)
	if not autosave:
		popup(tr("GAME_SAVED"), 1.2)

var ship_locator

func show_ship_locator():
	ship_locator = load("res://Scenes/ShipLocator.tscn").instance()
	add_child(ship_locator)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func hide_ship_locator():
	remove_child(ship_locator)
	ship_locator = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func show_item_cursor(texture):
	item_cursor.get_node("Sprite").texture = texture
	update_item_cursor()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	item_cursor.position = mouse_pos
	item_cursor.visible = true

func update_item_cursor():
	if item_to_use.num <= 0:
		_on_BottomInfo_close_button_pressed()
		item_to_use = {"name":"", "type":"", "num":0}
	else:
		item_cursor.get_node("Num").text = "x " + String(item_to_use.num)
	if HUD:
		HUD.update_hotbar()

func hide_item_cursor():
	item_to_use = {"name":"", "type":"", "num":0}
	item_cursor.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func cancel_building():
	view.obj.finish_construct()
	for id in bldg_blueprints:
		tiles[id]._on_Button_button_out()

func cancel_building_MS():
	$UI/Panel.visible = false
	view.obj.finish_construct()

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

func _on_Title_Button_pressed(URL:String):
	OS.shell_open(URL)

func _on_BottomInfo_close_button_pressed():
	close_button_over = false
	if $UI/BottomInfo.visible:
		hide_tooltip()
		$UI/BottomInfo.visible = false
		if $UI/BottomInfo/CloseButton.on_close != "":
			call($UI/BottomInfo/CloseButton.on_close)
		$UI/BottomInfo/CloseButton.on_close = ""
		bottom_info_action = ""
		if tutorial and tutorial.tut_num == 6:
			tutorial.fade(0.4, false)
			tutorial.get_node("RsrcCheckTimer").start()
		HUD.refresh()

func cancel_place_soil():
	HUD.get_node("Resources/Soil").visible = false

#Used in planet view only
var close_button_over:bool = false

func _on_CloseButton_close_button_over():
	close_button_over = true

func _on_CloseButton_close_button_out():
	close_button_over = false

func fade_out_title(fn:String):
	$Title/Menu/VBoxContainer/NewGame.disconnect("pressed", self, "_on_NewGame_pressed")
	var tween:Tween = Tween.new()
	add_child(tween)
	tween.interpolate_property($Title, "modulate", null, Color(1, 1, 1, 0), 0.5)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)
	tween.queue_free()
	$Title.visible = false
	$UI/Settings.visible = true
	switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	HUD = load("res://Scenes/HUD.tscn").instance()
	if fn == "new_game":
		var tut_or_no_tut = load("res://Scenes/TutOrNoTut.tscn").instance()
		add_child(tut_or_no_tut)
		tut_or_no_tut.connect("new_game", self, "new_game")
	else:
		call(fn)
		add_panels()
		$Autosave.start()
	
func _on_NewGame_pressed():
	if $Title/Menu/VBoxContainer/LoadGame.disabled:
		fade_out_title("new_game")
	else:
		show_YN_panel("new_game", tr("START_NEW_GAME"))

func _on_LoadGame_pressed():
	fade_out_title("load_game")
	$Title/Menu/VBoxContainer/LoadGame.disconnect("pressed", self, "_on_LoadGame_pressed")

func _on_Autosave_timeout():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		if config.get_value("saving", "enable_autosave", true):
			fn_save_game(true)

var YN_str:String = ""
func show_YN_panel(type:String, text:String, args:Array = [], title:String = "Please Confirm..."):
	$UI/PopupBackground.visible = true
	YN_panel.dialog_text = text
	YN_panel.window_title = title
	YN_panel.popup_centered()
	YN_str = type
	if type in ["buy_pickaxe", "destroy_buildings", "op_galaxy", "conquer_all"]:
		YN_panel.connect("confirmed", self, "%s_confirm" % type, args)
	else:
		YN_panel.connect("confirmed", self, "%s_confirm" % type)

func buy_pickaxe_confirm(_costs:Dictionary):
	shop_panel.buy_pickaxe(_costs)
	YN_panel.disconnect("confirmed", self, "buy_pickaxe_confirm")

func destroy_buildings_confirm(arr:Array):
	for tile in arr:
		view.obj.destroy_bldg(tile)
	HUD.refresh()
	YN_panel.disconnect("confirmed", self, "destroy_buildings_confirm")

func send_ships_confirm():
	send_ships_panel.send_ships()
	YN_panel.disconnect("confirmed", self, "send_ships_confirm")

func new_game_confirm():
	fade_out_title("new_game")
	YN_panel.disconnect("confirmed", self, "new_game_confirm")

func op_galaxy_confirm(l_id:int, g_id:int):
	c_g_g = g_id
	c_g = l_id
	switch_view("galaxy")
	YN_panel.disconnect("confirmed", self, "op_galaxy_confirm")

func conquer_all_confirm(energy_cost:float, insta_conquer:bool):
	if energy >= energy_cost:
		energy -= energy_cost
		if insta_conquer:
			for planet in planet_data:
				if not planet.conquered:
					planet.conquered = true
					planet.erase("HX_data")
					stats.planets_conquered += 1
			system_data[c_s].conquered = true
			view.obj.refresh_planets()
			space_HUD.get_node("ConquerAll").visible = false
		else:
			is_conquering_all = true
			switch_view("battle")
		
func show_collect_info(info:Dictionary):
	if info.has("stone") and Helper.get_sum_of_dict(info.stone) == 0:
		info.erase("stone")
	if info.empty():
		return
	add_resources(info)
	$UI/Panel.visible = false
	var info2:Dictionary = info.duplicate(true)
	if info2.has("stone"):
		info2.stone = Helper.get_sum_of_dict(info2.stone)
	Helper.put_rsrc($UI/Panel/VBox, 32, info2)
	$UI/Panel/VBox.rect_size.y = 0
	$UI/Panel.visible = true
	$UI/Panel.modulate.a = 1.0
	Helper.add_label(tr("YOU_COLLECTED"), 0)
	$CollectPanelTimer.start(min(2.5, 0.5 + 0.3 * $UI/Panel/VBox.get_child_count()))
	$CollectPanelAnim.stop()

func _on_CollectPanelTimer_timeout():
	$CollectPanelAnim.play("Fade")

func _on_CollectPanelAnim_animation_finished(anim_name):
	$UI/Panel.visible = false
	$UI/Panel.modulate.a = 1.0

func _on_Ship_pressed():
	switch_view("STM")#Ship travel minigame

func _on_Ship_mouse_entered():
	show_tooltip("%s: %s\n%s" % [tr("TIME_LEFT"), Helper.time_to_str(ships_travel_length - OS.get_system_time_msecs() + ships_travel_start_date), tr("PLAY_SHIP_MINIGAME")])

func _on_mouse_exited():
	hide_tooltip()

func _on_ConfirmationDialog_popup_hide():
	yield(get_tree().create_timer(0), "timeout")
	if YN_panel.is_connected("confirmed", self, "%s_confirm" % YN_str):
		YN_panel.disconnect("confirmed", self, "%s_confirm" % YN_str)

func mine_tile(tile_id:int = -1):
	if not pickaxe.empty():
		if shop_panel.visible:
			toggle_panel(shop_panel)
		if tutorial and tutorial.visible and tutorial.tut_num == 14:
			tutorial.fade(0.4, false)
		if tile_id == -1:
			put_bottom_info(tr("START_MINE"), "about_to_mine")
		else:
			if tutorial and tutorial.tut_num == 15 and objective.empty():
				objective = {"type":ObjectiveType.MINE, "id":-1, "current":0, "goal":2}
			c_t = tile_id
			switch_view("mining")
	else:
		long_popup(tr("NO_PICKAXE"), tr("NO_PICKAXE_TITLE"), [tr("BUY_ONE")], ["open_shop_pickaxe"], tr("LATER"))
