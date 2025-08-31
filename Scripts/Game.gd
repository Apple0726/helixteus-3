extends Node2D

const TEST:bool = false
const DATE:String = ""
const VERSION:String = "v0.30"
const COMPATIBLE_SAVES = []
const ANCIENT_BLDGS = 7

#region Scenes
#var upgrade_panel_scene = preload("res://Scenes/Panels/UpgradePanel.tscn")
#var planet_HUD_scene = preload("res://Scenes/Planet/PlanetHUD.tscn")
#var space_HUD_scene = preload("res://Scenes/SpaceHUD.tscn")
#var planet_details_scene = preload("res://Scenes/Planet/PlanetDetails.tscn")
#var mining_HUD_scene = preload("res://Scenes/Views/Mining.tscn")
#var overlay_scene = preload("res://Scenes/Overlay.tscn")
#var element_overlay_scene = preload("res://Scenes/ElementOverlay.tscn")
#var annotator_scene = preload("res://Scenes/Annotator.tscn")
#var rsrc_scene = preload("res://Scenes/Resource.tscn")
#var cave_scene = preload("res://Scenes/Views/Cave.tscn")
#var STM_scene = preload("res://Scenes/Views/ShipTravelMinigame2.tscn")
#var battle_scene = preload("res://Scenes/Views/Battle.tscn")
#var particles_scene = preload("res://Scenes/LiquidParticles.tscn")
#var time_scene = preload("res://Scenes/TimeLeft.tscn")
#var planet_TS = preload("res://Resources/PlanetTileSet.tres")
#var lake_TS = preload("res://Resources/LakeTileSet.tres")
#var obstacles_TS = preload("res://Resources/ObstaclesTileSet.tres")
#var aurora_scene = preload("res://Scenes/Aurora.tscn")
#var white_rect_scene = preload("res://Scenes/WhiteRect.tscn")
#var mass_build_rect = preload("res://Scenes/MassBuildRect.tscn")
#endregion

#var surface_BG = preload("res://Graphics/Decoratives/Surface.jpg")
#var crust_BG = preload("res://Graphics/Decoratives/Crust.jpg")
#var star_texture = preload("res://Graphics/Effects/spotlight_8_s.png")
#var star_shader = preload("res://Shaders/Star.gdshader")
var planet_textures:Array
var galaxy_textures:Array
var bldg_textures:Array
var ancient_bldg_textures:Array

#region GUI nodes
#var construct_panel:Control
#var megastructures_panel:Control
var gigastructures_panel:Control
var shop_panel:Control
var ships_panel:Control
var upgrade_panel:Control
var craft_panel:Control
var vehicle_panel:Control
var RC_panel:Control
var MU_panel:Control
var SC_panel:Control
var PD_panel:Control
var production_panel:Control
var send_ships_panel:Control
var send_fighters_panel:Control
var send_probes_panel:Control
var terraform_panel:Control
var greenhouse_panel:Control
var shipyard_panel:Panel
var PC_panel:Panel
var AMN_panel:Control
var SPR_panel:Control
var planetkiller_panel:Control
var inventory:Control
var settings_panel:Control
var dimension:Control
var planet_details:Control
var overlay:Control
var element_overlay:Control
var annotator:Control
var mods:Control
var wiki:Panel
var stats_panel:Control
var load_save_panel:Control
var tooltip
var panel_var_name_to_file_name = {
	"upgrade_panel":"Upgrade",
	"craft_panel":"Craft",
	"inventory":"Inventory",
	"load_save_panel":"LoadSave",
	"mods":"Mods",
	"MU_panel":"MineralUpgrades",
	"settings_panel":"Settings",
	"ships_panel":"Ships",
	"send_ships_panel":"SendShipsPanel",
	"shop_panel":"Shop",
	"SC_panel":"SCPanel",
	"RC_panel":"RCPanel",
	"vehicle_panel":"VehiclePanel",
	"stats_panel":"Stats",
	"wiki":"Wiki",
	"PD_panel":"PDPanel",
	"production_panel":"ProductionPanel",
	"greenhouse_panel":"GreenhousePanel",
}
#endregion

const SYSTEM_SCALE_DIV = 100.0
const GALAXY_SCALE_DIV = 750.0
const CLUSTER_SCALE_DIV = 1600.0
const STAR_SCALE_DIV = 300.0/2.63

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
var show_atoms:Array = []#For element overlay

#region Save data
#Current view
var c_v:String = ""
var viewing_dimension:bool = false
var l_v:String

#Player resources
var money:float
var minerals:float
var mineral_capacity:float
var stone:Dictionary
var energy:float
var energy_capacity:float
var capacity_bonus_from_substation:float
var SP:float
#Dimension remnants
var DRs:float
var dim_num:int = 1
var subject_levels:Dictionary
var maths_bonus:Dictionary
var physics_bonus:Dictionary
var chemistry_bonus:Dictionary
var biology_bonus:Dictionary
var engineering_bonus:Dictionary

#id of the universe/supercluster/etc. you're viewing the object in
var c_u:int#c_u: current_universe
var c_c:int#etc.
var c_g:int
var c_g_g:int
var c_s:int
var c_s_g:int
var c_p:int
var c_p_g:int
var c_t:int # current_tile

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
var help:Dictionary = {}

var science_unlocked:Dictionary
var infinite_research:Dictionary
var MUs:Dictionary#Levels of mineral upgrades
#Measures to not overwhelm beginners. false: not visible
var show:Dictionary

#Used to notify the player with an icon when new buildings are unlocked
var new_bldgs:Dictionary = {}

#Used to determine the costs of an ancient building
var ancient_building_counters:Dictionary

#Stores information of all objects discovered
var universe_data:Array
var galaxy_data:Array
var system_data:Array
var planet_data:Array
var tile_data:Array
var caves_generated:int

#Vehicle data
var rover_data:Array
var fighter_data:Array
var probe_data:Array
var ship_data:Array
var ships_travel_data:Dictionary
var satellite_data:Array

#Your inventory
var items:Array

var hotbar:Array

var STM_lv:int#ship travel minigame level
var rover_id:int#Rover id when in cave

var planets_generated:int
var systems_generated:int
var galaxies_generated:int#Total number of galaxies generated
var clusters_generated:int

var stats_univ:Dictionary
var stats_dim:Dictionary
var stats_global:Dictionary

#enum ObjectiveType {BUILD, UPGRADE, MINERAL_UPG, SAVE, MINE, CONQUER, CRUST, CAVE, LEVEL, WORMHOLE, SIGNAL, DAVID, COLLECT_PARTS, MANIPULATORS, EMMA, TERRAFORM}
#var objective:Dictionary# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}

var autocollect:Dictionary
var save_date:int
var bookmarks:Dictionary
var ancient_bldgs_discovered:Dictionary
#endregion

enum ClusterType {GROUP, CLUSTER}

var block_scroll:bool = false
var overlay_CS:float = 0.5
var overlay_data = {	"galaxy":{"overlay":0, "visible":false, "custom_values":[{"left":2, "right":30, "modified":false}, {"left":1, "right":5, "modified":false}, null, null, null, {"left":0.5, "right":15, "modified":false}, {"left":250, "right":100000, "modified":false}, {"left":1, "right":1, "modified":false}, {"left":1, "right":1, "modified":false}, null]},
						"cluster":{"overlay":0, "visible":false, "custom_values":[{"left":200, "right":10000, "modified":false}, null, null, null, {"left":1, "right":100, "modified":false}, {"left":0.2, "right":5, "modified":false}, {"left":0.8, "right":1.2, "modified":false}, null]},
}
var element_overlay_enabled = false
var element_overlay_type = 0
var c_sv:String = ""#current_save
var save_created
var u_i:Dictionary
var view_history:Array = []
var view_history_pos:int = -1

#Stores data of the item that you clicked in your inventory
var item_to_use = {"id":-1, "num":0}

var mining_HUD
var science_tree_view = {"pos":Vector2.ZERO, "zoom":1.0}
var cave
var ruins
var STM
var battle_scene
var battle_GUI
var ship_customize_screen
var is_conquering_all:bool = false

var cave_filters = {
	"money":false,
	"minerals":false,
	"stone":false,
}

# Stores the locations of all boring machines the player has built
# to make autocollecting metals possible while minimizing lag
var boring_machine_data = {
	
}

#region Item info
var mat_info = {	"coal":{"value":15},#One kg of coal = $15
					"glass":{"value":1000},
					"sand":{"value":8},
					#"clay":{"value":12},
					"quillite":{"value":2000000},
					"soil":{"value":14},
					"cellulose":{"value":70},
					"silicon":{"value":80},
}
#Changing length of met_info changes cave rng!
var met_info = {	"lead":{"min_depth":0, "max_depth":500, "rarity":1, "density":11.34, "value":300},
					"copper":{"min_depth":100, "max_depth":750, "rarity":1.7, "density":8.96, "value":660},
					"iron":{"min_depth":200, "max_depth":1000, "rarity":2.8, "density":7.87, "value":1400},
					"aluminium":{"min_depth":300, "max_depth":1500, "rarity":5.0, "density":2.7, "value":3350},
					"silver":{"min_depth":400, "max_depth":1750, "rarity":8.5, "density":10.49, "value":7430},
					"gold":{"min_depth":600, "max_depth":2500, "rarity":15.3, "density":19.3, "value":17950},
					"amethyst":{"min_depth":800, "max_depth":3000, "rarity":25.5, "density":2.66, "value":38630},
					"emerald":{"min_depth":800, "max_depth":3000, "rarity":25.6, "density":2.70, "value":38850},
					"quartz":{"min_depth":800, "max_depth":3000, "rarity":25.7, "density":2.32, "value":39080},
					"topaz":{"min_depth":800, "max_depth":3000, "rarity":25.8, "density":3.50, "value":39310},
					"ruby":{"min_depth":800, "max_depth":3000, "rarity":25.9, "density":4.01, "value":39540},
					"sapphire":{"min_depth":800, "max_depth":3000, "rarity":26.0, "density":3.99, "value":39770},
					"titanium":{"min_depth":1500, "max_depth":4000, "rarity":46.0, "density":4.51, "value":93590},
					"platinum":{"min_depth":2400, "max_depth":6000, "rarity":79.5, "density":21.45, "value":212650},
					"diamond":{"min_depth":5800, "max_depth":9000, "rarity":157.3, "density":4.20, "value":591850},
					"nanocrystal":{"min_depth":9400, "max_depth":14000, "rarity":298.9, "density":1.5, "value":1550270},
					"mythril":{"min_depth":23000, "max_depth":28000, "rarity":1586.4, "density":13.4, "value":18955720},
}

var pickaxes_info = {"stick":{"speed":1.0, "durability":140, "costs":{"money":300}},
					"wooden_pickaxe":{"speed":1.8, "durability":300, "costs":{"money":2700}},
					"stone_pickaxe":{"speed":3.0, "durability":500, "costs":{"money":24000}},
					"lead_pickaxe":{"speed":4.9, "durability":600, "costs":{"money":115000}},
					"copper_pickaxe":{"speed":7.4, "durability":600, "costs":{"money":580000}},
					"iron_pickaxe":{"speed":11.2, "durability":900, "costs":{"money":4350000}},
					"aluminium_pickaxe":{"speed":17.8, "durability":800, "costs":{"money":20500000}},
					"silver_pickaxe":{"speed":28.7, "durability":1000, "costs":{"money":e(8, 7)}},
					"gold_pickaxe":{"speed":190.0, "durability":150, "costs":{"money":e(6.25, 8)}},
					"gemstone_pickaxe":{"speed":85.0, "durability":1200, "costs":{"money":e(9.5, 8)}},
					"titanium_pickaxe":{"speed":175.0, "durability":2500, "costs":{"money":e(8.2, 9)}},
					"platinum_pickaxe":{"speed":330.0, "durability":1300, "costs":{"money":e(1.15, 10)}},
					"diamond_pickaxe":{"speed":775.0, "durability":2000, "costs":{"money":e(5.4, 10)}},
					"nanocrystal_pickaxe":{"speed":4980.0, "durability":770, "costs":{"money":e(3.25, 11)}},
					"mythril_pickaxe":{"speed":19600.0, "durability":4000, "costs":{"money":e(6.4, 12)}},
}

var seeds_produce = {"lead_seeds":{"costs":{"cellulose":0.05}, "produce":{"lead":0.1}},
					"copper_seeds":{"costs":{"cellulose":0.06}, "produce":{"copper":0.1*met_info.lead.value / met_info.copper.value}},
					"iron_seeds":{"costs":{"cellulose":0.07}, "produce":{"iron":0.1*met_info.lead.value / met_info.iron.value}},
					"aluminium_seeds":{"costs":{"cellulose":0.08}, "produce":{"aluminium":0.1*met_info.lead.value / met_info.aluminium.value}},
					"silver_seeds":{"costs":{"cellulose":0.09}, "produce":{"silver":0.1*met_info.lead.value / met_info.silver.value}},
					"gold_seeds":{"costs":{"cellulose":0.1}, "produce":{"gold":0.1*met_info.lead.value / met_info.gold.value}},
}
#endregion

#Density is in g/cm^3
var element = {	"Si":{"density":2.329},
				"O":{"density":1.429}}

#region Achievements
var achievement_data:Dictionary = {}
var achievements:Dictionary = {
	"money":{
		"0":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1000, false, 308), "rsrc":tr("MONEY")}),
		"1":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e6, false, 308), "rsrc":tr("MONEY")}),
		"2":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e9, false, 308), "rsrc":tr("MONEY")}),
		"3":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e12, false, 308), "rsrc":tr("MONEY")}),
		"4":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e15, false, 308), "rsrc":tr("MONEY")}),
		"5":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e18, false, 308), "rsrc":tr("MONEY")}),
		"6":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e21, false, 308), "rsrc":tr("MONEY")}),
		"7":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e24, false, 308), "rsrc":tr("MONEY")}),
		"8":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e27, false, 308), "rsrc":tr("MONEY")}),
		"9":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1e30, false, 308), "rsrc":tr("MONEY")}),
	},
	"conquest":{
		"0":tr("CONQUER_OBJECTIVE").format({"num":2, "object":tr("PLANETS")}),
		"1":tr("CONQUER_OBJECTIVE").format({"num":10, "object":tr("PLANETS")}),
		"2":tr("CONQUER_OBJECTIVE").format({"num":100, "object":tr("PLANETS")}),
		"3":tr("CONQUER_OBJECTIVE").format({"num":Helper.format_num(1000, false, 308), "object":tr("PLANETS")}),
		"4":tr("CONQUER_OBJECTIVE").format({"num":Helper.format_num(10000, false, 308), "object":tr("PLANETS")}),
		"5":tr("CONQUER_OBJECTIVE").format({"num":Helper.format_num(100000, false, 308), "object":tr("PLANETS")}),
		"6":tr("CONQUER_OBJECTIVE").format({"num":Helper.format_num(e(1, 6), false, 308), "object":tr("PLANETS")}),
		"fully_conquer_system":tr("FULLY_CONQUER_SYSTEM"),
		"fully_conquer_galaxy":tr("FULLY_CONQUER_GALAXY"),
		"fully_conquer_cluster":tr("FULLY_CONQUER_CLUSTER"),
	},
	"construct":{
		"0":tr("BUILD_OBJECTIVE").format({"num":100, "bldg":tr("BUILDINGS")}),
		"1":tr("BUILD_OBJECTIVE").format({"num":Helper.format_num(10000, false, 308), "bldg":tr("BUILDINGS")}),
		"2":tr("BUILD_OBJECTIVE").format({"num":Helper.format_num(e(1, 6), false, 308), "bldg":tr("BUILDINGS")}),
		"3":tr("BUILD_OBJECTIVE").format({"num":Helper.format_num(e(1, 8), false, 308), "bldg":tr("BUILDINGS")}),
		"4":tr("BUILD_OBJECTIVE").format({"num":Helper.format_num(e(1, 10), false, 308), "bldg":tr("BUILDINGS")}),
		"5":tr("BUILD_OBJECTIVE").format({"num":Helper.format_num(e(1, 12), false, 308), "bldg":tr("BUILDINGS")}),
	},
	"exploration":{
		"B_star":tr("FIND_CLASS_X_STAR") % "B",
		"O_star":tr("FIND_CLASS_X_STAR") % "O",
		"Q_star":tr("FIND_CLASS_X_STAR") % "Q",
		"R_star":tr("FIND_CLASS_X_STAR") % "R",
		"Z_star":tr("FIND_CLASS_X_STAR") % "Z",
		"HG_star":tr("FIND_HYPERGIANT_STAR"),
		"HG_V_star":tr("FIND_HYPERGIANT_X_STAR") % "V",
		"HG_X_star":tr("FIND_HYPERGIANT_X_STAR") % "X",
		"HG_XX_star":tr("FIND_HYPERGIANT_X_STAR") % "XX",
		"HG_L_star":tr("FIND_HYPERGIANT_X_STAR") % "L",
		"20_planet_system":tr("FIND_X_PLANET_SYSTEM") % 20,
		"25_planet_system":tr("FIND_X_PLANET_SYSTEM") % 25,
		"30_planet_system":tr("FIND_X_PLANET_SYSTEM") % 30,
		"35_planet_system":tr("FIND_X_PLANET_SYSTEM") % 35,
		"40_planet_system":tr("FIND_X_PLANET_SYSTEM") % 40,
		"45_planet_system":tr("FIND_X_PLANET_SYSTEM") % 45,
		"50_planet_system":tr("FIND_X_PLANET_SYSTEM") % 50,
		"diamond_crater":tr("FIND_X_CRATER") % tr("DIAMOND"),
		"nanocrystal_crater":tr("FIND_X_CRATER") % tr("NANOCRYSTAL"),
		"mythril_crater":tr("FIND_X_CRATER") % tr("MYTHRIL"),
		"aurora_cave":tr("FIND_AURORA_CAVE"),
		"volcano_cave":tr("FIND_VOLCANO_CAVE"),
		"volcano_aurora_cave":tr("FIND_VOLCANO_AURORA_CAVE"),
		"find_neon_lake":tr("FIND_NEON_LAKE"),
		"find_xenon_lake":tr("FIND_XENON_LAKE"),
		"reach_floor_8":tr("REACH_FLOOR_X_CAVE") % 8,
		"reach_floor_16":tr("REACH_FLOOR_X_CAVE") % 16,
		"reach_floor_24":tr("REACH_FLOOR_X_CAVE") % 24,
		"reach_floor_32":tr("REACH_FLOOR_X_CAVE") % 32,
		"planet_with_nothing":tr("PLANET_WITH_NOTHING"),
		"tier_2_ancient_bldg":tr("FIND_TIER_X_ANCIENT_BLDG") % 2,
		"tier_3_ancient_bldg":tr("FIND_TIER_X_ANCIENT_BLDG") % 3,
		"tier_4_ancient_bldg":tr("FIND_TIER_X_ANCIENT_BLDG") % 4,
		"tier_5_ancient_bldg":tr("FIND_TIER_X_ANCIENT_BLDG") % 5,
		"find_all_ancient_bldgs":tr("FIND_ALL_ANCIENT_BLDGS") % ANCIENT_BLDGS,
	},
	"progression":{
		"build_MS":tr("BUILD_A_MS"),
		"build_GS":tr("BUILD_A_GS"),
		"new_universe":tr("DISCOVER_NEW_UNIV"),
		"new_dimension":tr("RENEW_DIMENSION"),
		"2nd_ship":tr("FIND_2ND_SHIP"),
		"3rd_ship":tr("FIND_3RD_SHIP"),
		"4th_ship":tr("FIND_4TH_SHIP"),
	},
	"random":{
		"clear_out_cave_floor":tr("CLEAR_OUT_CAVE_FLOOR"),
		"destroy_BBB":tr("DESTROY_BBB"),
		"reach_center_of_planet":tr("REACH_CENTER_OF_PLANET"),
		"1000_year_journey":tr("1000_YEAR_JOURNEY"),
		"build_tri_probe_in_slow_univ":tr("BUILD_TRI_PROBE_IN_SLOW_UNIV"),
		"use_stick_to_mine_from_surface_to_core":tr("USE_STICK_TO_MINE_FROM_SURFACE_TO_CORE"),
		"rekt_enemy_30_levels_higher":tr("REKT_ENEMY_30_LEVELS_HIGHER"),
		"op_gh":tr("OP_GH"),
	}
}
#endregion

#Holds informatopion of the tooltip that can be hidden by the player by pressing F7
var help_str:String
var bottom_info_action:String = ""

@onready var music_player = $MusicPlayer
@onready var cmd_node = $Tooltips/Command

var metal_textures:Dictionary = {}
var game_tween:Tween
var view_tween:Tween
var tile_brightness:Array = []
var tile_avg_mod:Array = []

var current_viewport_dimensions:Vector2
#func update_viewport_dimensions():
	#if settings_panel.get_node("TabContainer/GRAPHICS/DisplayRes").selected != 0:
		#get_viewport().size = current_viewport_dimensions

func load_settings(config:ConfigFile):
	# audio
	Settings.master_volume = config.get_value("audio", "master", 0)
	Settings.music_volume = config.get_value("audio", "music", 0)
	Settings.SFX_volume = config.get_value("audio", "SFX", 0)
	Settings.pitch_affected = config.get_value("audio", "pitch_affected", true)
	Helper.update_volumes(0, Settings.master_volume)
	Helper.update_volumes(1, Settings.music_volume)
	Helper.update_volumes(2, Settings.SFX_volume)
	switch_music(load("res://Audio/Title.ogg"))
	
	# graphics
	Settings.vsync = config.get_value("graphics", "vsync", true)
	Settings.fullscreen = config.get_value("graphics", "fullscreen", false)
	get_window().mode = Window.MODE_FULLSCREEN if Settings.fullscreen else Window.MODE_WINDOWED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if Settings.vsync else DisplayServer.VSYNC_DISABLED)
	Settings.enable_shaders = config.get_value("graphics", "enable_shaders", true)
	Settings.screen_shake = config.get_value("graphics", "screen_shake", true)
	Settings.max_fps = config.get_value("graphics", "max_fps", 60)
	Settings.static_space_LOD = config.get_value("graphics", "static_space_LOD", 12)
	Settings.dynamic_space_LOD = config.get_value("graphics", "dynamic_space_LOD", 8)
	$ShaderExport/SubViewport/Starfield.material.set_shader_parameter("volsteps", Settings.static_space_LOD)
	$ShaderExport/SubViewport/Starfield.material.set_shader_parameter("iterations", 14 + Settings.static_space_LOD / 2)
	$StarfieldUniverse.material.set_shader_parameter("volsteps", Settings.dynamic_space_LOD)
	$StarfieldUniverse.material.set_shader_parameter("iterations", 14 + Settings.dynamic_space_LOD / 2)
	
	# interface
	Settings.notation = config.get_value("interface", "notation", "SI")
	Settings.language = config.get_value("interface", "language", "en")
	TranslationServer.set_locale(Settings.language)
	$Title/Languages.change_language()
	Settings.cave_gen_info = config.get_value("game", "cave_gen_info", false)
	
	# game
	if OS.get_name() == "Web" and not config.get_value("misc", "HTML5", false):
		popup_window("You're playing the browser version of Helixteus 3. While it's convenient, it has\nmany issues not present in the executables:\n\n - High RAM usage\n - Less FPS\n - Importing saves does not work\n - Audio glitches\n - Saving delay (5-10 seconds)", "Browser version", [], [], "I understand", 0)
		config.set_value("misc", "HTML5", true)
		config.save("user://settings.cfg")
	Settings.enable_autosave = config.get_value("game", "enable_autosave", true)
	Settings.autosell = config.get_value("game", "autosell", true)
	Settings.auto_switch_buy_sell = config.get_value("game", "auto_switch_buy_sell", false)
	Settings.autosave_light = config.get_value("game", "autosave_light", true)
	Settings.autosave_interval = 10
	Settings.enemy_AI_difficulty = config.get_value("game", "enemy_AI_difficulty", Settings.ENEMY_AI_DIFFICULTY_NORMAL)
	$Autosave.wait_time = Settings.autosave_interval
	
	# misc
	Settings.op_cursor = config.get_value("misc", "op_cursor", false)
	if Settings.op_cursor:
		Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
	Settings.discord = config.get_value("misc", "discord", true)


func _ready():
	Helper.setup_discord()
	Helper.refresh_discord("In title screen")
	$Star/Sprite2D.texture = load("res://Graphics/Effects/spotlight_%s.png" % [4, 5, 6].pick_random())
	var op_star_colors = [
		Color(0.6169, 0.9533, 0.7249, 1),
		Color(0.7428, 0.9162, 0.7401, 1),
		Color(0.6895, 0.5263, 0.965, 1),
		Color(0.5061, 0.9214, 0.8825, 1),
		Color(0.8829, 0.5799, 0.9917, 1),
	]
	var star_color = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0))
	print(star_color)
	$Star/Sprite2D.material["shader_parameter/color"] = star_color
	var star_tween = create_tween()
	star_tween.tween_property($Star/Sprite2D.material, "shader_parameter/alpha", 1.0, 2.0)
	#current_viewport_dimensions = get_viewport().size
	#get_viewport().connect("size_changed",Callable(self,"update_viewport_dimensions"))
	for key in Mods.added_mats:
		mat_info[key] = Mods.added_mats[key]
	for key in Mods.added_mets:
		met_info[key] = Mods.added_mets[key]
	for key in Mods.added_picks:
		pickaxes_info[key] = Mods.added_picks[key]
	
#	place_BG_stars()
#	place_BG_sc_stars()
	for i in range(3, 13):
		planet_textures.append(load("res://Graphics/Planets/%s.png" % i))
		if i <= 10:
			var tile_texture = load("res://Graphics/Tiles/%s.jpg" % i)
			var tile_img = tile_texture.get_image()
			var brightness:float = 0.0
			var rgb = {"r":0, "g":0, "b":0}
			for x in tile_img.get_width():
				for y in tile_img.get_height():
					var color:Color = tile_img.get_pixel(x, y)
					brightness += color.r + color.g + color.b
					rgb.r += color.r
					rgb.g += color.g
					rgb.b += color.b
			var num_pixels = tile_img.get_width() * tile_img.get_height()
			rgb.r /= num_pixels
			rgb.g /= num_pixels
			rgb.b /= num_pixels
			tile_brightness.append(brightness)
			tile_avg_mod.append(Color(rgb.r, rgb.g, rgb.b, 1.0))
	for i in range(0, 7):
		galaxy_textures.append(load("res://Graphics/Galaxies/%s.png" % i))
	for bldg in Building.names:
		var dir_str = "res://Graphics/Buildings/%s.png" % bldg
		if ResourceLoader.exists(dir_str):
			bldg_textures.append(load(dir_str))
	for bldg in AncientBuilding.names:
		var dir_str = "res://Graphics/Buildings/Ancient/%s.png" % bldg
		if ResourceLoader.exists(dir_str):
			ancient_bldg_textures.append(load(dir_str))
	for metal in met_info.keys():
		metal_textures[metal] = load("res://Graphics/Metals/%s.png" % metal)
	if not TranslationServer.get_locale() in ["de", "zh", "es", "ja", "nl", "hu"]:
		TranslationServer.set_locale("en")
	AudioServer.set_bus_volume_db(0, -40)
	view = preload("res://Scenes/Views/View.tscn").instantiate()
	add_child(view)
	#noob
	#AudioServer.set_bus_mute(1,true)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == ERR_FILE_NOT_FOUND:
		config.save("user://settings.cfg")
		err = config.load("user://settings.cfg")
	if err == OK:
		load_settings(config)
	else:
		printerr("Warning! Settings unable to be loaded")
	var OS_name = OS.get_name()
	if Settings.op_cursor:
		OS_name = OS_name.replace("ws", "ge")
	$UI/Version.text = "Alpha %s (%s): %s" % [VERSION, OS_name, DATE]
	refresh_continue_button()
	animate_title_buttons()
	for mod in Mods.mod_list:
		var main = Mods.mod_list[mod]
		main.phase_2()
	send_probes_panel = preload("res://Scenes/Panels/SendProbesPanel.tscn").instantiate()
	send_probes_panel.visible = false
	$Panels/Control.add_child(send_probes_panel)

func refresh_continue_button():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	var saved_c_sv = ""
	if err == OK:
		saved_c_sv = config.get_value("game", "saved_c_sv", "")
	if saved_c_sv != "" and FileAccess.open("user://%s/save_info.hx3" % [saved_c_sv], FileAccess.READ) != null:
		$Title/Menu/VBoxContainer/Continue.visible = true
		$Title/Menu/VBoxContainer/Continue.text = tr("CONTINUE_X") % saved_c_sv
	return saved_c_sv

func animate_title_buttons():
	var tween = create_tween()
	tween.set_parallel(true)
	$TitleBackground.modulate.a = 0.0
	$Title.modulate.a = 0.0
	$Title/Menu/AnimationPlayer.play("Fade")
	tween.tween_property($TitleBackground, "modulate", Color.WHITE, 1)
	tween.tween_property($Title, "modulate", Color.WHITE, 1).set_delay(0.2)
	tween.tween_property($Star/Sprite2D.material, "shader_parameter/brightness_offset", 0.8, 1.0).set_delay(0.5)
	tween.tween_property($Star, "modulate", Color.WHITE, 1.2)
	
func switch_music(src, time_speed:float = 1.0, pitch_scale:float = 1.0):
	#Music fading
	if music_player.playing:
		$MusicPlayer/AnimationPlayer.play_backwards("FadeMusic")
		await $MusicPlayer/AnimationPlayer.animation_finished
	if not src:
		return
	music_player.stream = src
	if Settings.pitch_affected:
		if c_v in ["cave", "battle"] and subject_levels.dimensional_power >= 4:
			music_player.pitch_scale = pitch_scale * log(time_speed - 1.0 + exp(1.0))
		else:
			music_player.pitch_scale = pitch_scale * time_speed
	else:
		music_player.pitch_scale = pitch_scale
	$MusicPlayer/AnimationPlayer.play("FadeMusic")
	await get_tree().process_frame
	music_player.play()

func load_univ():
	view_history.clear()
	view_history_pos = -1
	var save_game = FileAccess.open("user://%s/Univ%s/main.hx3" % [c_sv, c_u], FileAccess.READ)
	if save_game == null:
		save_game = FileAccess.open("user://%s/Univ%s/main~.hx3" % [c_sv, c_u], FileAccess.READ)
	var save_game_dict:Dictionary = save_game.get_var()
	save_game.close()
	for key in save_game_dict:
		if key in self:
			self[key] = save_game_dict[key]
	for key in mat_info:
		if not mats.has(key):
			mats[key] = 0
	stats_univ = save_game_dict.get("stats_univ", Data.default_stats.duplicate(true))
	for stat in Data.default_stats:
		var val = Data.default_stats[stat]
		if not stats_univ.has(stat):
			if val is Dictionary:
				stats_univ[stat] = val.duplicate(true)
			else:
				stats_univ[stat] = val
	u_i = universe_data[c_u]
	if science_unlocked.has("CI"):
		stack_size = 32
	if science_unlocked.has("CI2"):
		stack_size = 64
	if science_unlocked.has("CI3"):
		stack_size = 128
	if not autocollect.is_empty():
		var time_elapsed = max(Time.get_unix_time_from_system() - save_date, 0)
		if autocollect.has("ship_XP"):
			var xp_mult = Helper.get_spaceport_xp_mult(autocollect.ship_XP)
			for i in len(ship_data):
				Helper.add_ship_XP(i, xp_mult * pow(1.15, u_i.lv) * time_elapsed / (4.0 / autocollect.ship_XP) * u_i.time_speed)
		var min_mult:float = pow(maths_bonus.IRM, infinite_research.MEE)
		var energy_mult:float = pow(maths_bonus.IRM, infinite_research.EPE)
		var SP_mult:float = pow(maths_bonus.IRM, infinite_research.RLE)
		Helper.add_minerals(((autocollect.rsrc.minerals + autocollect.MS.minerals + autocollect.GS.minerals) * min_mult) * time_elapsed * u_i.time_speed)
		energy += ((autocollect.rsrc.energy + autocollect.MS.energy + autocollect.GS.energy) * energy_mult) * time_elapsed * u_i.time_speed
		SP += ((autocollect.rsrc.SP + autocollect.MS.SP + autocollect.GS.SP) * SP_mult) * time_elapsed * u_i.time_speed
		var plant_time_elapsed = min(time_elapsed, mats.cellulose / abs(autocollect.mats.cellulose)) if not is_zero_approx(autocollect.mats.cellulose) else 0
		if autocollect.mats.has("soil") and not is_zero_approx(autocollect.mats.soil):
			plant_time_elapsed = min(plant_time_elapsed, mats.soil / abs(autocollect.mats.soil))
		for mat in autocollect.mats:
			if mat == "minerals":
				Helper.add_minerals(autocollect.mats[mat] * plant_time_elapsed * u_i.time_speed)
			else:
				mats[mat] += autocollect.mats[mat] * plant_time_elapsed * u_i.time_speed
		for met in autocollect.mets:
			mets[met] += autocollect.mets[met] * plant_time_elapsed * u_i.time_speed
		for atom in autocollect.atoms:
			atoms[atom] += autocollect.atoms[atom] * time_elapsed * u_i.time_speed
	if c_v == "mining" or c_v == "cave":
		c_v = "planet"
	elif c_v in ["science_tree", "STM", "planet_details", "ship_customize_screen"]:
		c_v = l_v
	elif c_v == "battle":
		c_v = "system"
	view.set_process(true)
	tile_data = open_obj("Planets", c_p_g)
	planet_data = open_obj("Systems", c_s_g)
	system_data = open_obj("Galaxies", c_g_g)
	galaxy_data = open_obj("Clusters", c_c)

func load_game():
	# Instantiate necessary panels on game load
	if not is_instance_valid(stats_panel):
		stats_panel = preload("res://Scenes/Panels/Stats.tscn").instantiate()
		stats_panel.panel_var_name = "stats_panel"
		stats_panel.hide()
		$Panels/Control.add_child(stats_panel)
	if not is_instance_valid(shop_panel):
		shop_panel = preload("res://Scenes/Panels/Shop.tscn").instantiate()
		shop_panel.panel_var_name = "shop_panel"
		shop_panel.hide()
		$Panels/Control.add_child(shop_panel)
	var save_info = FileAccess.open("user://%s/save_info.hx3" % [c_sv], FileAccess.READ)
	if save_info == null:
		save_info = FileAccess.open("user://%s/save_info.hx3~" % [c_sv], FileAccess.READ)
	var save_info_dict:Dictionary = save_info.get_var()
	save_info.close()
	save_created = save_info_dict.save_created
	help = save_info_dict.help
	c_u = save_info_dict.c_u
	universe_data = save_info_dict.universe_data
	DRs = save_info_dict.get("DRs", 0)
	dim_num = save_info_dict.get("dim_num", 1)
	subject_levels = save_info_dict.get("subject_levels", {"maths":0,
					"physics":0,
					"chemistry":0,
					"biology":0,
					"philosophy":0,
					"engineering":0,
					"dimensional_power":0,
		})
	if subject_levels.dimensional_power >= 7:
		Data.path_2[Building.CENTRAL_BUSINESS_DISTRICT].desc = "x %s " + tr("TIME_SPEED")
	else:
		Data.path_2[Building.CENTRAL_BUSINESS_DISTRICT].desc = tr("CBD_PATH_2")
	stats_global = save_info_dict.get("stats_global", Data.default_stats.duplicate(true))
	stats_dim = save_info_dict.get("stats_dim", Data.default_stats.duplicate(true))
	for stat in Data.default_stats:
		var val = Data.default_stats[stat]
		if not stats_global.has(stat):
			if val is Dictionary:
				stats_global[stat] = val.duplicate(true)
			else:
				stats_global[stat] = val
		if not stats_dim.has(stat):
			if val is Dictionary:
				stats_dim[stat] = val.duplicate(true)
			else:
				stats_dim[stat] = val
	maths_bonus = save_info_dict.maths_bonus
	Data.MUs.MV.pw = maths_bonus.MUCGF_MV
	Data.MUs.MSMB.pw = maths_bonus.MUCGF_MSMB
	physics_bonus = save_info_dict.physics_bonus
	chemistry_bonus = save_info_dict.chemistry_bonus
	biology_bonus = save_info_dict.biology_bonus
	engineering_bonus = save_info_dict.engineering_bonus
	achievement_data = save_info_dict.get("achievement_data", {})
	if achievement_data.is_empty() or achievement_data.money is Array:#Save migration
		for ach in achievements:
			achievement_data[ach] = {}
	if save_info_dict.version != VERSION and not save_info_dict.version in COMPATIBLE_SAVES:
		c_u = -1
		var beginner_friendly = len(universe_data) == 1 and dim_num == 1
		var lv_sum:int = 0
		for univ in universe_data:
			lv_sum += pow(univ.lv, 2.2)
		DRs += floor(lv_sum / 10000.0) + 1
		for i in len(universe_data):
			Helper.remove_recursive("user://%s/Univ%s" % [c_sv, i])
		universe_data.clear()
		dim_num += 1
		switch_music(null)
		viewing_dimension = true
		help.erase("hide_dimension_stuff")
		add_dimension()
		dimension.refresh_univs(true)
		dimension.get_node("Subjects/Grid/Maths").visible = not beginner_friendly
		dimension.get_node("Subjects/Grid/Physics").visible = not beginner_friendly
		dimension.get_node("Subjects/Grid/Biology").visible = not beginner_friendly
		dimension.get_node("Subjects/Grid/Dimensional_Power").visible = not beginner_friendly
		stats_dim = Data.default_stats.duplicate(true)
		fn_save_game()
	elif c_u == -1:
		viewing_dimension = true
		add_dimension()
		dimension.refresh_univs(len(universe_data) == 0)
	else:
		load_univ()
		switch_view(c_v, {"first_time":true})
		if not $UI.is_ancestor_of(HUD):
			$UI.add_child(HUD)
	set_c_sv(c_sv)

func set_c_sv(_c_sv):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("game", "saved_c_sv", _c_sv)
		config.save("user://settings.cfg")

func set_default_dim_bonuses():
	maths_bonus = {
		"BUCGF":1.3,
		"MUCGF_MV":1.9,
		"MUCGF_MSMB":1.6,
		"IRM":1.2,
		"SLUGF_XP":1.3,
		"SLUGF_Stats":1.15,
		"COSHEF":1.5,
		"MMBSVR":10,
		"ULUGF":1.63,
	}
	physics_bonus = Data.univ_prop_weights.duplicate()
	physics_bonus.MVOUP = 0.5
	physics_bonus.BI = 0.3
	physics_bonus.aurora_spawn_probability = 0.35
	physics_bonus.aurora_width_multiplier = 1.0
	physics_bonus.perpendicular_auroras = 0.0
	chemistry_bonus = {}
	biology_bonus = {
		"PGSM":1.0,
		"PYM":1.0,
		"H2O":1.0,
		"CH4":1.0,
		"CO2":1.0,
		"NH3":1.0,
		"H":0,
		"He":1.0,
		"O":1.0,
		"Ne":1.0,
		"Xe":0,
	}
	engineering_bonus = {
		"BCM":1.0,
		"PS":1.0,
		"RSM":1.0,
		"max_ancient_building_tier":0,
		"ancient_building_a_value":0.0,
		"ancient_building_b_value":1.5,
	}
	subject_levels = {
		"maths":0,
		"physics":0,
		"chemistry":0,
		"biology":0,
		"philosophy":0,
		"engineering":0,
		"dimensional_power":0,
	}

func new_game(univ:int = 0, new_save:bool = false, DR_advantage = false):
	view_history.clear()
	view_history_pos = -1
	stats_univ = Data.default_stats.duplicate(true)
	var save_dir = DirAccess.open("user://")
	if new_save:
		stats_global = stats_univ.duplicate(true)
		stats_dim = stats_univ.duplicate(true)
		var sv_id:int = 1
		c_sv = "Save1"
		while DirAccess.open("user://%s" % c_sv):
			sv_id += 1
			c_sv = "Save%s" % sv_id
		save_dir.make_dir(str(c_sv))
		save_created = Time.get_unix_time_from_system()
		DRs = 0
		dim_num = 1
		if not DR_advantage:
			help = Data.default_help.duplicate()
			set_default_dim_bonuses()
		for ach in achievements:
			achievement_data[ach] = {}
		if subject_levels.dimensional_power <= 4:
			universe_data = [{"id":0, "lv":1, "generated":true, "xp":0, "xp_to_lv":10, "shapes":[], "name":tr("UNIVERSE"), "cluster_num":1000, "view":{"pos":Vector2(640, 360), "zoom":1.0, "sc_mult":0.1}}]
			universe_data[0].speed_of_light = 1.0#e(3.0, 8)#m/s
			universe_data[0].planck = 1.0#e(6.626, -34)#J.s
			universe_data[0].boltzmann = 1.0#e(1.381, -23)#J/K
			universe_data[0].gravitational = 1.0#e(6.674, -11)#m^3/kg/s^2
			universe_data[0].charge = 1.0#e(1.602, -19)#C
			universe_data[0].dark_energy = 1.0
			universe_data[0].age = 1.0
			universe_data[0].difficulty = 1.0
			universe_data[0].time_speed = 1.0
			universe_data[0].antimatter = 0.0
		else:
			universe_data[0].generated = true
	else:
		universe_data[univ].generated = true
	u_i = universe_data[univ]
	save_dir.make_dir("user://%s/Univ%s" % [c_sv, univ])
	save_dir.make_dir("user://%s/Univ%s/Caves" % [c_sv, univ])
	save_dir.make_dir("user://%s/Univ%s/Planets" % [c_sv, univ])
	save_dir.make_dir("user://%s/Univ%s/Systems" % [c_sv, univ])
	save_dir.make_dir("user://%s/Univ%s/Galaxies" % [c_sv, univ])
	save_dir.make_dir("user://%s/Univ%s/Clusters" % [c_sv, univ])
	l_v = ""

	#Player resources
	money = 800
	minerals = 0
	mineral_capacity = 200
	stone = {}
	energy = 200
	energy_capacity = 7500
	capacity_bonus_from_substation = 0
	SP = 0
	science_unlocked = {}
	if subject_levels.dimensional_power >= 1:
		science_unlocked.ASM = true
		science_unlocked.ASM2 = true
	cave_filters = {
		"money":false,
		"minerals":false,
		"stone":false,
	}
	boring_machine_data = {}
	new_bldgs = {}
	ancient_building_counters = {
		AncientBuilding.SPACEPORT:{},
		AncientBuilding.MINERAL_REPLICATOR:{},
		AncientBuilding.OBSERVATORY:{},
		AncientBuilding.MINING_OUTPOST:{},
		AncientBuilding.SUBSTATION:{},
		AncientBuilding.CELLULOSE_SYNTHESIZER:{},
		AncientBuilding.NUCLEAR_FUSION_REACTOR:{},
	}

	#id of the universe/supercluster/etc. you're viewing the object in
	c_u = univ#c_u: current_universe
	c_c = 0#c_c: current_cluster
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

	for sc in Data.infinite_research_sciences:
		infinite_research[sc] = 0
	mats = {	"coal":0,
				"glass":0,
				"sand":0,
				"soil":0,
				"cellulose":0,
				"silicon":0,
				"quillite":0,
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
				"titanium":0,
				"platinum":0,
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
				"Al":0,
				"Si":0,
				"Ti":0,
				"Fe":0,
				"Xe":0,
				"Ta":0,
				"W":0,
				"Os":0,
				"Pt":0,
				"Pu":0,
	}

	particles = {	
		"subatomic_particles":0,
	}

	#Display help when players see/do things for the first time. true: show help

	MUs = {	"MV":1,
			"MSMB":1,
			"IS":1,
			"STMB":1,
			"SHSR":1,
			"CHR":1,
	}#Levels of mineral upgrades

	#Measures to not overwhelm beginners. false: not visible
	show = {}
	new_bldgs = {Building.MINERAL_EXTRACTOR:true}
	if subject_levels.dimensional_power >= 1:
		for mat in mat_info.keys():
			show[mat] = true
		for met in met_info.keys():
			show[met] = true
	#Stores information of all objects discovered
	u_i.cluster_data = [{"id":0, "visible":true, "type":0, "shapes":[], "class":ClusterType.GROUP, "name":tr("LOCAL_GROUP"), "pos":Vector2.ZERO, "diff":u_i.difficulty, "FM":u_i.dark_energy, "parent":0, "galaxy_num":55, "galaxies":[], "view":{"pos":Vector2(640, 360), "zoom":1 / 4.0}, "rich_elements":{}}]
	galaxy_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "name":tr("MILKY_WAY"), "pos":Vector2.ZERO, "rotation":0, "diff":u_i.difficulty, "B_strength":1e-9 * u_i.charge * u_i.dark_energy, "dark_matter":1.0, "parent":0, "system_num":400, "view":{"pos":Vector2(7500, 7500) * 0.5 + Vector2(640, 360), "zoom":0.5}}]
	var s_b:float = pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2)
	system_data = [{"id":0, "l_id":0, "name":tr("SOLAR_SYSTEM"), "pos":Vector2(-7500, -7500), "diff":u_i.difficulty, "parent":0, "planet_num":7, "planets":[], "view":{"pos":Vector2(640, 150), "zoom":2}, "stars":[{"type":StarType.MAIN_SEQUENCE, "class":"G2", "size":1, "temperature":5500, "mass":u_i.planck, "luminosity":s_b, "pos":Vector2(0, 0)}]}]
	planet_data = []
	tile_data = []
	caves_generated = 0

	#Vehicle data
	rover_data = []
	fighter_data = []
	probe_data = []
	ship_data = []
	
	ships_travel_data = {	"c_coords":{"c":0, "g":0, "s":0, "p":2}, # Local coords of the planet that the ships are on
							"c_g_coords":{"c":0, "g":0, "s":0}, # ship global coordinates (current)
							"dest_coords":{"c":0, "g":0, "s":0, "p":2}, # Local coords of the destination planet
							"dest_g_coords":{"c":0, "g":0, "s":0}, # ship global coordinates (destination)
							"depart_pos":Vector2.ZERO, # Depart position of system/galaxy/etc. depending on view
							"dest_pos":Vector2.ZERO, # Destination position of system/galaxy/etc. depending on view
							"travel_view":"-", # View in which ships travel
							"drives_used":0, # Number of drives used in one journey
							"drive_available_time":0, # Drive will be available to use at this time
							"travel_start_date":-1,
							"travel_length":NAN,
	}
	satellite_data = []

	items = [{"id":Item.OVERCLOCK1, "num":5}, null, null, null, null, null, null, null, null, null]

	hotbar = []

	STM_lv = 0#ship travel minigame level
	rover_id = -1#Rover id when in cave

	planets_generated = 0
	systems_generated = 0
	galaxies_generated = 0#Total number of galaxies generated
	clusters_generated = 0

	#objective = {}# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}
	autocollect = {
		"mats":{"cellulose":0},
		"mets":{},
		"atoms":{},
		"particles":{},
		"MS":{"minerals":0, "energy":0, "SP":0},
		"GS":{"minerals":0, "energy":0, "SP":0},
		"rsrc":{"minerals":0, "energy":0, "SP":0},
		"rsrc_list":{}}
	save_date = Time.get_unix_time_from_system()
	generate_planets(0)
	if univ == 0:
		#Home planet information
		planet_data[2]["name"] = tr("HOME_PLANET")
		planet_data[2].type = 5
		planet_data[2]["conquered"] = true
		planet_data[2]["size"] = round(randf_range(12000, 12100))
		planet_data[2].view = {"pos":Vector2(340, 80), "zoom":3.0 / Helper.get_wid(planet_data[2].size)}
		stats_univ.biggest_planet = planet_data[2].size
		planet_data[2]["angle"] = PI / 2
		planet_data[2]["tiles"] = []
		planet_data[2].pressure = 1
		planet_data[2].lake = {"element":"H2O"}
		planet_data[2].liq_seed = 7
		planet_data[2].liq_period = 0.4
		planet_data[2].crust_start_depth = randi_range(25, 30)
		planet_data[2].mantle_start_depth = randi_range(25000, 30000)
		planet_data[2].core_start_depth = randi_range(4000000, 4200000)
		planet_data[2].surface.coal.chance = 0.5
		planet_data[2].surface.coal.amount = 100
		planet_data[2].surface.soil.chance = 0.6
		planet_data[2].surface.soil.amount = 60
		planet_data[2].surface.cellulose.chance = 0.4
		planet_data[2].surface.cellulose.amount = 50
		planet_data[2].bookmarked = true
	bookmarks = {"planet":{"2":{
				"type":planet_data[2].type,
				"name":planet_data[2].name,
				"c_p":2,
				"c_p_g":2,
				"c_s":0,
				"c_s_g":0,
				"c_g":0,
				"c_g_g":0,
				"c_c":0}}, "system":{}, "galaxy":{}, "cluster":{}}
	ancient_bldgs_discovered = {
		AncientBuilding.SPACEPORT:{},
		AncientBuilding.MINERAL_REPLICATOR:{},
		AncientBuilding.OBSERVATORY:{},
		AncientBuilding.MINING_OUTPOST:{},
		AncientBuilding.SUBSTATION:{},
		AncientBuilding.CELLULOSE_SYNTHESIZER:{},
		AncientBuilding.NUCLEAR_FUSION_REACTOR:{},
	}
	Helper.save_obj("Systems", 0, planet_data)
	generate_tiles(2)
	
	c_v = "planet"
	Helper.save_obj("Galaxies", 0, system_data)
	Helper.save_obj("Clusters", 0, galaxy_data)
	fn_save_game()
	if not is_ancestor_of(HUD):
		$UI.add_child(HUD)
	HUD.refresh()
	update_starfield = true
	add_planet(true)
	$Autosave.start()
	var init_time = Time.get_unix_time_from_system()
	add_panels()
	view.set_process(true)
	set_c_sv(c_sv)

func add_panels():
	pass
	#upgrade_panel = upgrade_panel_scene.instantiate()
	#inventory = preload("res://Scenes/Panels/Inventory.tscn").instantiate()
	#shop_panel = preload("res://Scenes/Panels/ShopPanel.tscn").instantiate()
	#ships_panel = preload("res://Scenes/Panels/ShipPanel.tscn").instantiate()
	#gigastructures_panel = preload("res://Scenes/Panels/GigastructuresPanel.tscn").instantiate()
	#craft_panel = preload("res://Scenes/Panels/CraftPanel.tscn").instantiate()
	#vehicle_panel = preload("res://Scenes/Panels/VehiclePanel.tscn").instantiate()
	#RC_panel = preload("res://Scenes/Panels/RCPanel.tscn").instantiate()
	#MU_panel = preload("res://Scenes/Panels/MUPanel.tscn").instantiate()
	#SC_panel = preload("res://Scenes/Panels/SCPanel.tscn").instantiate()
	#production_panel = preload("res://Scenes/Panels/ProductionPanel.tscn").instantiate()
	#send_ships_panel = preload("res://Scenes/Panels/SendShipsPanel.tscn").instantiate()
	#send_fighters_panel = preload("res://Scenes/Panels/SendFightersPanel.tscn").instantiate()
	#terraform_panel = preload("res://Scenes/Panels/TerraformPanel.tscn").instantiate()
	#greenhouse_panel = preload("res://Scenes/Panels/GreenhousePanel.tscn").instantiate()
	#shipyard_panel = preload("res://Scenes/Panels/ShipyardPanel.tscn").instantiate()
	#PC_panel = preload("res://Scenes/Panels/PCPanel.tscn").instantiate()
	#AMN_panel = preload("res://Scenes/Panels/ReactionsPanel.tscn").instantiate()
	#AMN_panel.set_script(load("Scripts/AMNPanel.gd"))
	#SPR_panel = preload("res://Scenes/Panels/ReactionsPanel.tscn").instantiate()
	#SPR_panel.set_script(load("Scripts/SPRPanel.gd"))
	#planetkiller_panel = preload("res://Scenes/Panels/PlanetkillerPanel.tscn").instantiate()
	#wiki = preload("res://Scenes/Panels/Wiki.tscn").instantiate()
	#stats_panel = preload("res://Scenes/Panels/StatsPanel.tscn").instantiate()
	#
	#wiki.visible = false
	#$Panels/Control.add_child(wiki)
	#
	#stats_panel.visible = false
	#$Panels/Control.add_child(stats_panel)
	#
	#planetkiller_panel.visible = false
	#$Panels/Control.add_child(planetkiller_panel)
	#
	#AMN_panel.visible = false
	#$Panels/Control.add_child(AMN_panel)
	#
	#SPR_panel.visible = false
	#$Panels/Control.add_child(SPR_panel)
	#
	#send_ships_panel.visible = false
	#$Panels/Control.add_child(send_ships_panel)
	#
	#send_fighters_panel.visible = false
	#$Panels/Control.add_child(send_fighters_panel)
	#
	#terraform_panel.visible = false
	#$Panels/Control.add_child(terraform_panel)
	#
	#greenhouse_panel.visible = false
	#$Panels/Control.add_child(greenhouse_panel)
	#
	#shipyard_panel.visible = false
	#$Panels/Control.add_child(shipyard_panel)
	#
	#PC_panel.visible = false
	#$Panels/Control.add_child(PC_panel)
	#
	#gigastructures_panel.visible = false
	#$Panels/Control.add_child(gigastructures_panel)
#
	#shop_panel.visible = false
	#$Panels/Control.add_child(shop_panel)
#
	#ships_panel.visible = false
	#$Panels/Control.add_child(ships_panel)
#
	#craft_panel.visible = false
	#$Panels/Control.add_child(craft_panel)
#
	#vehicle_panel.visible = false
	#$Panels/Control.add_child(vehicle_panel)
#
	#RC_panel.visible = false
	#$Panels/Control.add_child(RC_panel)
#
	#MU_panel.visible = false
	#$Panels/Control.add_child(MU_panel)
#
	#SC_panel.visible = false
	#$Panels/Control.add_child(SC_panel)
#
	#production_panel.visible = false
	#$Panels/Control.add_child(production_panel)
#
	#inventory.visible = false
	#$Panels/Control.add_child(inventory)
#
	#upgrade_panel.visible = false
	#$Panels/Control.add_child(upgrade_panel)
	#
	#element_overlay = element_overlay_scene.instantiate()
	#element_overlay.visible = false
	#$UI.add_child(element_overlay)

func popup(txt, delay):
	if $Panels.has_node("Popup"):
		$Panels.get_node("Popup").free()
	var popup = preload("res://Scenes/Popup.tscn").instantiate()
	popup.delay = delay
	popup.name = "Popup"
	$Panels.add_child(popup)
	popup.text = txt
	popup.modulate.a = 0
	await get_tree().process_frame
	if is_instance_valid(popup):
		popup.size.x = 0
		var x_pos = 640 - popup.size.x / 2
		popup.position.x = x_pos


func popup_window(txt:String, title:String, other_buttons:Array = [], other_functions:Array = [], ok_txt:String = "OK", align:int = 1):
	hide_tooltip()
	var popup = preload("res://Scenes/PopupWindow.tscn").instantiate()
	$UI.add_child(popup)
	popup.set_align(align)
	popup.set_text(txt)
	popup.set_OK_text(ok_txt)
	for i in range(0, len(other_buttons)):
		popup.add_button(other_buttons[i], other_functions[i])

func open_shop_pickaxe():
	if not is_instance_valid(shop_panel) or not shop_panel.visible:
		fade_in_panel("shop_panel")
	shop_panel._on_btn_pressed(shop_panel.PICKAXE)
	shop_panel.get_node("Tabs/PickaxesButton")._on_Button_pressed()

var bottom_info_shown:bool = false
func put_bottom_info(txt:String, action:String, on_close:String = ""):
	if bottom_info_shown:
		_on_BottomInfo_close_button_pressed(true)
	$UI/BottomInfo.visible = true
	bottom_info_shown = true
	$UI.move_child($UI/BottomInfo, $UI.get_child_count())
	var more_info = $UI/BottomInfo/Text
	more_info.visible = false
	more_info.text = txt
	more_info.modulate.a = 0
	more_info.visible = true
	more_info.size.x = 0#This "trick" lets us resize the label to fit the text
	more_info.position.x = -more_info.get_minimum_size().x / 2.0
	more_info.modulate.a = 1
	bottom_info_action = action
	$UI/BottomInfo/CloseButton.on_close = on_close
	$UI/BottomInfo/MoveAnim.play("MoveLabel")

func fade_in_panel(panel_var_name:String, initialize_properties:Dictionary = {}):
	if is_instance_valid(self[panel_var_name]):
		self[panel_var_name].show()
		$Panels/Control.move_child(self[panel_var_name], $Panels/Control.get_child_count())
		for prop in initialize_properties:
			self[panel_var_name][prop] = initialize_properties[prop]
	else:
		self[panel_var_name] = load("res://Scenes/Panels/%s.tscn" % panel_var_name_to_file_name[panel_var_name]).instantiate()
		self[panel_var_name].panel_var_name = panel_var_name
		for prop in initialize_properties:
			self[panel_var_name][prop] = initialize_properties[prop]
		$Panels/Control.add_child(self[panel_var_name])
	active_panel = self[panel_var_name]
	self[panel_var_name].refresh()
	if $UI.has_node("BuildingShortcuts"):
		$UI.get_node("BuildingShortcuts").close()
	elif c_v == "planet" and not viewing_dimension:
		view.obj.get_node("BuildingShortcutTimer").stop()
	self[panel_var_name].modulate.a = 0.0
	self[panel_var_name].tween = create_tween()
	if panel_var_name != "settings_panel":
		self[panel_var_name].tween.set_parallel(true)
		self[panel_var_name].tween.tween_property($Blur/BlurRect.material, "shader_parameter/amount", 1.0, 0.2)
	self[panel_var_name].tween.tween_property(self[panel_var_name], "modulate", Color(1, 1, 1, 1), 0.07)
	hide_tooltip()

func fade_out_panel(panel:Control):
	#$ShaderExport/SubViewport.get_texture().get_image().save_png("user://universe.png")
	panel.hide()
	block_scroll = false
	hide_tooltip()
	if panel != settings_panel:
		panel.tween = create_tween()
		panel.tween.tween_property($Blur/BlurRect.material, "shader_parameter/amount", 0.0, 0.2)

func toggle_panel(new_panel_var_name):
	# If opening a panel different to currently open panel, close current panel
	if is_instance_valid(active_panel) and active_panel != self[new_panel_var_name]:
		fade_out_panel(active_panel)
	# Check if the panel to open is already open. If it is open, close it
	if not is_instance_valid(self[new_panel_var_name]) or not self[new_panel_var_name].visible:
		fade_in_panel(new_panel_var_name)
	else:
		fade_out_panel(self[new_panel_var_name])
		active_panel = null

func set_to_ship_coords():
	var diff_cluster:bool = c_c != ships_travel_data.dest_coords.c
	c_c = ships_travel_data.dest_coords.c
	c_g_g = ships_travel_data.dest_g_coords.g
	c_g = ships_travel_data.dest_coords.g
	c_s_g = ships_travel_data.dest_g_coords.s
	c_s = ships_travel_data.dest_coords.s
	if diff_cluster:
		galaxy_data = open_obj("Clusters", c_c)

func set_to_fighter_coords(i:int):
	c_c = fighter_data[i].c_c
	c_c = fighter_data[i].c_c
	if fighter_data[i].has("c_g_g"):
		c_g_g = fighter_data[i].c_g_g
		c_g = fighter_data[i].c_g

func set_bookmark_coords(bookmark:Dictionary):
	if bookmark.has("c_p_g"):
		tile_data = open_obj("Planets", bookmark.c_p_g)
		if tile_data.is_empty():
			HUD.planet_grid_btns.get_node(str(bookmark.c_p_g)).queue_free()
			bookmarks.planet.erase(str(bookmark.c_p_g))
			popup(tr("BOOKMARK_P_ERROR"), 2.0)
			return true#Error
		c_p = bookmark.c_p
		c_p_g = bookmark.c_p_g
	if bookmark.has("c_s_g"):
		planet_data = open_obj("Systems", bookmark.c_s_g)
		if planet_data.is_empty():
			HUD.system_grid_btns.get_node(str(bookmark.c_s_g)).queue_free()
			bookmarks.system.erase(str(bookmark.c_s_g))
			popup(tr("BOOKMARK_S_ERROR"), 2.0)
			return true#Error
		c_s = bookmark.c_s
		c_s_g = bookmark.c_s_g
	c_c = bookmark.c_c
	if bookmark.has("c_g"):
		c_g = bookmark.c_g
		c_g_g = bookmark.c_g_g
		system_data = open_obj("Galaxies", c_g_g)
		galaxy_data = open_obj("Clusters", c_c)
	return false#No error

func set_custom_coords(coords:Array, coord_values:Array):#coords: ["c_p_g", "c_p"], coord_values: [1, 2]
	for i in len(coords):
		if coords[i] in self:
			if coords[i] == "c_p_g" and c_p_g != coord_values[i]:
				tile_data = open_obj("Planets", coord_values[i])
			elif coords[i] == "c_s_g" and c_s_g != coord_values[i]:
				planet_data = open_obj("Systems", coord_values[i])
			elif coords[i] == "c_g_g" and c_g_g != coord_values[i]:
				system_data = open_obj("Galaxies", coord_values[i])
			elif coords[i] == "c_c" and c_c != coord_values[i]:
				galaxy_data = open_obj("Clusters", coord_values[i])
			self[coords[i]] = coord_values[i]

func delete_galaxy(_c_g:int):
	galaxy_data[_c_g].clear()
	Helper.save_obj("Clusters", c_c, galaxy_data)

#															V function to execute after removing objects but before adding new ones
#func switch_view(new_view:String, first_time:bool = false, fn:String = "", fn_args:Array = [], save_zooms:bool = true, fade_anim:bool = true):
func switch_view(new_view:String, other_params:Dictionary = {}):
	if is_generating:
		return
	_on_BottomInfo_close_button_pressed()
	if $UI.has_node("BuildingShortcuts"):
		$UI.get_node("BuildingShortcuts").queue_free()
	$UI/Panel/AnimationPlayer.play("FadeOut")
	var old_view:String = c_v
	if view_tween and view_tween.is_running():
		return
	if not other_params.has("dont_fade_anim"):
		view_tween = create_tween()
		view_tween.tween_property(view, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
		if $Stars/Starfield.modulate.a > 0.0:
			var fade_out_starfield = false
			if not new_view in ["planet", "system"]:
				fade_out_starfield = true
			else:
				var fn:String = other_params.get("fn", "")
				if fn == "set_to_ship_coords" and c_s_g != ships_travel_data.dest_g_coords.s:
					fade_out_starfield = true
				elif fn == "set_bookmark_coords" and c_s_g != other_params.get("fn_args")[0].get("c_s_g", c_s_g):
					fade_out_starfield = true
				elif fn == "set_custom_coords":
					var c_s_g_index = other_params.get("fn_args")[0].find("c_s_g")
					if c_s_g_index != -1 and c_s_g != other_params.get("fn_args")[1][c_s_g_index]:
						fade_out_starfield = true
			if fade_out_starfield:
				if starfield_tween:
					starfield_tween.kill()
				starfield_tween = create_tween()
				starfield_tween.tween_property($Stars/Starfield, "modulate:a", 0.0, 0.15)
				update_starfield = true
		elif new_view in ["planet", "system"]:
			update_starfield = true
		if $StarfieldUniverse.visible:
			if starfield_universe_tween:
				starfield_universe_tween.kill()
			starfield_universe_tween = create_tween()
			starfield_universe_tween.tween_property($StarfieldUniverse.material, "shader_parameter/brightness", 0.0, 0.15)
		if is_instance_valid(view.obj) and Settings.enable_shaders:
			if c_v == "system":
				var tween2 = create_tween()
				tween2.set_parallel(true)
				for star in get_tree().get_nodes_in_group("stars_system"):
					if is_instance_valid(star) and star.material != null:
						tween2.tween_property(star.material, "shader_parameter/alpha", 0.0, 0.15)
			if c_v == "galaxy":
				var tween2 = create_tween()
				tween2.set_parallel(true)
				for system in view.obj.obj_btns:
					if is_instance_valid(system) and system.material != null:
						tween2.tween_property(system.material, "shader_parameter/alpha", 0.0, 0.15)
			elif c_v == "universe":
				var tween2 = create_tween()
				tween2.set_parallel(true)
				for cluster in view.obj.btns:
					if is_instance_valid(cluster) and cluster.material != null:
						tween2.tween_property(cluster.material, "shader_parameter/alpha", 0.0, 0.15)
		if is_instance_valid(planet_HUD) and new_view != "planet":
			var anim_player:AnimationPlayer = planet_HUD.get_node("ButtonsAnimation")
			anim_player.play_backwards("MoveButtons")
		if is_instance_valid(space_HUD) and not new_view in ["system", "galaxy", "cluster", "universe"]:
			var anim_player:AnimationPlayer = space_HUD.get_node("AnimationPlayer")
			anim_player.play_backwards("MoveButtons")
		if is_instance_valid(HUD) and new_view in ["battle", "cave", "dimension", "STM", "planet_details", ""]:
			var anim_player:AnimationPlayer = HUD.get_node("AnimationPlayer2")
			anim_player.play_backwards("MoveStuff")
		if c_v == "planet" and is_instance_valid(view.obj):
			view.obj.timer.stop()
		await view_tween.finished
	if not other_params.has("first_time"):
		save_views(true)
		fn_save_game()
	if viewing_dimension:
		remove_dimension()
		if not $UI.is_ancestor_of(HUD):
			$UI.add_child(HUD)
		switch_music(Data.ambient_music.pick_random(), u_i.time_speed)
	else:
		if not other_params.has("first_time"):
			match c_v:
				"planet":
					remove_planet(not other_params.has("dont_save_zooms"))
				"planet_details":
					planet_details.queue_free()
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
				"universe":
					remove_universe()
					remove_space_HUD()
				"mining":
					remove_mining()
				"science_tree":
					remove_science_tree()
				"cave":
					$UI.add_child(HUD)
					if is_instance_valid(cave):
						cave.queue_free()
					switch_music(Data.ambient_music.pick_random(), u_i.time_speed)
				"STM":
					$UI.add_child(HUD)
					STM.queue_free()
					switch_music(Data.ambient_music.pick_random(), u_i.time_speed)
				"battle":
					$UI.add_child(HUD)
					Engine.physics_ticks_per_second = 60
					view.move_with_keyboard = true
					battle_scene.queue_free()
					battle_GUI.queue_free()
				"ship_customize_screen":
					$UI.add_child(HUD)
					ship_customize_screen.queue_free()
			if c_v in ["science_tree", "STM", "planet_details"]:
				c_v = l_v
			elif new_view != "":
				if not (c_v == "battle" and new_view == "ship_customize_screen") and c_v != "ship_customize_screen":
					l_v = c_v
				if new_view != "dimension":
					c_v = new_view
				else:
					$Ship.visible = false
					viewing_dimension = true
					add_dimension()
	if other_params.has("fn"):
		var fn:String = other_params.fn
		var fn_args:Array = other_params.get("fn_args", [])
		if fn == "set_bookmark_coords":
			if set_bookmark_coords(fn_args[0]):
				c_v = old_view
		else:
			callv(fn, fn_args)
	if new_view in ["universe", "cluster", "galaxy", "system", "planet"]:
		var new_dict:Dictionary = {"view":new_view, "c_c":c_c, "c_g_g":c_g_g, "c_g":c_g, "c_s_g":c_s_g, "c_s":c_s, "c_p_g":c_p_g, "c_p":c_p}
		if other_params.has("fn"):
			var fn_args:Array = other_params.fn_args if other_params.has("fn_args") else []
			if other_params.fn == "set_custom_coords":
				new_dict = {#fn_args[0]: ["c_c_g", "c_c"], fn_args[1]: [2, 5] (c_c_g = 2, c_c = 5)
					"view":new_view, 
					"c_c":(fn_args[1][fn_args[0].find("c_c")] if fn_args[0].has("c_c") else c_c),
					"c_g_g":(fn_args[1][fn_args[0].find("c_g_g")] if fn_args[0].has("c_g_g") else c_g_g),
					"c_g":(fn_args[1][fn_args[0].find("c_g")] if fn_args[0].has("c_g") else c_g),
					"c_s_g":(fn_args[1][fn_args[0].find("c_s_g")] if fn_args[0].has("c_s_g") else c_s_g),
					"c_s":(fn_args[1][fn_args[0].find("c_s")] if fn_args[0].has("c_s") else c_s),
					"c_p_g":(fn_args[1][fn_args[0].find("c_p_g")] if fn_args[0].has("c_p_g") else c_p_g),
					"c_p":(fn_args[1][fn_args[0].find("c_p")] if fn_args[0].has("c_p") else c_p),
				}
			elif other_params.fn == "set_bookmark_coords":
				new_dict = {#fn_args[0]: {"c_sc":0, "c_c_g":1, "c_c":1} (bookmark dictionary)
					"view":new_view, 
					"c_c":(fn_args[0].c_c if fn_args[0].has("c_c") else c_c),
					"c_g_g":(fn_args[0].c_g_g if fn_args[0].has("c_g_g") else c_g_g),
					"c_g":(fn_args[0].c_g if fn_args[0].has("c_g") else c_g),
					"c_s_g":(fn_args[0].c_s_g if fn_args[0].has("c_s_g") else c_s_g),
					"c_s":(fn_args[0].c_s if fn_args[0].has("c_s") else c_s),
					"c_p_g":(fn_args[0].c_p_g if fn_args[0].has("c_p_g") else c_p_g),
					"c_p":(fn_args[0].c_p if fn_args[0].has("c_p") else c_p),
				}
			elif other_params.fn in ["set_to_ship_coords", "set_to_fighter_coords"]:
				new_dict = {
					"view":new_view, 
					"c_c":c_c,
					"c_g_g":c_g_g,
					"c_g":c_g,
					"c_s_g":c_s_g,
					"c_s":c_s,
					"c_p_g":c_p_g,
					"c_p":c_p,
				}
		if other_params.has("shift"):
			view_history_pos += other_params.shift
			if view_history_pos < 0:
				view_history_pos = 0
			elif view_history_pos > len(view_history) - 1:
				view_history_pos = len(view_history) - 1
		if len(view_history) == 0 or view_history[view_history_pos].hash() != new_dict.hash():
			if view_history_pos < len(view_history) - 1:
				view_history.resize(view_history_pos + 1)
			view_history.append(new_dict)
			view_history_pos += 1
		$MMTimer.start()
	else:
		$MMTimer.stop()
	if not viewing_dimension:
		match new_view:
			"planet":
				add_planet()
			"planet_details":
				planet_details = load("res://Scenes/Planet/PlanetDetails.tscn").instantiate()
				$UI.add_child(planet_details)
				if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
					$UI.remove_child(HUD)
			"system":
				add_system()
				add_space_HUD()
				space_HUD.get_node("StarPanel").refresh()
			"galaxy":
				add_galaxy()
			"cluster":
				add_cluster()
			"universe":
				add_universe()
				add_space_HUD()
			"mining":
				add_mining()
			"science_tree":
				add_science_tree()
			"cave":
				if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
					$UI.remove_child(HUD)
				cave = load("res://Scenes/Views/Cave.tscn").instantiate()
				cave.rover_data = rover_data[rover_id]
				cave.start_at_floor = other_params.get("start_floor", 1)
				var music_time_speed = u_i.time_speed * tile_data[c_t].get("time_speed_bonus", 1.0)
				var music_pitch = 0.95 if tile_data[c_t].has("aurora") else 1.0
				var music
				if tile_data[c_t].has("ash"):
					music = preload("res://Audio/lava_cave.ogg")
				else:
					music = preload("res://Audio/cave1.ogg")
				switch_music(music, music_time_speed, music_pitch)
				add_child(cave)
			"STM":
				$Ship.visible = false
				view.queue_redraw()
				if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
					$UI.remove_child(HUD)
				STM = load("res://Scenes/Views/ShipTravelMinigame2.tscn").instantiate()
				add_child(STM)
				if randf() < 0.5:
					switch_music(preload("res://Audio/STM.ogg"), u_i.time_speed)
				else:
					switch_music(preload("res://Audio/STM2.ogg"), u_i.time_speed)
			"battle":
				$Ship.visible = false
				if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
					$UI.remove_child(HUD)
				view.scale = Vector2.ONE
				view.position = Vector2.ZERO
				view.move_with_keyboard = false
				if starfield_tween:
					starfield_tween.kill()
				starfield_tween = create_tween()
				starfield_tween.tween_property($Stars/Starfield, "modulate:a", 0.5, 0.5)
				battle_GUI = load("res://Scenes/BattleGUI.tscn").instantiate()
				battle_scene = load("res://Scenes/Views/Battle.tscn").instantiate()
				battle_GUI.battle_scene = battle_scene
				battle_scene.battle_GUI = battle_GUI
				add_child(battle_GUI)
				view.add_child(battle_scene)
			"ship_customize_screen":
				$Ship.hide()
				ship_customize_screen = load("res://Scenes/ShipCustomizeScreen.tscn").instantiate()
				ship_customize_screen.ship_id = other_params.ship_id
				ship_customize_screen.respeccing = other_params.get("respeccing", false)
				add_child(ship_customize_screen)
				ship_customize_screen.get_node("Label").text = other_params.get("label_text", "")
				if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
					$UI.remove_child(HUD)
		if c_v in ["planet", "system", "galaxy", "cluster", "universe", "mining", "science_tree"] and is_instance_valid(HUD) and is_ancestor_of(HUD):
			HUD.refresh()
		if c_v == "universe" and is_instance_valid(HUD) and HUD.dimension_btn.visible:
			HUD.switch_btn.visible = false
	#if not other_params.has("first_time"):
		#fn_save_game()
	if not other_params.has("dont_fade_anim"):
		view_tween = create_tween()
		view_tween.tween_property(view, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	if c_v in ["planet", "system", "galaxy", "cluster", "universe"]:
		var state = ""
		var small_image_text = ""
		if c_v in ["planet", "system"]:
			state = "Managing planets"
		if c_v == "planet":
			small_image_text = "Viewing " + planet_data[c_p].name
		elif c_v == "system":
			small_image_text = "Viewing " + system_data[c_s].name
		elif c_v == "galaxy":
			state = "Observing the stars"
			small_image_text = "Viewing " + galaxy_data[c_g].name
		elif c_v == "cluster":
			state = "Watching galaxies in the distance"
			small_image_text = "Viewing " + u_i.cluster_data[c_c].name
		elif c_v == "universe":
			state = "Navigating the universe"
			small_image_text = "Viewing " + u_i.name
		Helper.refresh_discord("", state, c_v, small_image_text)
	await get_tree().process_frame
	hide_tooltip()

func add_science_tree():
	$ScienceTreeBG.visible = Settings.enable_shaders
	var tween = create_tween()
	tween.tween_property($ScienceTreeBG, "modulate", Color.WHITE, 0.5)
	$ClusterBG.visible = false
	HUD.get_node("Buttons").visible = false
	HUD.get_node("Bottom/Panel").visible = false
	HUD.get_node("Bottom/Hotbar").visible = false
	HUD.get_node("Top/Lv").modulate.a = 0.5
	HUD.get_node("Top/Name").modulate.a = 0.5
	add_obj("science_tree")
	for rsrc in HUD.get_node("Top/Resources").get_children():
		if rsrc.name != "SP":
			rsrc.modulate.a = 0.5

var pitch_increased_mining = false

func add_mining():
	HUD.get_node("Bottom/Hotbar").visible = false
	mining_HUD = load("res://Scenes/Views/Mining.tscn").instantiate()
	add_child(mining_HUD)
	if tile_data[c_t].has("time_speed_bonus") and Settings.pitch_affected:
		music_player.pitch_scale *= tile_data[c_t].time_speed_bonus
		pitch_increased_mining = true

func remove_mining():
	Helper.save_obj("Planets", c_p_g, tile_data)
	if is_instance_valid(HUD):
		HUD.get_node("Bottom/Hotbar").visible = true
	if is_instance_valid(mining_HUD):
		mining_HUD.queue_free()
	if tile_data[c_t].has("time_speed_bonus") and Settings.pitch_affected and pitch_increased_mining:
		music_player.pitch_scale /= tile_data[c_t].time_speed_bonus
		pitch_increased_mining = false

func remove_science_tree():
	$ScienceTreeBG.visible = false
	$ClusterBG.visible = true
	HUD.get_node("Buttons").visible = true
	HUD.get_node("Bottom/Panel").visible = true
	HUD.get_node("Bottom/Hotbar").visible = true
	HUD.get_node("Top/Lv").modulate.a = 1.0
	HUD.get_node("Top/Name").modulate.a = 1.0
	view.remove_obj("science_tree")
	for rsrc in HUD.get_node("Top/Resources").get_children():
		rsrc.modulate.a = 1.0
	$UI.remove_child($UI.get_node("ScienceUI"))

func add_loading():
	var loading_scene = preload("res://Scenes/Loading.tscn")
	var loading = loading_scene.instantiate()
	loading.position = Vector2(640, 360)
	add_child(loading)
	loading.name = "Loading"

func open_obj(type:String, id:int):
	var file_path:String = "user://%s/Univ%s/%s/%s.hx3" % [c_sv, c_u, type, id]
	var save = FileAccess.open(file_path, FileAccess.READ)
	if save == null or save.get_length() == 0:
		save = FileAccess.open(file_path + "~", FileAccess.READ)
		if save == null:
			return []
		if save.get_length() == 0:
			save.close()
			return []
	var arr = save.get_var()
	save.close()
	if not arr.is_empty() and arr[0] is Array:
		var arr_decompressed = []
		var star_properties = ["type", "class", "size", "pos", "temperature", "mass", "luminosity"]
		for compressed_obj in arr:
			var decompressed_obj = {}
			var properties:Array = []
			if type == "Galaxies":
				properties = ["id", "l_id", "name", "pos", "diff", "parent", "planet_num", "planets", "view", "stars", "discovered", "conquered", "closest_planet_distance"]
			elif type == "Clusters":
				properties = ["id", "l_id", "name", "pos", "diff", "parent", "system_num", "view", "type", "discovered", "conquered", "rotation", "B_strength", "dark_matter"]
			for i in len(properties):
				if compressed_obj[i] == null:
					continue
				if properties[i] == "stars":
					var stars = []
					for star_info:Array in compressed_obj[i]:
						var star_dict = {}
						for j in len(star_properties):
							var star_prop:String = star_properties[j]
							star_dict[star_prop] = star_info[j]
						var attr_dict:Dictionary = star_info[-1]
						for attr in attr_dict.keys():
							star_dict[attr] = attr_dict[attr]
						stars.append(star_dict)
						decompressed_obj.stars = stars
				else:
					decompressed_obj[properties[i]] = compressed_obj[i]
			var attr_dict:Dictionary = compressed_obj[-1]
			for attr in attr_dict.keys():
				decompressed_obj[attr] = attr_dict[attr]
			arr_decompressed.append(decompressed_obj)
		return arr_decompressed
	return arr
	
func obj_exists(type:String, id:int):
	var file_path:String = "user://%s/Univ%s/%s/%s.hx3" % [c_sv, c_u, type, id]
	return FileAccess.open(file_path, FileAccess.READ) or FileAccess.open(file_path + "~", FileAccess.READ)

func add_obj(view_str):
	match view_str:
		"planet":
			tile_data = open_obj("Planets", c_p_g)
			view.add_obj("Planet", planet_data[c_p]["view"]["pos"], planet_data[c_p]["view"]["zoom"])
		"system":
			view.add_obj("System", system_data[c_s]["view"]["pos"], system_data[c_s]["view"]["zoom"])
			if ships_travel_data.c_g_coords.s == c_s_g:
				system_data[c_s].explored = true
		"galaxy":
			view.shapes_data = galaxy_data[c_g].get("shapes", [])
			view.add_obj("Galaxy", galaxy_data[c_g].view.pos, galaxy_data[c_g].view.zoom)
			add_space_HUD()
			if ships_travel_data.c_g_coords.g == c_g_g:
				galaxy_data[c_g].explored = true
		"cluster":
			view.shapes_data = u_i.cluster_data[c_c].shapes
			view.add_obj("Cluster", u_i.cluster_data[c_c]["view"]["pos"], u_i.cluster_data[c_c]["view"]["zoom"])
			add_space_HUD()
			if ships_travel_data.c_coords.c == c_c:
				u_i.cluster_data[c_c].explored = true
		"universe":
			view.shapes_data = universe_data[c_u].shapes
			view.add_obj("Universe", universe_data[c_u]["view"]["pos"], universe_data[c_u]["view"]["zoom"], universe_data[c_u]["view"]["sc_mult"])
		"science_tree":
			view.add_obj("ScienceTree", science_tree_view.pos, science_tree_view.zoom)
			var sc_UI = preload("res://Scenes/ScienceUI.tscn").instantiate()
			sc_UI.modulate.a = 0.0
			$UI.add_child(sc_UI)
			sc_UI.sc_tree = view.obj
			view.obj.modulate.a = 0.0
			sc_UI.name = "ScienceUI"
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(sc_UI, "modulate", Color.WHITE, 0.2).set_delay(0.1)
			tween.tween_property(view.obj, "modulate", Color.WHITE, 0.2).set_delay(0.1)
	view.queue_redraw()

func add_space_HUD():
	if not is_instance_valid(space_HUD) or not $UI.is_ancestor_of(space_HUD):
		space_HUD = load("res://Scenes/SpaceHUD.tscn").instantiate()
		$UI.add_child(space_HUD)
		if c_v in ["galaxy", "cluster"]:
			space_HUD.get_node("VBoxContainer/Overlay").visible = true
			add_overlay()
		if c_v in ["galaxy", "cluster", "universe"]:
			space_HUD.get_node("VBoxContainer/Annotate").visible = true
			add_annotator()
		space_HUD.get_node("VBoxContainer/ElementOverlay").visible = c_v == "system" and science_unlocked.has("ATM")
		space_HUD.get_node("VBoxContainer/Stars").visible = c_v == "system"
		space_HUD.get_node("VBoxContainer/Megastructures").visible = c_v == "system" and science_unlocked.has("MAE")
		space_HUD.get_node("VBoxContainer/Gigastructures").visible = c_v in ["galaxy", "cluster"] and science_unlocked.has("GS")
		space_HUD.get_node("ConquerAll").visible = c_v == "system" and (u_i.lv >= 32 or subject_levels.dimensional_power >= 1) and not system_data[c_s].has("conquered") and len(ship_data) > 0 and ships_travel_data.c_g_coords.s == c_s_g
		space_HUD.get_node("SendFighters").visible = c_v == "galaxy" and science_unlocked.has("FG") and not galaxy_data[c_g].has("conquered") or c_v == "cluster" and science_unlocked.has("FG2") and not u_i.cluster_data[c_c].has("conquered")
		space_HUD.get_node("SendProbes").visible = c_v == "universe"

func add_overlay():
	overlay = load("res://Scenes/Overlay.tscn").instantiate()
	overlay.visible = false
	$UI.add_child(overlay)
	overlay.refresh_overlay()

func remove_overlay():
	if is_instance_valid(overlay) and $UI.is_ancestor_of(overlay):
		if $GrayscaleRect.modulate.a > 0:
			$GrayscaleRect/AnimationPlayer.play_backwards("Fade")
		overlay.queue_free()

func add_annotator():
	annotator = load("res://Scenes/Annotator.tscn").instantiate()
	annotator.visible = false
	$UI.add_child(annotator)

func remove_annotator():
	if is_instance_valid(annotator) and $UI.is_ancestor_of(annotator):
		$UI.remove_child(annotator)
		annotator.free()

func remove_space_HUD():
	if is_instance_valid(space_HUD) and $UI.is_ancestor_of(space_HUD):
		$UI.remove_child(space_HUD)
		space_HUD.queue_free()
	remove_overlay()
	remove_annotator()

func add_dimension():
	if not is_instance_valid(PD_panel):
		PD_panel = preload("res://Scenes/Panels/PDPanel.tscn").instantiate()
		PD_panel.hide()
		$Panels/Control.add_child(PD_panel)
	if is_instance_valid(HUD) and $UI.is_ancestor_of(HUD):
		$UI.remove_child(HUD)
	if is_instance_valid(dimension):
		dimension.visible = true
		dimension.refresh_univs()
		$Ship.visible = false
	else:
		dimension = preload("res://Scenes/Views/Dimension.tscn").instantiate()
		dimension.modulate.a = 0.0
		add_child(dimension)
	var tween = create_tween()
	tween.tween_property(dimension, "modulate", Color.WHITE, 0.2)

func set_starfield_color(_material, param:float):
	_material.set_shader_parameter("stepsize", min(param, 0.3))
	_material.set_shader_parameter("distfading", clamp(remap(param, 0.2, 0.3, 0.73, 0.53), 0.53, 0.73))
	if param <= 0.7:
		_material.set_shader_parameter("red_p", 1.0)
		_material.set_shader_parameter("green_p", 2.0)
		_material.set_shader_parameter("blue_p", 4.0)
	if param > 0.7 and param < 2.0: # Green stars (class Q)
		_material.set_shader_parameter("red_p", remap(param, 0.7, 2.0, 1.0, 2.0))
		_material.set_shader_parameter("green_p", remap(param, 0.7, 2.0, 2.0, 3.0))
		_material.set_shader_parameter("blue_p", remap(param, 0.7, 2.0, 4.0, 1.0))
	elif param > 2.0 and param < 8.0: # Pink stars (class R)
		_material.set_shader_parameter("red_p", remap(param, 2.0, 8.0, 2.0, 4.0))
		_material.set_shader_parameter("green_p", remap(param, 2.0, 8.0, 3.0, 1.0))
		_material.set_shader_parameter("blue_p", remap(param, 2.0, 8.0, 1.0, 4.0))
	elif param > 8.0: # Purple stars (class Z)
		_material.set_shader_parameter("red_p", max(remap(param, 8.0, 24.0, 4.0, 2.0), 2.0))
		_material.set_shader_parameter("green_p", 1.0)
		_material.set_shader_parameter("blue_p", 4.0)
	
var starfield_universe_tween

func add_universe():
	var starfield_color_param:float = 0.1 * pow(1.0 / pow(u_i.age, 0.25) / pow(1.0 / u_i.charge / 4.0, physics_bonus.BI), 0.65)
	if Settings.enable_shaders:
		$StarfieldUniverse.material.set_shader_parameter("position", u_i.view.pos)
		set_starfield_color($StarfieldUniverse.material, starfield_color_param)
		$StarfieldUniverse.modulate.a = 1.0
		if starfield_universe_tween:
			starfield_universe_tween.kill()
		starfield_universe_tween = create_tween()
		starfield_universe_tween.set_parallel(true)
		starfield_universe_tween.tween_property($StarfieldUniverse.material, "shader_parameter/brightness", 0.0015, 0.5)
		starfield_universe_tween.tween_property($StarfieldUniverse.material, "shader_parameter/max_alpha", 0.6, 0.5)
	if not universe_data[c_u].has("discovered"):
		reset_collisions()
		generate_clusters(c_u)
		universe_data[c_u].discovered = true
	add_obj("universe")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/DimensionView.png")

func add_cluster():
	if obj_exists("Clusters", c_c):
		galaxy_data = open_obj("Clusters", c_c)
	if not u_i.cluster_data[c_c].has("discovered"):
		is_generating = true
		add_loading()
		reset_collisions()
		if c_c != 0:
			galaxy_data.clear()
		if not u_i.cluster_data[c_c].has("name"):
			if u_i.cluster_data[c_c]["class"] == ClusterType.GROUP:
				u_i.cluster_data[c_c].name = tr("GALAXY_GROUP") + " %s" % c_c
			else:
				u_i.cluster_data[c_c].name = tr("GALAXY_CLUSTER") + " %s" % c_c
		generate_galaxy_part()
		is_generating = false
	else:
		add_obj("cluster")
	$Stars/WhiteStars.visible = true
	$Stars/AnimationPlayer.play("StarFade")
	if Settings.enable_shaders:
		$ClusterBG.fade_in()
		var r:float = (u_i.cluster_data[c_c].pos + u_i.cluster_data[c_c].pos).length()
		var th:float = atan2(u_i.cluster_data[c_c].pos.y, u_i.cluster_data[c_c].pos.x)
		var hue:float = fmod(r + 300, 1000.0) / 1000.0
		var sat:float = pow(fmod(th + PI, 10.0) / 10.0, 0.2)
		$ClusterBG.change_color(Color.from_hsv(hue, sat, 0.6))
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/UniverseView.png")
	if len(ship_data) == 3 and u_i.lv >= 60:
		popup_window(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_4th_ship()

func add_galaxy():
	if obj_exists("Clusters", c_c):
		galaxy_data = open_obj("Clusters", c_c)
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	var generate_normal_galaxy = true
	if c_g_g != 0 and galaxy_data[c_g].get("name") == "Paris" and not galaxy_data[c_g].has("baguette"):
		var file = FileAccess.open("Easter eggs/Paris public transit/data.txt", FileAccess.READ)
		if not file.get_open_error():
			galaxy_data[c_g].baguette = true
			generate_paris_galaxy(file)
			generate_normal_galaxy = false
	if generate_normal_galaxy and not galaxy_data[c_g].has("discovered"):
		if not galaxy_data[c_g].has("name"):
			galaxy_data[c_g].name = "%s %s" % [tr("GALAXY"), c_g]
		await start_system_generation()
	add_obj("galaxy")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/ClusterView.png")
	if len(ship_data) == 2 and u_i.lv >= 40:
		popup_window(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_3rd_ship()

#func start_system_generation():
#	reset_collisions()
#	gc_remaining = floor(pow(galaxy_data[c_g]["system_num"], 0.8) / 250.0)
#	if c_g_g != 0:
#		system_data.clear()
#	generate_systems(c_g)
#	var N:int = galaxy_data[c_g].system_num
#	var galaxy_generator = GalaxyGenerator.new()
#	galaxy_generator.set_system_data(system_data)
#	galaxy_generator.set_galaxy_properties(c_g_g, N, galaxy_data[c_g].diff)
#	var res:Array = []
#	if galaxy_data[c_g].type == 6:
#		res = galaxy_generator.generate_spiral_galaxy()
#	else:
#		res = galaxy_generator.generate_cluster_galaxy()
#	var system_positions = res[0]
#	var system_difficulties = res[1]
#	for i in N:
#		system_data[i].pos = system_positions[i]
#		system_data[i].diff = system_difficulties[i]
#	systems_generated += N
#	Helper.save_obj("Galaxies", c_g_g, system_data)
#	Helper.save_obj("Clusters", c_c, galaxy_data)
#	galaxy_generator.queue_free()
	
func start_system_generation():
	is_generating = true
	add_loading()
	reset_collisions()
	gc_remaining = floor(pow(galaxy_data[c_g].system_num, 0.8) / 250.0)
	if c_g_g != 0:
		system_data.clear()
	await generate_system_part()
	is_generating = false

var update_starfield:bool = false

func show_starfield(params:Dictionary):
	for param in params.keys():
		$ShaderExport/SubViewport/Starfield.material.set_shader_parameter(param, params[param])
	if update_starfield:
		update_starfield_BG()
		update_starfield = false

func update_starfield_BG():
	$ShaderExport.visible = true
	var game_size:Vector2 = DisplayServer.window_get_size()
	if game_size.y < game_size.x / 1.7777777:
		game_size.x = game_size.y * 1.7777777
	elif game_size.x < game_size.y * 1.7777777:
		game_size.y = game_size.x / 1.7777777
	$ShaderExport.size = game_size
	$ShaderExport/SubViewport/Starfield.size = game_size
	await RenderingServer.frame_post_draw
	var BG_image:Image = $ShaderExport/SubViewport.get_texture().get_image()
	$Stars/Starfield.texture = ImageTexture.create_from_image(BG_image)
	$ShaderExport.visible = false

var starfield_tween

func add_system():
	var starfield_color_param = 0.1 * pow(1.0 / pow(u_i.age, 0.25) / pow(1e-9 / galaxy_data[c_g].B_strength, physics_bonus.BI), 0.65)
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	set_starfield_color($ShaderExport/SubViewport/Starfield.material, starfield_color_param)
	show_starfield({"position":system_data[c_s].pos / 10000.0})
	if starfield_tween:
		starfield_tween.kill()
	starfield_tween = create_tween()
	starfield_tween.tween_property($Stars/Starfield, "modulate:a", 0.35, 0.3)
	planet_data = open_obj("Systems", c_s_g)
	if not system_data[c_s].has("discovered") or planet_data.is_empty():
		if c_s_g != 0:
			planet_data.clear()
		generate_planets(c_s)
	show.bookmarks = true
	add_obj("system")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/GalaxyView.png")
	if len(ship_data) == 1 and u_i.lv >= 20:
		popup_window(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_2nd_ship()

func add_planet(new_game:bool = false):
	var starfield_color_param = 0.1 * pow(1.0 / pow(u_i.age, 0.25) / pow(1e-9 / galaxy_data[c_g].B_strength, physics_bonus.BI), 0.65)
	set_starfield_color($ShaderExport/SubViewport/Starfield.material, starfield_color_param)
	show_starfield({"position":system_data[c_s].pos / 10000.0})
	if starfield_tween:
		starfield_tween.kill()
	starfield_tween = create_tween()
	starfield_tween.tween_property($Stars/Starfield, "modulate:a", 0.65, 1.5 if new_game else 0.8)
	planet_data = open_obj("Systems", c_s_g)
	if not planet_data[c_p].has("discovered") or open_obj("Planets", c_p_g).is_empty():
		generate_tiles(c_p)
	planet_HUD = load("res://Scenes/Planet/PlanetHUD.tscn").instantiate()
	$UI.add_child(planet_HUD)
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/SystemView.png")
	if new_game:
		planet_HUD.get_node("VBoxContainer/Construct").material.set_shader_parameter("color", Color(1.0, 0.75, 0.0, 1.0))
		planet_HUD.get_node("VBoxContainer/Construct/AnimationPlayer").play("FlashRepeat")
		await get_tree().create_timer(1.5).timeout
	add_obj("planet")
	if new_game:
		view.scale = Vector2.ONE * 0.1
		var wid = Helper.get_wid(planet_data[c_p].size)
		view.position = Vector2(640-wid*100*0.1, 360-wid*100*0.1)
		view.zoom_tween = create_tween().set_parallel()
		view.zoom_tween.tween_property(view, "scale", Vector2.ONE * 0.5, 5.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC).set_delay(0.5)
		view.zoom_tween.tween_property(view, "position", view.position - Vector2.ONE * 200.0 * 8.0 * view.scale.x * (5.0 - 1.0), 5.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC).set_delay(0.5)
		view.modulate.a = 0.0
		create_tween().tween_property(view, "modulate:a", 1.0, 3.0).set_delay(0.5)
	view.obj.icons_hidden = view.scale.x >= 0.25

func remove_dimension():
	viewing_dimension = false
	dimension.visible = false
	view.dragged = true

func remove_universe():
	$StarfieldUniverse.modulate.a = 0.0
	view.remove_obj("universe")

func remove_cluster():
	if Settings.enable_shaders:
		$ClusterBG.fade_out()
	$Stars/AnimationPlayer.play_backwards("StarFade")
	view.remove_obj("cluster")
	Helper.save_obj("Clusters", c_c, galaxy_data)

func remove_galaxy():
	view.remove_obj("galaxy")
	Helper.save_obj("Clusters", c_c, galaxy_data)
	Helper.save_obj("Galaxies", c_g_g, system_data)

func remove_system():
	view.remove_obj("system")
	Helper.save_obj("Galaxies", c_g_g, system_data)
	Helper.save_obj("Systems", c_s_g, planet_data)

func remove_planet(save_zooms:bool = true):
	if is_instance_valid(active_panel):
		fade_out_panel(active_panel)
	active_panel = null
	view.remove_obj("planet", save_zooms)
	if is_instance_valid(vehicle_panel):
		vehicle_panel.queue_free()
	Helper.save_obj("Systems", c_s_g, planet_data)
	Helper.save_obj("Planets", c_p_g, tile_data)
	_on_BottomInfo_close_button_pressed()
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
	if a[2] < b[2]:
		return true
	return false

var rich_element_list = ["Fe", "Al", "C", "Na", "Ti", "Ta", "W", "Os", "Ne", "Xe"]

func generate_clusters(parent_id:int):
	randomize()
	var total_clust_num = u_i.cluster_num
	max_dist_from_center = pow(total_clust_num, 0.5) * 500
	show.c_bk_button = true
	for _i in range(0, total_clust_num):
		if parent_id == 0 and _i == 0:
			continue
		var c_i = {}
		c_i["type"] = 0
		c_i["class"] = ClusterType.GROUP if randf() < 0.5 else ClusterType.CLUSTER
		c_i["parent"] = parent_id
		c_i["visible"] = TEST
		c_i["galaxies"] = []
		c_i["shapes"] = []
		var c_id = u_i.cluster_data.size()
		if c_i["class"] == ClusterType.GROUP:
			c_i["galaxy_num"] = randi_range(10, 100)
		else:
			c_i["galaxy_num"] = randi_range(500, 5000)
		var pos:Vector2
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center + 160
		if _i == 1:
			dist_from_center = 200
			c_i["class"] = ClusterType.GROUP
			c_i.galaxy_num = randi_range(80, 100)
		c_i.rich_elements = {}
		var _rich_elements = rich_element_list.duplicate()
		_rich_elements.shuffle()
		for j in range(0, int(remap(dist_from_center, 0, 12000, 1, 5))):
			c_i.rich_elements[_rich_elements[j]] = 8 * (1 + randf()) * remap(dist_from_center, 0, 16000, 1, 40)
		pos = Vector2.from_angle(randf_range(0, 2 * PI)) * dist_from_center
		c_i["pos"] = pos
		c_i["id"] = c_id + clusters_generated
		var DE_factor = pos.length() * u_i.dark_energy
		c_i.FM = Helper.clever_round(1 + DE_factor / 1000.0)#Ferromagnetic materials
		c_i.diff = Helper.clever_round((1 + DE_factor) * u_i.difficulty)
		u_i.cluster_data.append(c_i)
	clusters_generated += total_clust_num
	fn_save_game()

var is_generating:bool = false

func generate_galaxy_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_galaxies(c_c)
		$Loading.update_bar(progress, tr("GENERATING_CLUSTER") % [u_i.cluster_data[c_c]["galaxies"].size(), u_i.cluster_data[c_c]["galaxy_num"]])
		await get_tree().create_timer(0.0000000000001).timeout  #Progress Bar doesnt update without this
	galaxies_generated += u_i.cluster_data[c_c].galaxy_num
	Helper.save_obj("Clusters", c_c, galaxy_data)
	add_obj("cluster")
	remove_child($Loading)

func generate_galaxies(id:int):
	randomize()
	var total_gal_num = u_i.cluster_data[id]["galaxy_num"]
	var galaxy_num = total_gal_num - u_i.cluster_data[id]["galaxies"].size()
	var gal_num_to_load = min(500, galaxy_num)
	var progress = 1 - (galaxy_num - gal_num_to_load) / float(total_gal_num)
	var FM:float = u_i.cluster_data[id].FM
	for i in range(0, gal_num_to_load):
		var g_i = {}
		g_i.parent = id
		g_i.type = randi() % 7
		var rand = randf()
		g_i.dark_matter = randf_range(0.85, 1.15) #Influences planet numbers and size
		if g_i.type == 6:
			g_i.system_num = int(5000 + 10000 * pow(randf(), 2))
			g_i.B_strength = Helper.clever_round(1e-9 * randf_range(3, 5) * FM * u_i.charge)#Influences star classes
#			var sat:float = randf_range(0, 0.5)
#			var hue:float = randf_range(sat / 5.0, 1 - sat / 5.0)
#			g_i.modulate = Color().from_hsv(hue, sat, 1.0)
			g_i.dark_matter -= 0.05
		else:
			g_i.system_num = int(pow(randf(), 2) * 8000) + 2000
			g_i.B_strength = Helper.clever_round(1e-9 * randf_range(0.5, 4) * FM * u_i.charge)
			if randf() < 0.6: #Dwarf galaxy
				g_i.system_num /= 10
		g_i.dark_matter = Helper.clever_round(pow(g_i.dark_matter, -log(rand)*u_i.dark_energy/2.5 + 1))
		g_i.rotation = randf_range(0, 2 * PI)
		g_i.view = {"pos":Vector2(640, 360), "zoom": 0.2}
		var pos:Vector2
		var N = obj_shapes.size()
		if N >= total_gal_num / 6:
			obj_shapes.sort_custom(Callable(self,"sort_shapes"))
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.7), N - 1)
			min_dist_from_center = obj_shapes[0][2]
		
		var radius = 200 * pow(g_i.system_num / GALAXY_SCALE_DIV, 0.5)
		var circle
		var colliding = true
		if min_dist_from_center == 0:
			max_dist_from_center = 5000
		else:
			max_dist_from_center = min_dist_from_center * 1.5
		var outer_radius
		while colliding:
			colliding = false
			var dist_from_center = randf_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = Vector2.from_angle(randf_range(0, 2 * PI)) * dist_from_center
			circle = [pos, radius, outer_radius]
			for star_shape in obj_shapes:
				if pos.distance_to(star_shape[0]) < radius + star_shape[1]:
					colliding = true
					max_dist_from_center *= 1.2
					break
		if outer_radius > max_outer_radius:
			max_outer_radius = outer_radius
		obj_shapes.append(circle)
		g_i.pos = pos
		var g_id = galaxy_data.size()
		g_i.id = g_id + galaxies_generated
		g_i.l_id = g_id
		var starting_galaxy = c_c == 0 and galaxy_num == total_gal_num and i == 0
		if starting_galaxy:
			show.g_bk_button = true
			g_i = galaxy_data[0]
			radius = 200 * pow(g_i.system_num / GALAXY_SCALE_DIV, 0.5)
			obj_shapes.append([g_i.pos, radius, g_i.pos.length() + radius])
			u_i.cluster_data[id]["galaxies"].append([0, 0])
		else:
			if id == 0:#if the galaxies are in starting cluster
				g_i.diff = Helper.clever_round((1 + pos.distance_to(galaxy_data[0].pos) / 70) * u_i.cluster_data[id].diff)
			else:
				g_i.diff = Helper.clever_round(u_i.cluster_data[id].diff * randf_range(120, 150) / max(100, pow(pos.length(), 0.5)))
			u_i.cluster_data[id]["galaxies"].append([g_i.id, g_i.l_id])
			galaxy_data.append(g_i)
	if progress == 1:
		u_i.cluster_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			u_i.cluster_data[id]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}
	return progress

func update_loading_bar(curr:float, total:float, txt:String):
	$Loading.update_bar(curr / total, txt % [curr, total])
	#await get_tree().create_timer(0.0000000000001).timeout  #Progress Bar doesnt update without this

func generate_paris_galaxy(file):
	var N:int = galaxy_data[c_g].system_num
	var B = galaxy_data[c_g].B_strength
	var dark_matter = galaxy_data[c_g].dark_matter
	var G = u_i.gravitational
	var star_mass_param = 1.0#pow(u_i.age, 0.25) * pow(1e-9 / B, physics_bonus.BI)
	system_data.clear()
	print(star_mass_param)
	while file.get_position() < file.get_length():
		var line_data = file.get_line()
		var arr = line_data.split("¤")
		
		var s_i:Dictionary = {}
		s_i.parent = c_g
		s_i.planets = []
		s_i.pos = Vector2(float(arr[1]) * 100000, -float(arr[0]) * 100000)
		s_i.name = arr[2]
		
		var star = {}
		#Solar masses
		var mass:float = float(arr[3]) / star_mass_param / 1600000.0
		var star_size = 1
		var star_class = ""
		#Temperature in K
		var temp = 0
		if mass < 0.08:#Y, T, L
			star_size = remap(mass, 0, 0.08, 0.01, 0.1)
			temp = remap(mass, 0, 0.08, 250, 2400)
		elif mass >= 0.08 and mass < 0.45:#M
			star_size = remap(mass, 0.08, 0.45, 0.1, 0.7)
			temp = remap(mass, 0.08, 0.45, 2400, 3700)
		elif mass >= 0.45 and mass < 0.8:#K
			star_size = remap(mass, 0.45, 0.8, 0.7, 0.96)
			temp = remap(mass, 0.45, 0.8, 3700, 5200)
		elif mass >= 0.8 and mass < 1.04:#G
			star_size = remap(mass, 0.8, 1.04, 0.96, 1.15)
			temp = remap(mass, 0.8, 1.04, 5200, 6000)
		elif mass >= 1.04 and mass < 1.4:#F
			star_size = remap(mass, 1.04, 1.4, 1.15, 1.4)
			temp = remap(mass, 1.04, 1.4, 6000, 7500)
		elif mass >= 1.4 and mass < 2.1:#A
			star_size = remap(mass, 1.4, 2.1, 1.4, 1.8)
			temp = remap(mass, 1.4, 2.1, 7500, 10000)
		elif mass >= 2.1 and mass < 9:#B
			star_size = remap(mass, 2.1, 9, 1.8, 6.6)
			temp = remap(mass, 2.1, 9, 10000, 30000)
		elif mass >= 9 and mass < 100:#O
			star_size = remap(mass, 9, 100, 6.6, 22)
			temp = remap(mass, 16, 100, 30000, 70000)
		elif mass >= 100 and mass < 1000:#Q
			star_size = remap(mass, 100, 1000, 22, 60)
			temp = remap(mass, 100, 1000, 70000, 120000)
		elif mass >= 1000 and mass < 10000:#R
			star_size = remap(mass, 1000, 10000, 60, 200)
			temp = remap(mass, 1000, 10000, 120000, 210000)
		elif mass >= 10000:#Z
			var pw = pow(mass, 1/3.0) / pow(10000, 1/3.0)
			star_size = pw * 200
			temp = pw * 210000
		
		var star_type:int = StarType.MAIN_SEQUENCE
		star_class = get_star_class(temp)
		var s_b:float = pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2)
		star.type = star_type
		star["class"] = star_class
		star.size = Helper.clever_round(star_size, 4)
		star.pos = Vector2.ZERO
		star.temperature = Helper.clever_round(temp, 4)
		star.mass = Helper.clever_round(mass * u_i.planck, 4)
		star.luminosity = Helper.clever_round(4 * PI * pow(star_size * e(6.957, 8), 2) * e(5.67, -8) * s_b * pow(temp, 4) / e(3.828, 26), 4)
		var planet_num:int = clamp(round(pow(star.mass, 0.2) * randf_range(3, 9) * pow(dark_matter, 0.25)), 2, 50)
		s_i.planet_num = planet_num
		if galaxy_data[c_g].has("conquered"):
			s_i.conquered = true
		
		var s_id = system_data.size()
		s_i.id = s_id + systems_generated
		s_i.l_id = s_id
		s_i.stars = [star]
		s_i.diff = get_sys_diff(s_i.pos, c_g, s_i)
		system_data.append(s_i)
	galaxy_data[c_g].discovered = true
	Helper.save_obj("Galaxies", c_g_g, system_data)
	Helper.save_obj("Clusters", c_c, galaxy_data)
	
func generate_system_part():
	generate_systems(c_g)
	var N:int = galaxy_data[c_g].system_num
	if galaxy_data[c_g].type == 6:
		var r:float = N / 20.0
		var init_th:float = randf_range(0, PI)
		var th:float = init_th
		update_loading_bar(0, N, tr("GENERATING_GALAXY"))
		#await get_tree().create_timer(5).timeout
		var N_init:int = systems_collision_detection2(c_g, 0, 0, 0, true)#Generate stars at the center
		var N_progress:int = N_init
		while N_progress < (N + N_init) / 2.0:#Arm #1
			var progress:float = inverse_lerp(N_init, (N + N_init) / 2.0, N_progress)
			N_progress = systems_collision_detection2(c_g, N_progress, r, th)
			th += 0.4 - lerp(0.0, 0.33, progress)
			r += (1.0 - lerp(0.0, 0.8, progress)) * 1280 * lerp(1.3, 4.0, inverse_lerp(5000, 20000, N))
			update_loading_bar(N_progress - len(stars_failed), N, tr("GENERATING_GALAXY"))
			await get_tree().create_timer(0.0000000000001).timeout
		th = init_th + PI
		r = N / 20.0
		while N_progress < N:#Arm #2
			var progress:float = inverse_lerp((N + N_init) / 2.0, N, N_progress)
			N_progress = systems_collision_detection2(c_g, N_progress, r, th)
			th += 0.4 - lerp(0.0, 0.33, progress)
			r += (1.0 - lerp(0.0, 0.8, progress)) * 1280 * lerp(1.3, 4.0, inverse_lerp(5000, 20000, N))
			update_loading_bar(N_progress - len(stars_failed), N, tr("GENERATING_GALAXY"))
			await get_tree().create_timer(0.0000000000001).timeout
		for i in len(stars_failed):#Put stars that failed to pass the collision tests above
			var attempts:int = 0
			var s_i = system_data[stars_failed[i]]
			var biggest_star_size = get_max_star_prop(stars_failed[i], "size")
			#Collision detection
			var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
			r = randf_range(0, max_outer_radius)
			th = randf_range(0, 2 * PI)
			var pos:Vector2 = Vector2.from_angle(th) * r
			var coll:bool = true
			while coll:
				coll = false
				for circ in obj_shapes + obj_shapes2:
					if pos.distance_to(circ[0]) < circ[1] + radius:
						coll = true
						r = randf_range(0, max_outer_radius)
						th = randf_range(0, 2 * PI)
						pos = Vector2.from_angle(th) * r
						break
				attempts += 1
				if attempts > 20:
					max_outer_radius *= 1.1
					attempts = 0
			s_i.pos = pos
			s_i.diff = get_sys_diff(pos, c_g, s_i)
			obj_shapes2.append([pos, radius])
			if i % 100 == 0:
				update_loading_bar(N - len(stars_failed) + i, N, tr("GENERATING_GALAXY"))
				await get_tree().create_timer(0.0000000000001).timeout
		if c_g != 0:
			var view_zoom = 500.0 / max_outer_radius
			galaxy_data[c_g].view = {"pos":Vector2(640, 360), "zoom":view_zoom}
	else:
		for i in range(0, N, 500):
			systems_collision_detection(c_g, i)
			update_loading_bar(i, N, tr("GENERATING_GALAXY"))
			await get_tree().create_timer(0.0000000000001).timeout
	systems_generated += galaxy_data[c_g].system_num
	Helper.save_obj("Galaxies", c_g_g, system_data)
	Helper.save_obj("Clusters", c_c, galaxy_data)
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
		var biggest_star_size = get_max_star_prop(i, "size")
		#Collision detection
		var radius = 320 * pow(biggest_star_size / SYSTEM_SCALE_DIV, 0.35)
		var r2 = randf_range(0, circ_size)
		var th2 = randf_range(0, 2 * PI)
		var pos:Vector2 = Vector2.from_angle(th) * r + Vector2.from_angle(th2) * r2
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
				if pos.distance_to(circ[0]) < circ[1] + radius:
					coll = true
					attempts += 1
					r2 = randf_range(0, circ_size)
					th2 = randf_range(0, 2 * PI)
					pos = Vector2.from_angle(th) * r + Vector2.from_angle(th2) * r2
					break
		if cont:
			if pos.length() > max_outer_radius:
				max_outer_radius = pos.length()
			if starting_system:
				obj_shapes2.append([system_data[0].pos, radius])
			else:
				s_i.pos = pos
				s_i.diff = get_sys_diff(pos, id, s_i)
				obj_shapes2.append([pos, radius])
	obj_shapes.append([Vector2.from_angle(th) * r, circ_size])
	obj_shapes2.clear()
	return N_fin

func systems_collision_detection(id:int, N_init:int):
	var total_sys_num = galaxy_data[id].system_num
	var N_fin:int = min(N_init + 500, total_sys_num)
	#obj_shapes: 0: pos, 1: radius, 2: outer_radius
	for i in range(N_init, N_fin):
		var s_i = system_data[i]
		var starting_system = c_g_g == 0 and i == 0
		var N = obj_shapes.size()
		#Whether to move on to a new "ring" for collision detection
		if N >= total_sys_num / 8:
			obj_shapes.sort_custom(Callable(self,"sort_shapes"))
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.9), N - 1)
			min_dist_from_center = obj_shapes[0][2]
			#								V this condition makes sure globular clusters don't spawn near the center
			if gc_remaining > 0 and gc_offset > 1 + int(pow(total_sys_num, 0.1)):
				gc_remaining -= 1
				gc_stars_remaining = int(pow(total_sys_num, 0.5) * randf_range(1, 3))
				gc_center = Vector2.from_angle(randf_range(0, 2 * PI)) * min_dist_from_center
				max_dist_from_center = 100
			gc_offset += 1
		
		var biggest_star_size = get_max_star_prop(i, "size")
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
			var dist_from_center = randf_range(0, max_dist_from_center)
			if gc_stars_remaining == 0:
				dist_from_center = randf_range(min_dist_from_center + radius, max_dist_from_center)
			outer_radius = radius + dist_from_center
			pos = Vector2.from_angle(randf_range(0, 2 * PI)) * dist_from_center + gc_center
			circle = [pos, radius, outer_radius]
			for star_shape in obj_shapes:
				#if Geometry.is_point_in_circle(pos, star_shape.pos, radius + star_shape.radius):
				if pos.distance_to(star_shape[0]) < radius + star_shape[1]:
					colliding = true
					radius_increase_counter += 1
					if radius_increase_counter > 5:
						max_dist_from_center *= 1.2
						radius_increase_counter = 0
					break
			if not colliding:
				for gc_circle in gc_circles:
					#if Geometry.is_point_in_circle(pos, gc_circle.pos, radius + gc_circle.radius):
					if pos.distance_to(gc_circle[0]) < radius + gc_circle[1]:
						colliding = true
						radius_increase_counter += 1
						if radius_increase_counter > 5:
							max_dist_from_center *= 1.2
							radius_increase_counter = 0
						break
		max_outer_radius = max(outer_radius, max_outer_radius)
		if gc_stars_remaining > 0:
			gc_stars_remaining -= 1
			gc_circles.append(circle)
			if gc_stars_remaining == 0:
				#Convert globular cluster to a single huge circle for collision detection purposes
				gc_circles.sort_custom(Callable(self,"sort_shapes"))
				var big_radius = gc_circles[-1][2]
				obj_shapes = [[gc_center, big_radius, gc_center.length() + big_radius]]
				gc_circles = []
		else:
			if not starting_system:
				obj_shapes.append(circle)
		if starting_system:
			radius = 320 * pow(1 / SYSTEM_SCALE_DIV, 0.3)
			obj_shapes.append([s_i.pos, radius, s_i.pos.length() + radius])
		else:
			s_i.pos = pos
			s_i.diff = get_sys_diff(pos, id, s_i)
	if c_g_g != 0 and N_fin == total_sys_num:
		var view_zoom = 500.0 / max_outer_radius
		galaxy_data[id].view = {"pos":Vector2(640, 360), "zoom":view_zoom}

func get_sys_diff(pos:Vector2, id:int, s_i:Dictionary):
	var stars:Array = s_i.stars
	var combined_star_mass = 0
	for star in stars:
		combined_star_mass += star.mass
	if c_g_g == 0:
		return Helper.clever_round((1 + pos.distance_to(system_data[0].pos) * pow(combined_star_mass, 0.5) / 5000) * galaxy_data[id].diff)
	else:
		return Helper.clever_round(galaxy_data[id].diff * pow(combined_star_mass, 0.4) * randf_range(120, 150) / max(100, pow(pos.length(), 0.5)))
	
func generate_systems(id:int):
	randomize()
	var total_sys_num = galaxy_data[id].system_num
	var spiral:bool = galaxy_data[id].type == 6
	
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity

	#Open clusters are
	var B = galaxy_data[id].B_strength#Magnetic field strength
	var dark_matter = galaxy_data[id].dark_matter
	var G = u_i.gravitational
	# Higher star_mass_param: lower temperature (older) stars
	# Higher B: hotter stars
	var star_mass_param = pow(u_i.age, 0.25) * pow(1e-9 / B, physics_bonus.BI)
	for i in range(0, total_sys_num):
		if c_g_g == 0 and i == 0:
			show.s_bk_button = true
			continue
		var s_i:Dictionary = {}
		s_i.parent = id
		s_i.planets = []
		var num_stars:int = max(-log(randf()/dark_matter)/1.5 + 1, 1)
		var stars = []
		for _j in range(0, num_stars):
			var star = {}
			#Solar masses
			var mass:float = -log(randf()) / star_mass_param / (1.65 if gc_stars_remaining == 0 else 4.0)
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			if mass < 0.08:#Y, T, L
				star_size = remap(mass, 0, 0.08, 0.01, 0.1)
				temp = remap(mass, 0, 0.08, 250, 2400)
			elif mass >= 0.08 and mass < 0.45:#M
				star_size = remap(mass, 0.08, 0.45, 0.1, 0.7)
				temp = remap(mass, 0.08, 0.45, 2400, 3700)
			elif mass >= 0.45 and mass < 0.8:#K
				star_size = remap(mass, 0.45, 0.8, 0.7, 0.96)
				temp = remap(mass, 0.45, 0.8, 3700, 5200)
			elif mass >= 0.8 and mass < 1.04:#G
				star_size = remap(mass, 0.8, 1.04, 0.96, 1.15)
				temp = remap(mass, 0.8, 1.04, 5200, 6000)
			elif mass >= 1.04 and mass < 1.4:#F
				star_size = remap(mass, 1.04, 1.4, 1.15, 1.4)
				temp = remap(mass, 1.04, 1.4, 6000, 7500)
			elif mass >= 1.4 and mass < 2.1:#A
				star_size = remap(mass, 1.4, 2.1, 1.4, 1.8)
				temp = remap(mass, 1.4, 2.1, 7500, 10000)
			elif mass >= 2.1 and mass < 9:#B
				star_size = remap(mass, 2.1, 9, 1.8, 6.6)
				temp = remap(mass, 2.1, 9, 10000, 30000)
			elif mass >= 9 and mass < 100:#O
				star_size = remap(mass, 9, 100, 6.6, 22)
				temp = remap(mass, 16, 100, 30000, 70000)
			elif mass >= 100 and mass < 1000:#Q
				star_size = remap(mass, 100, 1000, 22, 60)
				temp = remap(mass, 100, 1000, 70000, 120000)
			elif mass >= 1000 and mass < 10000:#R
				star_size = remap(mass, 1000, 10000, 60, 200)
				temp = remap(mass, 1000, 10000, 120000, 210000)
			elif mass >= 10000:#Z
				var pw = pow(mass, 1/3.0) / pow(10000, 1/3.0)
				star_size = pw * 200
				temp = pw * 210000
			
			var star_type:int
			if mass >= 0.08:
				star_type = StarType.MAIN_SEQUENCE
			else:
				star_type = StarType.BROWN_DWARF
			var hypergiant:int = -1
			if mass > 0.2 and mass < 1.3 and randf() < 0.03:
				star_type = StarType.WHITE_DWARF
				temp = 4000 + exp(10 * randf())
				star_size = randf_range(0.008, 0.02)
				mass = randf_range(0.4, 0.8)
			elif mass > 0.25:
				var r = randf()
				var star_size_tier = log(G/r) - log(G)*pow(r, 4) + 1
				if star_size_tier > 7.0:
					mass = randf_range(5, 30)
					var tier:int = ceil(star_size_tier - 7.0)
					star_size *= max(randf_range(550000, 700000) / temp, randf_range(3.0, 4.0)) * pow(1.2, tier - 1)
					star_type = StarType.HYPERGIANT + tier
					hypergiant = tier
				elif star_size_tier > 5.0:
					star_type = StarType.SUPERGIANT
					star_size *= max(randf_range(360000, 440000) / temp, randf_range(1.7, 2.1))
				elif star_size_tier > 3.5:
					star_type = StarType.GIANT
					star_size *= max(randf_range(240000, 280000) / temp, randf_range(1.2, 1.4))
			star_class = get_star_class(temp)
			var s_b:float = pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2)
			stats_univ.biggest_star = max(star_size, stats_univ.biggest_star)
			stats_dim.biggest_star = max(star_size, stats_dim.biggest_star)
			stats_global.biggest_star = max(star_size, stats_global.biggest_star)
			stats_univ.hottest_star = max(temp, stats_univ.hottest_star)
			stats_dim.hottest_star = max(temp, stats_dim.hottest_star)
			stats_global.hottest_star = max(temp, stats_global.hottest_star)
			stats_univ.star_classes[star_class[0]][int(star_class[1])] += 1
			stats_dim.star_classes[star_class[0]][int(star_class[1])] += 1
			stats_global.star_classes[star_class[0]][int(star_class[1])] += 1
			stats_univ.star_types[star_type] = stats_univ.star_types.get(star_type, 0) + 1
			stats_dim.star_types[star_type] = stats_dim.star_types.get(star_type, 0) + 1
			stats_global.star_types[star_type] = stats_global.star_types.get(star_type, 0) + 1
			star.type = star_type
			star["class"] = star_class
			star.size = Helper.clever_round(star_size, 4)
			star.pos = Vector2.ZERO
			star.temperature = Helper.clever_round(temp, 4)
			star.mass = Helper.clever_round(mass * u_i.planck, 4)
			star.luminosity = Helper.clever_round(4 * PI * pow(star_size * e(6.957, 8), 2) * e(5.67, -8) * s_b * pow(temp, 4) / e(3.828, 26), 4)
			stars.append(star)
		var combined_star_mass = 0
		for star in stars:
			combined_star_mass += star.mass
		stars.sort_custom(Callable(self,"sort_by_mass"))
		var planet_num:int = clamp(round(pow(combined_star_mass, 0.2) * randf_range(3, 9) * pow(dark_matter, 0.25)), 2, 50)
		s_i.planet_num = planet_num
		if galaxy_data[id].has("conquered"):
			s_i.conquered = true
			stats_univ.planets_conquered += planet_num
			stats_dim.planets_conquered += planet_num
			stats_global.planets_conquered += planet_num
		
		var s_id = system_data.size()
		s_i.id = s_id + systems_generated
		s_i.l_id = s_id
		s_i.pos = Vector2.ZERO
		s_i.stars = stars
		#galaxy_data[id][7].append([s_i[0], s_i[1]])
		system_data.append(s_i)
	galaxy_data[id].discovered = true

func sort_by_mass(star1:Dictionary, star2:Dictionary):
	if star1.mass > star2.mass:
		return true
	return false

func get_min_star_prop(s_id:int, prop:String):
	var min_star_prop = INF
	for star in system_data[s_id].stars:
		if star[prop] < min_star_prop:
			min_star_prop = star[prop]
	return min_star_prop

func get_max_star_prop(s_id:int, prop:String):
	var max_star_prop = 0.0
	for star in system_data[s_id].stars:
		if star[prop] > max_star_prop:
			max_star_prop = star[prop]
	return max_star_prop

func star_size_in_pixels(size:float):
	return 5.0 * size * 600.0 / STAR_SCALE_DIV

func generate_planets(id:int):#local id
	randomize()
	if not system_data[id].has("name"):
		var _name:String = "%s %s" % [tr("SYSTEM"), id]
		match len(system_data[id].stars):
			2:
				_name = "%s %s" % [tr("BINARY_SYSTEM"), id]
			3:
				_name = "%s %s" % [tr("TERNARY_SYSTEM"), id]
			4:
				_name = "%s %s" % [tr("QUADRUPLE_SYSTEM"), id]
			5:
				_name = "%s %s" % [tr("QUINTUPLE_SYSTEM"), id]
		system_data[id].name = _name
	var first_star:Dictionary = system_data[id].stars[0]
	var combined_star_mass = first_star.mass
	var star_boundary = star_size_in_pixels(first_star.size / 2.0)
	var max_star_temp = get_max_star_prop(id, "temperature")
	var max_star_size = get_max_star_prop(id, "size")
	var star_size_in_km = max_star_size * e(6.957, 5)
	var center_star_r_in_pixels:float = star_size_in_pixels(first_star.size) / 2.0
	var circles:Array = [[Vector2.ZERO, center_star_r_in_pixels]]
	var N_stars = len(system_data[id].stars)
	for i in range(1, N_stars):
		var colliding = true
		var pos:Vector2
		var star = system_data[id].stars[i]
		combined_star_mass += star.mass
		var r_offset:float = 10.0
		var radius_in_pixels = star_size_in_pixels(star.size) / 2.0
		while colliding:
			colliding = false
			var r:float = center_star_r_in_pixels + radius_in_pixels + r_offset
			var th:float = randf_range(0, 2 * PI)
			pos = Vector2.from_angle(th) * r
			for circ in circles:
				if pos.distance_to(circ[0]) < radius_in_pixels + circ[1]:
					colliding = true
					r_offset += 10.0
					break
		star.pos = pos
		star_boundary = max(star_boundary, pos.length() + radius_in_pixels)
		circles.append([pos, radius_in_pixels])
	var planet_num = system_data[id].planet_num
	var max_distance
	var j = 0
	while pow(1.3, j) * 240 < star_boundary * 2.63:
		j += 1
	var dark_matter = galaxy_data[c_g].dark_matter
	system_data[id]["planets"].clear()
	if not achievement_data.exploration.has("20_planet_system") and planet_num >= 20:
		earn_achievement("exploration", "20_planet_system")
	if not achievement_data.exploration.has("25_planet_system") and planet_num >= 25:
		earn_achievement("exploration", "25_planet_system")
	if not achievement_data.exploration.has("30_planet_system") and planet_num >= 30:
		earn_achievement("exploration", "30_planet_system")
	if not achievement_data.exploration.has("35_planet_system") and planet_num >= 35:
		earn_achievement("exploration", "35_planet_system")
	if not achievement_data.exploration.has("40_planet_system") and planet_num >= 40:
		earn_achievement("exploration", "40_planet_system")
	if not achievement_data.exploration.has("45_planet_system") and planet_num >= 45:
		earn_achievement("exploration", "45_planet_system")
	if not achievement_data.exploration.has("50_planet_system") and planet_num >= 50:
		earn_achievement("exploration", "50_planet_system")
	for i in range(1, planet_num + 1):
		# p_i = planet_info
		var p_i = {}
		if system_data[id].has("conquered"):
			p_i["conquered"] = true
		p_i["ring"] = i
		p_i["type"] = randi_range(3, 10)
		if planets_generated == 0:# Starting solar system has smaller planets
			p_i["size"] = int((2000 + randf_range(0, 7000) * (i + 1) / 2.0) * pow(u_i.gravitational, 0.5) * dark_matter)
			p_i.pressure = pow(10, randf_range(-3, log(p_i.size / 5.0) / log(10) - 3)) * u_i.boltzmann
		else:
			p_i["size"] = int((2000 + randf_range(0, 12000) * (i + 1) / 2.0) * pow(u_i.gravitational, 0.5) * dark_matter)
			p_i.pressure = pow(10, randf_range(-3, log(p_i.size) / log(10) - 2)) * u_i.boltzmann
		p_i["angle"] = randf_range(0, 2 * PI)
		if planets_generated == 0 and i == 2:
			p_i.angle = randf_range(PI/4, 3*PI/4)
		#p_i["distance"] = pow(1.3,i+(max(1.0,log(combined_star_size*(0.75+0.25/max(1.0,log(combined_star_size)))))/log(1.3)))
		p_i["distance"] = pow(1.3,i + j) * randf_range(240, 270)
		# 1 solar radius = 2.63 px = 0.0046 AU
		# 569 px = 1 AU = 215.6 solar radii
		max_distance = p_i["distance"]
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		var p_id = planet_data.size()
		p_i["id"] = p_id + planets_generated
		p_i["l_id"] = p_id
		system_data[id]["planets"].append({"local":p_id, "global":p_id + planets_generated})
		var dist_in_km = p_i.distance / 569.0 * e(1.5, 8)#                             V bond albedo
		var temp = max_star_temp * pow(star_size_in_km / (2 * dist_in_km), 0.5) * pow(1 - 0.1, 0.25)
		p_i.temperature = temp# in K
		var gas_giant:bool = c_s_g != 0 and p_i.size >= max(22000, 40000 * pow(combined_star_mass / u_i.planck, 0.5) / dark_matter)
		if gas_giant:
			p_i.crust_start_depth = 0
			p_i.mantle_start_depth = 0
			if p_i.temperature > 100:
				p_i.type = 12
			else:
				p_i.type = 11
			p_i.name = "%s %s" % [tr("GAS_GIANT"), p_id]
		else:
			p_i["name"] = tr("PLANET") + " " + str(p_id)
			p_i.crust_start_depth = randi_range(50, 450)
			p_i.mantle_start_depth = round(randf_range(0.005, 0.02) * p_i.size * 1000)
		var list_of_element_probabilities = Data.elements.duplicate()
		if u_i.cluster_data[c_c].rich_elements.has("C"):
			list_of_element_probabilities.CO2 *= (u_i.cluster_data[c_c].rich_elements.C - 1.0) / 2.0 + 1.0
			list_of_element_probabilities.CH4 *= (u_i.cluster_data[c_c].rich_elements.C - 1.0) / 4.0 + 1.0
		if u_i.cluster_data[c_c].rich_elements.has("Ne"):
			list_of_element_probabilities.Ne *= u_i.cluster_data[c_c].rich_elements.Ne
		if u_i.cluster_data[c_c].rich_elements.has("Xe"):
			list_of_element_probabilities.Xe *= u_i.cluster_data[c_c].rich_elements.Xe
		p_i.atmosphere = make_atmosphere_composition(temp, p_i.pressure, list_of_element_probabilities)
		p_i.crust = make_planet_composition(temp, "crust", p_i.size, gas_giant)
		p_i.mantle = make_planet_composition(temp, "mantle", p_i.size, gas_giant)
		p_i.core = make_planet_composition(temp, "core", p_i.size, gas_giant)
		p_i.core_start_depth = round(randf_range(0.4, 0.46) * p_i.size * 1000)
		p_i.surface = add_surface_materials(temp, p_i.crust)
		p_i.liq_seed = randi()
		p_i.liq_period = randf_range(0.1, 1)
		if id + systems_generated == 0 and c_u == 0:#Only water in solar system
			if randf() < 0.2:
				p_i.lake = {"element":"H2O"}
		elif p_i.temperature <= 1000:
			p_i.lake = {"element":get_random_element(list_of_element_probabilities)}
		p_i.HX_data = []
		var diff:float = system_data[id].diff
		var power_left:float = diff * pow(p_i.size / 2500.0, 0.5)
		var max_lv:int = max(1, 1 + log(2.0 * power_left) / log(1.3))
		var num:int = 0
		var total_num:int = randi() % 12 + 1
		if not p_i.has("conquered"):
			var enemy_positions:PackedVector2Array = []
			while num < total_num:
				num += 1
				var lv:int = randi_range(max(1, max_lv - 8), max_lv)
				var _class:int = 1
				if randf() < log(diff) / log(100) - 1.0:#difficulty < 100 = no green enemies, difficulty = 1000 = 50% chance of green enemies, difficulty > 10000 = no more red enemies, always green or higher
					_class += 1
				if randf() < log(diff / 100.0) / log(100) - 1.0:
					_class += 1
				if randf() < log(diff / 10000.0) / log(100) - 1.0:
					_class += 1
				if planets_generated == 0:
					lv = min(lv, 4)
					if i == 2:
						lv = 1
				if num == total_num:
					lv = max(1, 1 + log(2.0 * power_left) / log(1.3))
				var HP_power = 7.0 * (2.0 * randf() + 0.2)
				var stat_power = 48.0 - 1.5 * HP_power + lv / 2
				var HP = round(HP_power * (lv + 1.0))
				if _class == 2:
					HP = round(HP * randf_range(4.0, 6.0))
				elif _class >= 3:
					HP = round(HP * randf_range(8.0, 12.0))
				var stats = [0.0, 0.0, 0.0, 0.0]
				while stat_power > 0:
					stats[randi() % 4] += 1
					stat_power -= 1
				var attack = stats[0]
				var defense = stats[1]
				var accuracy = stats[2]
				var agility = stats[3]
				if planets_generated == 0 and i == 2:
					while agility > 7:
						agility -= 3
						attack += 1
						defense += 1
						accuracy += 1
				var _money = round(randf_range(1, 2) * pow(1.3, lv - 1) * 50000)
				var XP = round(pow(1.25, lv - 1) * 40)
				var colliding = true
				var initial_position:Vector2
				while colliding:
					colliding = false
					initial_position = Vector2(randf_range(640.0 - num * 10.0, 900.0 + num * 20.0), randf_range(220.0 - num * 15.0, 500.0 + num * 15.0))
					for pos in enemy_positions:
						if Geometry2D.is_point_in_circle(initial_position, pos, 30.0):
							colliding = true
							break
				enemy_positions.append(initial_position)
				var HX_data = {
					"class":_class,
					"type":randi() % 4 + 1,
					"passive_abilities":[randi() % Battle.PassiveAbility.N],
					"lv":lv,
					"HP":HP,
					"attack":attack,
					"defense":defense,
					"accuracy":accuracy,
					"agility":agility,
					"initial_position":initial_position,
					"money":_money,
					"XP":XP}
				while randf() < 0.25:
					var additional_passive_ability = randi() % Battle.PassiveAbility.N
					if additional_passive_ability not in HX_data.passive_abilities:
						HX_data.passive_abilities.append(additional_passive_ability)
						HX_data.money *= 0.7 * len(HX_data.passive_abilities)
						HX_data.XP *= 0.7 * len(HX_data.passive_abilities)
				p_i.HX_data.append(HX_data)
				power_left -= 0.5 * pow(1.3, lv - 1)
				if power_left <= 0.0:
					break
			p_i.HX_data.shuffle()
		var wid:int = Helper.get_wid(p_i.size)
		var view_zoom = 3.0 / wid
		p_i.view = {"pos":Vector2(340, 80), "zoom":view_zoom}
		if c_u != 0 and planets_generated == 0 and i == 3:
			p_i.discovered = true
			p_i.conquered = true
			p_i.angle = PI / 2
			p_i.pressure = 1
		stats_univ.biggest_planet = max(p_i.size, stats_univ.biggest_planet)
		stats_dim.biggest_planet = max(p_i.size, stats_dim.biggest_planet)
		stats_global.biggest_planet = max(p_i.size, stats_global.biggest_planet)
		if c_s_g != 0:
			if p_i.type in [11, 12]:
				if randf() < min(sqrt(p_i.size) / 3000.0 + pow(p_i.pressure, 0.3) / 100.0, 0.03) * pow(u_i.get("age", 1.0), 0.15):
					p_i.MS = "MME"
			elif randf() < min(p_i.size / 500000.0 + pow(p_i.pressure, 0.7) / 400.0, 0.03) * pow(u_i.get("age", 1.0), 0.15):
				p_i.MS = "SE"
			if p_i.has("MS"):
				p_i.MS_lv = randi() % (Data.MS_num_stages[p_i.MS] + 1)
				if p_i.MS == "MME":
					p_i.repair_cost = Data.MS_costs[p_i.MS + "_" + str(p_i.MS_lv)].money * randf_range(1, 3) * 24 * pow(p_i.size / 13000.0, 2)
				elif p_i.MS == "SE":
					p_i.repair_cost = Data.MS_costs[p_i.MS + "_" + str(p_i.MS_lv)].money * 24 * randf_range(1, 3) * p_i.size / 12000.0
				p_i.repair_cost *= engineering_bonus.BCM
				system_data[id].has_MS = true
		planet_data.append(p_i)
	if c_s_g != 0:
		for i in range(0, N_stars):
			var star = system_data[id].stars[i]
			var star_size = star.size
			var star_temp = star.temperature
			var star_lum = star.luminosity
			var MSes = ["DS", "MB", "PK", "CBS"]
			if c_g_g == 0:
				MSes.erase("MB")
			var MS = MSes[randi() % len(MSes)]
			if MS in ["DS", "MB"] and randf() < min(sqrt(star_temp) / pow(star_size, 1.5) / 100.0, 0.03):
				star.MS = MS
			elif randf() < min(pow(star_lum, 0.1) / 25.0, 0.03):
				star.MS = MS
			if star.has("MS"):
				star.MS_lv = randi() % (Data.MS_num_stages[star.MS] + 1)
				star.bldg = {}
				if star.MS == "MB":
					star.repair_cost = Data.MS_costs[star.MS].money * 72 * randf_range(1, 3) * pow(star.size, 2)
				elif star.MS == "DS":
					star.repair_cost = Data.MS_costs[star.MS + "_" + str(star.MS_lv)].money * 24 * randf_range(1, 3) * pow(star.size, 2)
				elif star.MS == "CBS":
					star.repair_cost = Data.MS_costs[star.MS + "_" + str(star.MS_lv)].money * 24 * randf_range(1, 3)
				elif star.MS == "PK":
					star.repair_cost = Data.MS_costs[star.MS + "_" + str(star.MS_lv)].money * 24 * randf_range(1, 3) * planet_data[-1].distance / 1000.0
				star.repair_cost *= engineering_bonus.BCM
				system_data[id].has_MS = true
		var view_zoom = 400.0 / max_distance * (planet_data[0].distance / 70)
		system_data[id]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}
	system_data[id].closest_planet_distance = planet_data[0].distance
	system_data[id]["discovered"] = true
	planets_generated += planet_num
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

func generate_volcano(t_id:int, VEI:float, artificial:bool = false):
	var richness:float = VEI if VEI <= 7.0 else pow(VEI - 6.0, 1.6) + 6.0
	var size:int = snapped(VEI - 2, 2) + 1
	var half_size:int = size / 2
	var wid:int = Helper.get_wid(planet_data[c_p].size)
	var i:int = t_id % wid
	var j:int = t_id / wid
	var building_to_resource = {
		Building.MINERAL_EXTRACTOR:"minerals",
		Building.RESEARCH_LAB:"SP",
	}
	for k in range(max(0, i - half_size), min(i + half_size + 1, wid)):
		for l in range(max(0, j - half_size + abs(k-i)), min(j + half_size - abs(k-i) + 1, wid)):
			var current_tile_id:int = k % wid + l * wid
			if !tile_data[current_tile_id]:
				tile_data[current_tile_id] = {}
			var current_tile = tile_data[current_tile_id]
			if current_tile.has("lake"):
				continue
			if !current_tile.has("resource_production_bonus"):
				current_tile.resource_production_bonus = {}
			var overclock_mult = current_tile.bldg.get("overclock_mult", 1.0) if current_tile.has("bldg") else 1.0
			if current_tile.has("ash"):
				if not current_tile.has("cave"):
					var diff = max(richness - current_tile.ash.richness, 0)
					if current_tile.has("bldg") and building_to_resource.has(current_tile.bldg.name):
						var rsrc = building_to_resource[current_tile.bldg.name]
						autocollect.rsrc[rsrc] += diff * current_tile.bldg.path_1_value * overclock_mult * current_tile.resource_production_bonus.get(rsrc, 1.0)
					current_tile.ash.richness = max(richness, current_tile.ash.richness)
					current_tile.resource_production_bonus.minerals = current_tile.resource_production_bonus.get("minerals", 1.0) + diff
					current_tile.resource_production_bonus.SP = current_tile.resource_production_bonus.get("SP", 1.0) + diff / 2.0
			else:
				current_tile.ash = {"richness":richness}
				current_tile.resource_production_bonus.minerals = current_tile.resource_production_bonus.get("minerals", 1.0) + (richness - 1.0)
				current_tile.resource_production_bonus.SP = current_tile.resource_production_bonus.get("SP", 1.0) + (richness - 1.0) / 2.0
				if current_tile.has("bldg") and building_to_resource.has(current_tile.bldg.name):
					var rsrc = building_to_resource[current_tile.bldg.name]
					autocollect.rsrc[rsrc] += (richness - 1.0) * current_tile.bldg.path_1_value * overclock_mult * current_tile.resource_production_bonus.get(rsrc, 1.0)
				if artificial:
					current_tile.ash.artificial = true
			if not achievement_data.exploration.has("volcano_cave") and current_tile.has("cave"):
				earn_achievement("exploration", "volcano_cave")
			if not achievement_data.exploration.has("volcano_aurora_cave") and current_tile.has("cave") and current_tile.has("aurora"):
				earn_achievement("exploration", "volcano_aurora_cave")
	if !tile_data[t_id]:
		tile_data[t_id] = {}
	tile_data[t_id].volcano = {"VEI":VEI}

func generate_tiles(id:int):
	tile_data.clear()
	var p_i:Dictionary = planet_data[id]
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = Helper.get_wid(p_i.size)
	var N:int = pow(wid, 2)
	tile_data.resize(N)
	for i in N:
		tile_data[i] = {"resource_production_bonus":{}}
	#Aurora spawn
	var diff:int = 0
	var tile_from:int = -1
	var tile_to:int = -1
	var rand:float = randf()
	var thiccness:int = ceil(randf_range(1, 3) * wid / 50.0 * physics_bonus.aurora_width_multiplier)
	var pulsation:float = randf_range(0.4, 1)
	var amplitude:float = 0.85
	var max_star_temp = get_max_star_prop(c_s, "temperature")
	var num_auroras:int = 2
	var home_planet:bool = c_p_g == 2 and c_u == 0
	var B_strength:float = galaxy_data[c_g].B_strength
	for i in num_auroras:
		if not home_planet and (randf() < physics_bonus.aurora_spawn_probability * pow(p_i.pressure, 0.15)):
			#au_int: aurora_intensity
			var au_int = Helper.clever_round(80000 * randf_range(1, 2) * B_strength * max_star_temp)
			if tile_from == -1:
				tile_from = randi() % wid
				tile_to = randi() % wid
			if rand < 0.5:#Vertical
				for j in wid:
					var x_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness * amplitude * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(x_pos - int(thiccness / 2) + diff, x_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						show.auroras = true
						var id2:int = k + j * wid
						if tile_data[id2].has("aurora"):
							tile_data[id2].aurora *= au_int
							tile_data[id2].resource_production_bonus.SP *= au_int
							tile_data[id2].resource_production_bonus.energy *= au_int
						else:
							tile_data[id2].aurora = au_int
							tile_data[id2].resource_production_bonus.SP = tile_data[id2].resource_production_bonus.get("SP", 1.0) + au_int
							tile_data[id2].resource_production_bonus.energy = tile_data[id2].resource_production_bonus.get("energy", 1.0) + au_int
			else:#Horizontal
				for j in wid:
					var y_pos:int = lerp(tile_from, tile_to, j / float(wid)) + diff + thiccness * amplitude * sin(j / float(wid) * 4 * pulsation * PI)
					for k in range(y_pos - int(thiccness / 2) + diff, y_pos + int(ceil(thiccness / 2.0)) + diff):
						if k < 0 or k > wid - 1:
							continue
						show.auroras = true
						var id2:int = j + k * wid
						if tile_data[id2].has("aurora"):
							tile_data[id2].aurora *= au_int
							tile_data[id2].resource_production_bonus.SP *= au_int
							tile_data[id2].resource_production_bonus.energy *= au_int
						else:
							tile_data[id2].aurora = au_int
							tile_data[id2].resource_production_bonus.SP = tile_data[id2].resource_production_bonus.get("SP", 1.0) + au_int
							tile_data[id2].resource_production_bonus.energy = tile_data[id2].resource_production_bonus.get("energy", 1.0) + au_int
			stats_global.highest_au_int = max(au_int, stats_global.highest_au_int)
			stats_dim.highest_au_int = max(au_int, stats_dim.highest_au_int)
			stats_univ.highest_au_int = max(au_int, stats_univ.highest_au_int)
			if wid / 3 == 1:
				diff = thiccness + 1
			else:
				diff = randi_range(thiccness + 1, wid / 3) * sign(randf_range(-69, 69))
			if i == 0 and randf() < physics_bonus.perpendicular_auroras:
				rand = 1.0 - rand
	#We assume that the star system's age is inversely proportional to the coldest star's temperature
	#Age is a factor in crater rarity. Older systems have more craters
	var coldest_star_temp = get_min_star_prop(c_s, "temperature")
	var noise = FastNoiseLite.new()
	noise.seed = p_i.liq_seed
	noise.fractal_octaves = 1
	noise.frequency = 1.0 / p_i.liq_period#Higher period = bigger lakes
	if p_i.has("lake"):
		var phase_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake.element + ".tscn")
		var phase = phase_scene.instantiate()
		if chemistry_bonus.has(p_i.lake.element):
			phase.modify_PD(chemistry_bonus[p_i.lake.element])
		p_i.lake.state = Helper.get_state(p_i.temperature, p_i.pressure, phase)
		phase.free()
	var volcano_probability:float = 0.0
	if randf() < log(20.0 / sqrt(coldest_star_temp/u_i.gravitational) + 1.0):
		volcano_probability = min(sqrt(u_i.gravitational) / sqrt(randf()) / N, 0.15)
	var empty_tiles = []
	var crater_num:int = 0
	var total_VEI:float = 0.0
	for i in wid:
		for j in wid:
			var level:float = noise.get_noise_2d(i / float(wid), j / float(wid))
			var t_id = i % wid + j * wid
			var cave_can_spawn = true
			var is_lake = level > 0.5 and p_i.has("lake") and p_i.lake.state != "g"
			if is_lake and not tile_data[t_id].has("ash"):
				tile_data[t_id].lake = true
				tile_data[t_id].resource_production_bonus.clear()
				if p_i.lake.state != "s":
					cave_can_spawn = false
			if home_planet:
				continue
			if cave_can_spawn and randf() < 0.1 / pow(wid, 0.9):
				var floor_size:int = randf_range(25 * min(wid / 8.0, 1), 40 * randf_range(1, 1 + wid / 100.0))
				var num_floors:int = randi() % (int(wid / 2.5) + 1) + 3
				var modifiers:Dictionary = {}
				if c_s_g != 0:
					var number_of_modifiers:int = log(1.0 / randf() + 1.1) * log(system_data[c_s].diff) / log(10)
					var modifiers2:Dictionary = Data.cave_modifiers.duplicate(true)
					if c_g_g == 0:
						number_of_modifiers = min(number_of_modifiers, 2)
						for mod in modifiers2.keys():
							if modifiers2[mod].tier == 2:
								modifiers2.erase(mod)
					if number_of_modifiers > len(modifiers2.keys()):
						number_of_modifiers = len(modifiers2.keys())
					for k in number_of_modifiers:
						var modifier_keys:Array = modifiers2.keys()
						modifier_keys.shuffle()
						var key:String = modifier_keys[0]
						if modifiers2[key].has("double_treasure_at"):
							var mod_power:float = log(1.0 / randf() + 0.5) / max(remap(log(system_data[c_s].diff) / log(20), 0.0, 4.0, 2.0, 1.0), 1.0)
							var direction:float
							if modifiers2[key].has("one_direction"):
								direction = modifiers2[key].one_direction
							else:
								direction = sign(randf() - 0.5)
							modifiers[key] = pow(modifiers2[key].double_treasure_at, mod_power * direction)
							if modifiers2[key].has("min") and modifiers[key] < modifiers2[key].min:
								modifiers[key] = modifiers2[key].min
							if modifiers2[key].has("max") and modifiers[key] > modifiers2[key].max:
								modifiers[key] = modifiers2[key].max
						elif randf() < 0.5:
							modifiers[key] = modifiers2[key].treasure_if_true
						modifiers2.erase(key)
				var period:int = 65 + sign(randf() - 0.5) * randf() * 40
				tile_data[t_id].cave = {"num_floors":num_floors, "floor_size":floor_size, "period":period, "debris":randf() + 0.2}
				if tile_data[t_id].has("ash") and not achievement_data.exploration.has("volcano_cave") and tile_data[t_id].has("cave"):
					earn_achievement("exploration", "volcano_cave")
				if not modifiers.is_empty():
					tile_data[t_id].cave.modifiers = modifiers
				if not achievement_data.exploration.has("aurora_cave") and tile_data[t_id].has("aurora"):
					earn_achievement("exploration", "aurora_cave")
				if not achievement_data.exploration.has("volcano_aurora_cave") and tile_data[t_id].has("ash") and tile_data[t_id].has("aurora"):
					earn_achievement("exploration", "volcano_aurora_cave")
				continue
			if is_lake:
				continue
			if c_s_g != 0 and randf() < volcano_probability:
				var VEI:float = log(1e6/(coldest_star_temp * u_i.gravitational * randf()) + exp(3.0))
				total_VEI += VEI
				generate_volcano(t_id, VEI)
				continue
			var crater_size = max(0.25, pow(p_i.pressure, 0.3))
			if randf() < 15 / crater_size / pow(coldest_star_temp, 0.8):
				if tile_data[t_id].has("ash"):
					continue
				tile_data[t_id].crater = {}
				tile_data[t_id].crater.variant = randi() % 2 + 1
				var depth = ceil(pow(10, randf_range(2, 3)) * pow(crater_size, 0.8))
				tile_data[t_id].crater.init_depth = depth
				tile_data[t_id].depth = depth
				tile_data[t_id].crater.metal = "lead"
				crater_num += 1
				for met in met_info:
					if met == "lead":
						continue
					if randf() < 0.3 / pow(met_info[met].rarity, 0.95) * sqrt(1 + u_i.cluster_data[c_c].pos.length() / 1000.0):
						if c_s_g == 0 and met_info[met].rarity > 8:
							continue
						if c_g_g == 0 and met_info[met].rarity > 50:
							continue
						tile_data[t_id].crater.metal = met
						if not achievement_data.exploration.has("diamond_crater") and met == "diamond":
							earn_achievement("exploration", "diamond_crater")
						if not achievement_data.exploration.has("nanocrystal_crater") and met == "nanocrystal":
							earn_achievement("exploration", "nanocrystal_crater")
						if not achievement_data.exploration.has("mythril_crater") and met == "mythril":
							earn_achievement("exploration", "mythril_crater")
				continue
			empty_tiles.append(t_id)
	var ancient_bldgs_list:Dictionary = {	AncientBuilding.SPACEPORT:				log(p_i.pressure + 1), 
											AncientBuilding.MINERAL_REPLICATOR:		1.0 + total_VEI / 6.0,
											AncientBuilding.OBSERVATORY:				max(-log(p_i.pressure / 2.0 + 0.001), 0),
											AncientBuilding.MINING_OUTPOST:			1.0 + 15.0 * crater_num / N,
											#AncientBuilding.AURORA_GENERATOR:		5.0 if diff == 0 else 1.0,
											AncientBuilding.SUBSTATION:				max(-log(p_i.pressure / 10.0 + 0.1), 0),
											AncientBuilding.CELLULOSE_SYNTHESIZER:	log(p_i.pressure * (1.0 + p_i.atmosphere.CH4 + p_i.atmosphere.CO2 + p_i.atmosphere.H + p_i.atmosphere.O + p_i.atmosphere.H2O) + 1)
	}
	var ancient_bldgs_list_without_NFR = ancient_bldgs_list.duplicate()
	if c_s_g != 0:
		ancient_bldgs_list[AncientBuilding.NUCLEAR_FUSION_REACTOR] = log(p_i.pressure * (1.0 + p_i.atmosphere.CH4 + p_i.atmosphere.H + p_i.atmosphere.H2O) + 1)
	var S = 0.0
	var S2 = 0.0
	for ancient_bldg in ancient_bldgs_list.keys():
		S += ancient_bldgs_list[ancient_bldg]
	for ancient_bldg in ancient_bldgs_list.keys():
		ancient_bldgs_list[ancient_bldg] /= S
	for ancient_bldg in ancient_bldgs_list_without_NFR.keys():
		S2 += ancient_bldgs_list_without_NFR[ancient_bldg]
	for ancient_bldg in ancient_bldgs_list_without_NFR.keys():
		ancient_bldgs_list_without_NFR[ancient_bldg] /= S2
	var nuclear_fusion_reactor_tiles = []
	var base_ancient_bldg_probability = 0.0
	if randf() < 500.0 / coldest_star_temp:
		base_ancient_bldg_probability = 1 if p_i.temperature < 273 else -pow((p_i.temperature / 273.0 - 1), 2) + 1
	planet_data[id].ancient_bldgs = {}
	if not home_planet:
		var spaceport_spawned = false
		for t_id in empty_tiles:
			if t_id in nuclear_fusion_reactor_tiles:
				continue
			if randf() < 0.1 / pow(wid, 0.5) * base_ancient_bldg_probability:
				var i = t_id % wid
				var j = t_id / wid
				var ancient_bldg
				var rand2 = randf()
				var k = 0
				var S3 = 0
				if i == wid-1 or j == wid-1:
					for _ancient_bldg in ancient_bldgs_list_without_NFR.keys():
						if rand2 < ancient_bldgs_list_without_NFR[_ancient_bldg] + S3:
							ancient_bldg = _ancient_bldg
							break
						else:
							k += 1
							S3 += ancient_bldgs_list_without_NFR[_ancient_bldg]
				else:
					for _ancient_bldg in ancient_bldgs_list.keys():
						if rand2 < ancient_bldgs_list[_ancient_bldg] + S3:
							ancient_bldg = _ancient_bldg
							break
						else:
							k += 1
							S3 += ancient_bldgs_list[_ancient_bldg]
					if ancient_bldg == AncientBuilding.NUCLEAR_FUSION_REACTOR:
						nuclear_fusion_reactor_tiles.append_array([t_id+1, t_id+wid, t_id+wid+1])
						erase_tile(t_id)
						erase_tile(t_id+1)
						erase_tile(t_id+wid)
						erase_tile(t_id+wid+1)
				if ancient_bldg == AncientBuilding.SPACEPORT:
					if spaceport_spawned:
						continue
					spaceport_spawned = true
				var obj = {"tile":t_id, "tier":max(1, int(-log(randf() / u_i.age / (1.0 + u_i.cluster_data[c_c].pos.length() * u_i.dark_energy / 1000.0)) / 3.0 + 1))}
				if randf() < 1.0 - 0.5 * exp(-pow(p_i.temperature - 273, 2) / 20000.0) / pow(obj.tier, 2):
					obj.repair_cost = 250000 * pow(obj.tier, 20) * randf_range(1, 3) * Data.ancient_bldg_repair_cost_multipliers[ancient_bldg]
				if p_i.ancient_bldgs.has(ancient_bldg):
					p_i.ancient_bldgs[ancient_bldg].append(obj)
				else:
					p_i.ancient_bldgs[ancient_bldg] = [obj]
	if p_i.id == 6:#Guaranteed wormhole spawn on furthest planet in solar system
		var random_tile:int = randi() % len(tile_data)
		erase_tile(random_tile)
		var dest_id:int = randi_range(1, galaxy_data[0].system_num - 1)#		local_destination_system_id		global_dest_s_id
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id}
		p_i.wormhole = true
	elif c_s_g != 0 and randf() < 0.1:#10% chance to spawn a wormhole on a planet outside solar system
		var random_tile:int = randi() % len(tile_data)
		erase_tile(random_tile)
		var dest_id:int = randi() % len(system_data)
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id + system_data[0].id}
		p_i.wormhole = true#								new: whether the wormhole should generate a new wormhole on another planet
	if p_i.has("lake") and p_i.lake.state == "g":
		p_i.erase("lake")
	planet_data[id]["discovered"] = true
	if home_planet:
		tile_data[41].cave = {"num_floors":5, "floor_size":25, "period":65, "debris":0.3}
		tile_data[215].cave = {"num_floors":8, "floor_size":30, "period":50, "debris":0.4}
		tile_data[112].ship = true
		p_i.ancient_bldgs = {AncientBuilding.SPACEPORT:[{"tile":113, "tier":1, "repair_cost":10000 * Data.ancient_bldg_repair_cost_multipliers[AncientBuilding.SPACEPORT]}],
							AncientBuilding.MINERAL_REPLICATOR:[{"tile":55, "tier":1, "repair_cost":10000 * Data.ancient_bldg_repair_cost_multipliers[AncientBuilding.MINERAL_REPLICATOR]}]}
	elif c_p_g == 2:
		var random_tile:int = randi() % N
		erase_tile(random_tile)
		var random_tile2:int = random_tile
		while random_tile == random_tile2:
			random_tile2 = randi() % N
		var random_tile3:int = random_tile
		while random_tile == random_tile3 or random_tile2 == random_tile3:
			random_tile3 = randi() % N
		erase_tile(random_tile2)
		erase_tile(random_tile3)
		tile_data[random_tile].ship = true
		var mineral_replicator = {"tile":random_tile3, "tier":max(1, int(-log(randf() / u_i.age) / 3.0 + 1))}
		var spaceport:Dictionary
		mineral_replicator.repair_cost = 10000 * pow(mineral_replicator.tier, 20) * randf_range(1, 5) * Data.ancient_bldg_repair_cost_multipliers[AncientBuilding.MINERAL_REPLICATOR]
		if random_tile == N-1:
			spaceport = {"tile":random_tile - 1, "tier":max(1, int(-log(randf() / u_i.age) / 3.0 + 1))}
			erase_tile(random_tile - 1)
		else:
			spaceport = {"tile":random_tile + 1, "tier":max(1, int(-log(randf() / u_i.age) / 3.0 + 1))}
			erase_tile(random_tile + 1)
		spaceport.repair_cost = 10000 * pow(spaceport.tier, 20) * randf_range(1, 5) * Data.ancient_bldg_repair_cost_multipliers[AncientBuilding.SPACEPORT]
		p_i.ancient_bldgs = {AncientBuilding.SPACEPORT:[spaceport], AncientBuilding.MINERAL_REPLICATOR:[mineral_replicator]}
		tile_data[random_tile2].cave = {"num_floors":8, "floor_size":30, "period":50, "debris":0.4}
	for bldg in p_i.ancient_bldgs.keys():
		for i in len(p_i.ancient_bldgs[bldg]):
			var tier:int = p_i.ancient_bldgs[bldg][i].tier
			var t_id = p_i.ancient_bldgs[bldg][i].tile
			for j in ([t_id, t_id+1, t_id+wid, t_id+1+wid] if bldg == AncientBuilding.NUCLEAR_FUSION_REACTOR else [t_id]):
				tile_data[j].ancient_bldg = {"name":bldg, "tier":tier, "id":i}
				if p_i.ancient_bldgs[bldg][i].has("repair_cost"):
					tile_data[j].ancient_bldg.repair_cost = p_i.ancient_bldgs[bldg][i].repair_cost
			if not p_i.ancient_bldgs[bldg][i].has("repair_cost"):
				Helper.set_ancient_bldg_bonuses(p_i, tile_data[t_id].ancient_bldg, t_id, wid)
			if not achievement_data.exploration.has("tier_2_ancient_bldg") and tier >= 2:
				earn_achievement("exploration", "tier_2_ancient_bldg")
			if not achievement_data.exploration.has("tier_3_ancient_bldg") and tier >= 3:
				earn_achievement("exploration", "tier_3_ancient_bldg")
			if not achievement_data.exploration.has("tier_4_ancient_bldg") and tier >= 4:
				earn_achievement("exploration", "tier_4_ancient_bldg")
			if not achievement_data.exploration.has("tier_5_ancient_bldg") and tier >= 5:
				earn_achievement("exploration", "tier_5_ancient_bldg")
			ancient_bldgs_discovered[bldg][tier] = ancient_bldgs_discovered[bldg].get(tier, 0) + 1
			if not achievement_data.exploration.has("find_all_ancient_bldgs"):
				var all_discovered = true
				for UB in ancient_bldgs_discovered.keys():
					if ancient_bldgs_discovered[UB].is_empty():
						all_discovered = false
						break
				if all_discovered:
					earn_achievement("exploration", "find_all_ancient_bldgs")
	
	#Give lake data to adjacent tiles
	var lake_au_int:float = 0.0
	if not achievement_data.exploration.has("find_neon_lake"):
		if p_i.has("lake") and p_i.lake.element == "Ne":
			earn_achievement("exploration", "find_neon_lake")
	if not achievement_data.exploration.has("find_xenon_lake"):
		if p_i.has("lake") and p_i.lake.element == "Xe":
			earn_achievement("exploration", "find_xenon_lake")
	if p_i.has("lake"):
		if p_i.lake.element == "Ne":
			lake_au_int = Helper.clever_round(1.2e6 * (randf_range(1, 2)) * B_strength * max_star_temp)
		elif p_i.lake.element == "Xe":
			lake_au_int = Helper.clever_round(9.5e7 * (randf_range(1, 2)) * B_strength * max_star_temp)
	for i in wid:
		for j in wid:
			var t_id = i % wid + j * wid
			var tile = tile_data[t_id]
			if tile.has("lake"):
				var lake_info = p_i.lake
				var distance_from_lake:int = 1
				if lake_info.element in ["H", "Xe"]:
					distance_from_lake += Data.lake_bonus_values[lake_info.element][lake_info.state] + biology_bonus[lake_info.element]
				for k in range(max(0, i - distance_from_lake), min(i + distance_from_lake + 1, wid)):
					for l in range(max(0, j - distance_from_lake), min(j + distance_from_lake + 1, wid)):
						var id2 = k % wid + l * wid
						var _tile = tile_data[id2]
						if Vector2(k, l) == Vector2(i, j):
							continue
						if lake_au_int > 0.0 and not _tile.has("lake"):
							if _tile.has("aurora"):
								if not _tile.has("lake_elements"):
									_tile.aurora += lake_au_int
									_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + lake_au_int
								else:
									_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + max(0, lake_au_int - _tile.aurora)
									_tile.aurora = max(lake_au_int, _tile.aurora)
							else:
								_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + lake_au_int
								_tile.aurora = lake_au_int
						if _tile.has("lake_elements"):
							_tile.lake_elements[lake_info.element] = lake_info.state
						else:
							_tile.lake_elements = {lake_info.element:lake_info.state}
			elif tile.has("crater"):
				for k in range(max(0, i - 1), min(i + 1 + 1, wid)):
					for l in range(max(0, j - 1), min(j + 1 + 1, wid)):
						var id2 = k % wid + l * wid
						var _tile = tile_data[id2]
						if Vector2(k, l) == Vector2(i, j):
							continue
						_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + pow(met_info[tile.crater.metal].rarity, 0.6) - 0.8
			elif tile.has("wormhole"):
				for k in range(max(0, i - 2), min(i + 2 + 1, wid)):
					for l in range(max(0, j - 2), min(j + 2 + 1, wid)):
						var id2 = k % wid + l * wid
						var _tile = tile_data[id2]
						if Vector2(k, l) == Vector2(i, j):
							continue
						_tile.resource_production_bonus.SP = _tile.resource_production_bonus.get("SP", 1.0) + 7.0
	# Give science point production bonus to tiles surrounding lakes
	for i in len(tile_data):
		var tile = tile_data[i]
		if tile.has("cave") or tile.has("volcano") or tile.has("lake") or tile.has("wormhole"):
			tile.resource_production_bonus.clear()
		elif tile.has("lake_elements"):
			for el in tile.lake_elements.keys():
				var state_multiplier = 1.0
				var state = tile.lake_elements[el]
				if state == "l":
					state_multiplier = 2.0
				elif state == "sc":
					state_multiplier = 1.5
				tile.resource_production_bonus.SP = tile.resource_production_bonus.get("SP", 1.0) + Data.lake_SP_bonus[el] * state_multiplier
	var planet_with_nothing = true
	for i in N:
		if len(tile_data[i].keys()) == 1 and tile_data[i].resource_production_bonus.is_empty():
			tile_data[i] = null
		else:
			planet_with_nothing = false
	if not achievement_data.exploration.has("planet_with_nothing") and planet_with_nothing:
		earn_achievement("exploration", "planet_with_nothing")
	Helper.save_obj("Planets", c_p_g, tile_data)
	Helper.save_obj("Systems", c_s_g, planet_data)
	tile_data.clear()

func erase_tile(tile:int):
	if tile_data[tile] == null:
		tile_data[tile] = {}
	for key in tile_data[tile].keys():
		if not key in ["aurora", "ash", "resource_production_bonus"]:
			tile_data[tile].erase(key)

func make_atmosphere_composition(temp:float, pressure:float, list_of_element_probabilities:Dictionary):
	var atm = {}
	var S:float = 0
	for el in list_of_element_probabilities.keys():
		var phase_scene = load("res://Scenes/PhaseDiagrams/" + el + ".tscn")
		var phase = phase_scene.instantiate()
		if chemistry_bonus.has(el):
			phase.modify_PD(chemistry_bonus[el])
		var rand = list_of_element_probabilities[el] / (1 - randf())
		var el_state = Helper.get_state(temp, pressure, phase)
		if el_state == "l":
			rand *= 0.2
		elif el_state == "sc":
			rand *= 0.5
		elif el_state == "s":
			rand *= 0.05
		atm[el] = rand
		S += rand
		phase.free()
	for el in atm:
		atm[el] /= S
	return atm

func make_planet_composition(temp:float, depth:String, size:float, gas_giant:bool = false):
	var elements = {}
	var big_planet_factor:float = clamp(remap(size, 12500, 45000, 1, 5), 1, 5)
	var FM:float = u_i.cluster_data[c_c].FM
	if not gas_giant or depth == "core":
		if depth == "crust":
			var O = randf_range(1.0, 1.9)
			elements = {	"O":O,
							"Si":O * randf_range(3.9, 4),
							"Al":0.05 * randf(),
							"Fe":0.035 * FM * randf(),
							"Na":0.025 * randf(),
							"Ti":0.005 * randf(),
							"H":0.01 * big_planet_factor * randf(),
							"C":0.01 * big_planet_factor * randf(),
							"He":0.003 * big_planet_factor * randf(),
						}
		elif depth == "mantle":
			var O = randf_range(1.5, 1.9)
			elements = {	"O":O,
							"Si":O * randf_range(3.9, 4),
							"Al":0.05 * randf(),
							"Fe":0.035 * randf(),
							"Na":0.025 * randf(),
							"H":0.01 * big_planet_factor * randf(),
							"C":0.01 * big_planet_factor * randf(),
							"Ti":0.005 * randf(),
							"He":0.003 * big_planet_factor * randf(),
						}
		else:
			var x:float = randf_range(1, 10) * FM
			var y:float = randf_range(0, 5) * FM
			elements["Fe"] = x/(x+1)
			elements["Ni"] = (1 - Helper.get_sum_of_dict(elements)) * y/(y+1)
			elements["O"] = (1 - Helper.get_sum_of_dict(elements)) * randf_range(0, 0.19)
			elements["Si"] = elements["O"] * randf_range(3.9, 4)
			elements.Ta = 0.05 * randf()
			elements.W = 0.05 * randf()
			elements.Os = 0.025 * randf()
			elements.Ti = 0.01 * randf()
	else:
		if depth == "crust":
			return {}
		if depth == "mantle":
			elements["H"] = randf()
			elements["N"] = (1 - Helper.get_sum_of_dict(elements)) * randf()
			elements["He"] = (1 - Helper.get_sum_of_dict(elements)) * randf()
			elements["C"] = (1 - Helper.get_sum_of_dict(elements)) * randf()
			var r = 1 - Helper.get_sum_of_dict(elements)
			elements.Al = r * 0.05 * randf()
			elements.Fe = r * 0.035 * FM * randf()
			elements.Na = r * 0.025 * randf()
			elements.Mg = r * 0.02 * randf()
			elements.Ti = r * 0.005 * randf()
			elements.H = r * 0.002 * randf()
	for el in elements:
		if u_i.cluster_data[c_c].rich_elements.has(el):
			elements[el] *= u_i.cluster_data[c_c].rich_elements[el]
	var S = Helper.get_sum_of_dict(elements)
	for el in elements:
		elements[el] /= S
	return elements

func add_surface_materials(temp:float, crust_comp:Dictionary):#Amount in kg
	#temp in K
	var surface_mat_info = {	"coal":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":randf_range(50, 150)},
								"glass":{"chance":0.1, "amount":4},
								"sand":{"chance":0.8, "amount":50},
								"soil":{"chance":randf_range(0.1, 0.8), "amount":randf_range(30, 100)},
								"cellulose":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":randf_range(15, 45)}
	}
	if abs(temp - 273) > 80:
		surface_mat_info.erase("cellulose")
		surface_mat_info.erase("coal")
	surface_mat_info.sand.chance = pow(crust_comp.Si + crust_comp.O, 0.1) if crust_comp.has_all(["Si", "O"]) else 0.0
	var sand_glass_ratio:float = clamp(atan(0.01 * (temp + 273 - 1500)) * 1.05 / PI + 0.5, 0, 1)
	surface_mat_info.glass.chance = surface_mat_info.sand.chance * sand_glass_ratio
	surface_mat_info.sand.chance *= (1 - sand_glass_ratio)
	if sand_glass_ratio == 0:
		surface_mat_info.erase("glass")
	elif sand_glass_ratio == 1:
		surface_mat_info.erase("sand")
	for mat in surface_mat_info:
		surface_mat_info[mat].chance = Helper.clever_round(surface_mat_info[mat].chance)
		surface_mat_info[mat].amount = Helper.clever_round(surface_mat_info[mat].amount)
	return surface_mat_info

func show_tooltip(txt:String, params:Dictionary = {}):
	if is_instance_valid(tooltip):
		tooltip.queue_free()
	tooltip = preload("res://Scenes/Tooltip.tscn").instantiate()
	tooltip.modulate.a = 0.0
	$Tooltips.add_child(tooltip)
	tooltip.orig_text = txt
	tooltip.imgs = params.get("imgs", [])
	tooltip.imgs_size = params.get("size", 17)
	Helper.add_text_icons(tooltip, txt, tooltip.imgs, tooltip.imgs_size, true)
	if params.get("additional_text", "") != "":
		tooltip.show_additional_text(params.additional_text, params.get("additional_text_delay", 1.5), params.get("different_orig_text", ""))

func hide_tooltip():
	if is_instance_valid(tooltip):
		tooltip.visible = false

func add_items(item_id:int, num:int = 1):
	var cycles = 0
	while num > 0 and cycles < 2:
		for i in len(items):
			if num <= 0:
				break
			if items[i] == null:
				items[i] = {"id":item_id, "num":0}
			if items[i].id == item_id and items[i].num < stack_size:
				var sum = items[i].num + num
				var diff = stack_size - items[i].num
				items[i].num = min(stack_size, sum)
				num = max(num - diff, 0)
		cycles += 1
	return num

func remove_items(item_id:int, num:int = 1):
	if get_item_num(item_id) == 0:
		return 0
	while num > 0:
		for item_slot in items:
			if item_slot != null and item_slot.id == item_id:
				item_slot.num -= num
				if item_slot.num <= 0:
					num = -item_slot.num
					items[items.find(item_slot)] = null
				else:
					return get_item_num(item_id)
	return get_item_num(item_id)

func get_item_num(item_id:int):
	var n = 0
	for item_slot in items:
		if item_slot and item_slot.id == item_id:
			n += item_slot.num
	return n

func use_item(item_id:int, send_to_rover:int = -1):
	hide_tooltip()
	var num:int
	if Input.is_action_pressed("shift"):
		num = get_item_num(item_id)
	else:
		num = 1
	if send_to_rover != -1:
		var rover_has_inv_space:bool = false
		var rover = rover_data[send_to_rover]
		for i in len(rover.inventory):
			if rover.inventory[i].has("id") and rover.inventory[i].id == item_id:
				rover.inventory[i].num += num
				rover_has_inv_space = true
				break
			if not rover.inventory[i].has("id"):
				rover.inventory[i].type = "consumable"
				rover.inventory[i].id = item_id
				rover.inventory[i].num = num
				rover_has_inv_space = true
				break
		if rover_has_inv_space:
			remove_items(item_id, num)
			toggle_panel("vehicle_panel")
			vehicle_panel._on_rovers_pressed()
			popup(tr("ITEMS_SENT_TO_ROVER"), 2.0)
		else:
			popup(tr("ROVERS_INV_FULL"), 2.0)
		return
	if $UI/BottomInfo.visible:
		_on_BottomInfo_close_button_pressed(true)
	item_to_use.id = item_id
	item_to_use.num = num
	var item_type:int = Item.data[item_id].type
	if item_type == Item.Type.MINING_LIQUID:
		remove_items(item_id)
		pickaxe.liquid_id = item_id
		pickaxe.liquid_durability = Item.data[item_id].durability
		if active_panel == inventory:
			toggle_panel("inventory")
		popup("SUCCESSFULLY_APPLIED", 1.5)
		return
	elif item_type == Item.Type.DRILL:
		put_bottom_info(tr("CLICK_ON_ROVER_TO_GIVE"), "give_rover_items", "hide_item_cursor")
		toggle_panel("vehicle_panel")
	elif item_type == Item.Type.OVERCLOCK:
		put_bottom_info(tr("USE_OVERCLOCK_INFO"), "use_overclock", "hide_item_cursor")
	elif item_type == Item.Type.HELIX_CORE:
		if len(ship_data) > 0:
			put_bottom_info(tr("CLICK_SHIP_TO_GIVE_XP"), "use_hx_core", "hide_item_cursor")
			toggle_panel("ships_panel")
			ships_panel.get_node("Ships/Battlefield/Selected").hide()
			ships_panel.get_node("ShipStats/ShipDetails").hide()
			ships_panel.get_node("ShipStats/Label").show()
			ships_panel.get_node("ShipStats/Label").text = tr("CLICK_SHIP_TO_GIVE_XP")
		else:
			popup(tr("NO_SHIPS_2"), 1.5)
			return
	if active_panel == inventory:
		toggle_panel("inventory")
	show_item_cursor(load("res://Graphics/Items/%s/%s.png" % [Item.icon_directory(item_type), Item.data[item_id].icon_name]))

func get_star_class (temp):
	var cl = ""
	if temp < 600:
		cl = "Y" + str(int(10 - (temp - 250) / 350 * 10))
	elif temp < 1400:
		cl = "T" + str(int(10 - (temp - 600) / 800 * 10))
	elif temp < 2400:
		cl = "L" + str(int(10 - (temp - 1400) / 1000 * 10))
	elif temp < 3700:
		cl = "M" + str(int(10 - (temp - 2400) / 1300 * 10))
	elif temp < 5200:
		cl = "K" + str(int(10 - (temp - 3700) / 1500 * 10))
	elif temp < 6000:
		cl = "G" + str(int(10 - (temp - 5200) / 800 * 10))
	elif temp < 7500:
		cl = "F" + str(int(10 - (temp - 6000) / 1500 * 10))
	elif temp < 10000:
		cl = "A" + str(int(10 - (temp - 7500) / 2500 * 10))
	elif temp < 30000:
		cl = "B" + str(int(10 - (temp - 10000) / 20000 * 10))
	elif temp < 70000:
		cl = "O" + str(int(10 - (temp - 30000) / 40000 * 10))
	elif temp < 120000:
		cl = "Q" + str(int(10 - (temp - 70000) / 50000 * 10))
	elif temp < 210000:
		cl = "R" + str(int(10 - (temp - 120000) / 90000 * 10))
	elif temp < 1000000:
		cl = "Z" + str(max(int(10 - (temp - 210000) / 790000 * 10), 0))
	else:
		cl = "Z0"
	return cl

#Checks if player has enough resources to buy/craft/build something
func check_enough(costs):
	var enough = true
	for cost in costs:
		if cost == "money" and money < costs[cost]:
			return false
		if cost == "energy" and energy < costs[cost]:
			return false
		if cost == "SP" and SP < costs[cost]:
			return false
		if mats.has(cost) and mats[cost] < costs[cost]:
			return false
		if mets.has(cost) and mets[cost] < costs[cost]:
			return false
		if atoms.has(cost) and atoms[cost] < costs[cost]:
			return false
		if cost == "stone" and Helper.get_sum_of_dict(stone) < costs.stone:
			return false
	return true

func deduct_resources(costs):
	for cost in costs:
		if cost == "money":
			money -= costs.money
		elif cost == "energy":
			energy -= costs.energy
		elif cost == "SP":
			SP -= costs.SP
		elif cost == "stone":
			var ratio:float = 1 - costs.stone / float(Helper.get_sum_of_dict(stone))
			for el in stone:
				stone[el] *= ratio
		elif mats.has(cost):
			mats[cost] = max(0, mats[cost] - costs[cost])
		elif mets.has(cost):
			mets[cost] = max(0, mets[cost] - costs[cost])
		elif atoms.has(cost):
			atoms[cost] = max(0, atoms[cost] - costs[cost])
		elif particles.has(cost):
			particles[cost] = max(0, particles[cost] - costs[cost])

func add_resources(costs):
	for cost in costs:
		if cost == "money":
			money += costs.money
			stats_global.total_money_earned += costs.money
			stats_dim.total_money_earned += costs.money
			stats_univ.total_money_earned += costs.money
		elif cost == "energy":
			Helper.add_energy(costs.energy)
		elif cost == "SP":
			SP += costs.SP
		elif cost == "stone":
			for comp in costs.stone:
				Helper.add_to_dict(stone, comp, costs.stone[comp])
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
		if not show.has(cost):
			show[cost] = true
			if cost == "sand":
				new_bldgs[Building.GLASS_FACTORY] = true
			elif cost == "coal":
				new_bldgs[Building.STEAM_ENGINE] = true
			elif cost == "stone":
				new_bldgs[Building.STONE_CRUSHER] = true

func e(n, e):
	return n * pow(10, e)

var quadrant_top_left:PackedVector2Array = [Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]
var quadrant_top_right:PackedVector2Array = [Vector2(640, 0), Vector2(1280, 0), Vector2(1280, 360), Vector2(640, 360)]
var quadrant_bottom_left:PackedVector2Array = [Vector2(0, 360), Vector2(640, 360), Vector2(640, 720), Vector2(0, 720)]
var quadrant_bottom_right:PackedVector2Array = [Vector2(640, 360), Vector2(1280, 360), Vector2(1280, 720), Vector2(640, 720)]
@onready var fps_text = $Tooltips/FPS
var last_process_time = Time.get_unix_time_from_system()

func _process(_delta):
	if _delta == 0:
		return
	if DisplayServer.window_is_focused(0):
		Engine.max_fps = Settings.max_fps
	else:
		Engine.max_fps = 8
	var delta = (Time.get_unix_time_from_system() - last_process_time)
	last_process_time = Time.get_unix_time_from_system()
	fps_text.text = "%s FPS" % [Engine.get_frames_per_second()]
	if autocollect:
		var min_mult:float = pow(maths_bonus.IRM, infinite_research.MEE) * u_i.time_speed
		var energy_mult:float = pow(maths_bonus.IRM, infinite_research.EPE) * u_i.time_speed
		var SP_mult:float = pow(maths_bonus.IRM, infinite_research.RLE) * u_i.time_speed
		var min_to_add:float = delta * (autocollect.MS.minerals + autocollect.GS.minerals + autocollect.rsrc.minerals) * min_mult
		var energy_to_add = delta * (autocollect.MS.energy + autocollect.GS.energy + autocollect.rsrc.energy) * energy_mult
		SP += delta * (autocollect.MS.SP + autocollect.GS.SP) * SP_mult
		SP += autocollect.rsrc.SP * delta * SP_mult
		if mats.cellulose > 0:
			if not autocollect.mats.has("soil") or is_zero_approx(autocollect.mats.soil) or mats.soil > 0:
				for mat in autocollect.mats:
					if mat == "minerals":
						min_to_add += autocollect.mats[mat] * delta
					else:
						mats[mat] += autocollect.mats[mat] * delta
				for met in autocollect.mets:
					mets[met] += autocollect.mets[met] * delta
		else:
			mats.cellulose = 0
		if mats.soil < 0:
			mats.soil = 0
		if autocollect.has("atoms"):
			for atom in autocollect.atoms:
				atoms[atom] += autocollect.atoms[atom] * delta
		Helper.add_minerals(min_to_add)
		Helper.add_energy(energy_to_add)
		if is_instance_valid(HUD) and is_ancestor_of(HUD):
			HUD.update_minerals()
			HUD.update_money_energy_SP()

var mouse_pos = Vector2.ZERO
@onready var item_cursor = $Tooltips/ItemCursor

func sell_all_minerals():
	if minerals > 0:
		add_resources({"money":minerals * (MUs.MV + 4)})
		popup(tr("MINERAL_SOLD") % [Helper.format_num(round(minerals)), Helper.format_num(round(minerals * (MUs.MV + 4)))], 2)
		minerals = 0
		HUD.update_money_energy_SP()
		HUD.update_minerals()

var cmd_history:Array = []
var cmd_history_index:int = -1
var sub_panel

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if not stats_global.is_empty() and c_u != -1:
			stats_global.mouse_travel_distance += event.relative.length()
			stats_dim.mouse_travel_distance += event.relative.length()
			stats_univ.mouse_travel_distance += event.relative.length()
		$Tooltips/CtrlShift.position = mouse_pos - Vector2(87, 17)
	elif event is InputEventKey:
		if event.is_pressed() and not stats_global.is_empty() and c_u != -1:
			stats_global.keyboard_presses += 1
			stats_dim.keyboard_presses += 1
			stats_univ.keyboard_presses += 1
		$Tooltips/CtrlShift/Ctrl.visible = Input.is_action_pressed("ctrl")
		$Tooltips/CtrlShift/Shift.visible = Input.is_action_pressed("shift")
		$Tooltips/CtrlShift/Alt.visible = Input.is_action_pressed("alt")
	elif event is InputEventMouseButton and not stats_global.is_empty() and c_u != -1:
		if Input.is_action_just_pressed("left_click"):
			stats_global.clicks += 1
			stats_dim.clicks += 1
			stats_univ.clicks += 1
		if Input.is_action_just_pressed("right_click"):
			stats_global.right_clicks += 1
			stats_dim.right_clicks += 1
			stats_univ.right_clicks += 1
			if is_instance_valid(tooltip):
				tooltip.get_node("AnimationPlayer").play("Fade")
		elif Input.is_action_just_released("right_click"):
			if is_instance_valid(tooltip):
				tooltip.get_node("AnimationPlayer").play_backwards("Fade")
		if Input.is_action_just_pressed("scroll"):
			stats_global.scrolls += 1
			stats_dim.scrolls += 1
			stats_univ.scrolls += 1
	if is_instance_valid(stats_panel) and stats_panel.visible and stats_panel.get_node("Statistics").visible and stats_panel.curr_stat_tab == "_on_UserInput_pressed":
		stats_panel._on_UserInput_pressed()
	if is_instance_valid(tooltip):
		tooltip.set_tooltip_position()
	if item_cursor.visible:
		item_cursor.position = mouse_pos

	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		Settings.fullscreen = not Settings.fullscreen
		get_window().mode = Window.MODE_FULLSCREEN if Settings.fullscreen else Window.MODE_WINDOWED
		var config = ConfigFile.new()
		var err = config.load("user://settings.cfg")
		if err == OK:
			config.set_value("graphics", "fullscreen", Settings.fullscreen)
			config.save("user://settings.cfg")
		if is_instance_valid(settings_panel):
			settings_panel.get_node("TabContainer/GRAPHICS/Fullscreen").set_pressed_no_signal(Settings.fullscreen)

	if Input.is_action_just_released("cancel"):
		if item_cursor.visible and c_v not in ["STM", ""]:
			item_to_use.num = 0
			update_item_cursor()
		if bottom_info_action == "":
			if is_instance_valid(sub_panel):
				sub_panel.visible = false
				sub_panel = null
				view.move_view = true
				view.scroll_view = true
			elif is_instance_valid(active_panel):
				fade_out_panel(active_panel)
			active_panel = null
		hide_tooltip()
	
	#F3 to toggle overlay
	if Input.is_action_just_pressed("toggle"):
		if is_instance_valid(overlay) and not overlay.visible:
			overlay.toggle_btn.button_pressed = not overlay.toggle_btn.button_pressed
		elif c_v == "system" and not element_overlay.visible:
			element_overlay.toggle_btn.button_pressed = not element_overlay.toggle_btn.button_pressed
		
	#J to hide help
	if Input.is_action_just_released("J") and help_str != "":
		if help.has(help_str):
			help.erase(help_str)
		else:
			help[help_str] = true
		hide_tooltip()
		$UI/Panel/AnimationPlayer.play("FadeOut")
		if $UI.has_node("BuildingShortcuts"):
			$UI.get_node("BuildingShortcuts").queue_free()
	
	#/ to type a command
	if Input.is_action_just_released("command") and not cmd_node.visible and c_v != "":
		cmd_node.visible = true
		cmd_node.text = "/"
		cmd_node.call_deferred("grab_focus")
		cmd_node.caret_column = 1
	
	if Input.is_action_just_released("cancel"):
		hide_tooltip()
		cmd_node.visible = false
	
	if Input.is_action_just_released("up") and len(cmd_history) > 0 and cmd_node.visible:
		if cmd_history_index < len(cmd_history) - 1:
			cmd_history_index += 1
		cmd_node.text = cmd_history[cmd_history_index]
		cmd_node.caret_column = cmd_node.text.length()
	
	if Input.is_action_just_released("down") and len(cmd_history) > 0 and cmd_node.visible:
		if cmd_history_index > 0:
			cmd_history_index -= 1
		else:
			cmd_history_index = 0
		cmd_node.text = cmd_history[cmd_history_index]
		cmd_node.caret_column = cmd_node.text.length()
	
	if Input.is_action_just_pressed("S") and Input.is_action_pressed("ctrl"):
		if c_v != "":
			fn_save_game()
			save_views(false)

func _unhandled_key_input(event):
	var hotbar_presses = [Input.is_action_just_released("1"), Input.is_action_just_released("2"), Input.is_action_just_released("3"), Input.is_action_just_released("4"), Input.is_action_just_released("5"), Input.is_action_just_released("6"), Input.is_action_just_released("7"), Input.is_action_just_released("8"), Input.is_action_just_released("9"), Input.is_action_just_released("0")]
	if not c_v in ["battle", "cave", ""] and not viewing_dimension and not is_instance_valid(overlay):
		for i in 10:
			if len(hotbar) > i and hotbar_presses[i]:
				var _name = hotbar[i]
				if get_item_num(_name) > 0:
					inventory.on_slot_press(_name)

func fn_save_game():
	save_date = Time.get_unix_time_from_system()
	var save_info:Dictionary = {
		"save_created":save_created,
		"save_modified":save_date,
		"help":help,
		"c_u":c_u,
		"universe_data":universe_data,
		"version":VERSION,
		"DRs":DRs,
		"dim_num":dim_num,
		"subject_levels":subject_levels,
		"maths_bonus":maths_bonus,
		"physics_bonus":physics_bonus,
		"chemistry_bonus":chemistry_bonus,
		"biology_bonus":biology_bonus,
		"engineering_bonus":engineering_bonus,
		"stats_global":stats_global,
		"stats_dim":stats_dim,
		"achievement_data":achievement_data,
	}
	var save_info_file = FileAccess.open("user://%s/save_info.hx3~" % [c_sv], FileAccess.WRITE)
	save_info_file.store_var(save_info)
	save_info_file.close()
	if c_u == -1:
		return
	var save_game_dict = {
		"money":money,
		"minerals":minerals,
		"mineral_capacity":mineral_capacity,
		"energy_capacity":energy_capacity,
		"capacity_bonus_from_substation":capacity_bonus_from_substation,
		"stone":stone,
		"energy":energy,
		"SP":SP,
		"c_v":c_v,
		"l_v":l_v,
		"c_c":c_c,
		"c_g":c_g,
		"c_g_g":c_g_g,
		"c_s":c_s,
		"c_s_g":c_s_g,
		"c_p":c_p,
		"c_p_g":c_p_g,
		"c_t":c_t,
		"stack_size":stack_size,
		"auto_replace":auto_replace,
		"pickaxe":pickaxe,
		"science_unlocked":science_unlocked,
		"infinite_research":infinite_research,
		"mats":mats,
		"mets":mets,
		"atoms":atoms,
		"particles":particles,
		"show":show,
		"new_bldgs":new_bldgs,
		"items":items,
		"hotbar":hotbar,
		"MUs":MUs,
		"STM_lv":STM_lv,
		"rover_id":rover_id,
		"rover_data":rover_data,
		"fighter_data":fighter_data,
		"probe_data":probe_data,
		"ship_data":ship_data,
		"ships_travel_data":ships_travel_data,
		"planets_generated":planets_generated,
		"systems_generated":systems_generated,
		"galaxies_generated":galaxies_generated,
		"clusters_generated":clusters_generated,
		"stats_univ":stats_univ,
		#"objective":objective,
		"autocollect":autocollect,
		"save_date":save_date,
		"bookmarks":bookmarks,
		"ancient_bldgs_discovered":ancient_bldgs_discovered,
		"ancient_building_counters":ancient_building_counters,
		"cave_filters":cave_filters,
		"caves_generated":caves_generated,
		"boring_machine_data":boring_machine_data,
	}
	var save_game = FileAccess.open("user://%s/Univ%s/main.hx3~" % [c_sv, c_u], FileAccess.WRITE)
	save_game.store_var(save_game_dict)
	save_game.close()
	if c_v == "cave" and is_instance_valid(cave):
		cave.save_cave_data()
	DirAccess.copy_absolute("user://%s/save_info.hx3~" % [c_sv], "user://%s/save_info.hx3" % [c_sv])
	DirAccess.copy_absolute("user://%s/Univ%s/main.hx3~" % [c_sv, c_u], "user://%s/Univ%s/main.hx3" % [c_sv, c_u])

func save_views(autosave:bool):
	if is_instance_valid(view.obj) and is_ancestor_of(view.obj):
		view.save_zooms(c_v)
	if c_v in ["planet", "mining"]:
		Helper.save_obj("Planets", c_p_g, tile_data)
		Helper.save_obj("Systems", c_s_g, planet_data)
	elif c_v == "system":
		Helper.save_obj("Systems", c_s_g, planet_data)
		Helper.save_obj("Galaxies", c_g_g, system_data)
	elif c_v == "galaxy":
		if is_instance_valid(send_probes_panel) and send_probes_panel.is_processing() or is_instance_valid(send_fighters_panel) and send_fighters_panel.is_processing():
			Helper.save_obj("Galaxies", c_g_g, system_data)
		Helper.save_obj("Clusters", c_c, galaxy_data)
	elif c_v == "cluster":
		Helper.save_obj("Clusters", c_c, galaxy_data)
	if not autosave:
		popup(tr("GAME_SAVED"), 1.2)

func show_item_cursor(texture):
	item_cursor.get_node("Sprite2D").texture = texture
	item_cursor.get_node("Num").text = "x " + str(item_to_use.num)
	#update_item_cursor()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	item_cursor.position = mouse_pos
	item_cursor.visible = true

func update_item_cursor():
	if item_to_use.num <= 0:
		_on_BottomInfo_close_button_pressed()
		item_to_use.id = -1
		item_to_use.num = 0
	else:
		item_cursor.get_node("Num").text = "x " + str(item_to_use.num)
	if is_instance_valid(HUD):
		HUD.update_hotbar()

func hide_item_cursor():
	item_to_use.id = -1
	item_to_use.num = 0
	item_cursor.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func cancel_building():
	view.obj.finish_construct()
	help_str = ""
	HUD.get_node("Top/Resources/Glass").visible = false
	HUD.get_node("Top/Resources/Soil").visible = false
	HUD.get_node("Top/Resources/Stone").visible = show.has("stone")
	HUD.get_node("Top/Resources/SP").visible = show.has("SP")
	HUD.get_node("Top/Resources/Minerals").visible = show.has("minerals")
	HUD.get_node("Top/Resources/Cellulose").visible = science_unlocked.has("SA")
	for id in bldg_blueprints:
		tiles[id]._on_Button_button_out()

func cancel_building_MS():
	$UI/Panel/AnimationPlayer.play("FadeOut")
	view.obj.finish_construct()

func _on_Settings_mouse_entered():
	show_tooltip(tr("SETTINGS") + " (P)")

func _on_Settings_mouse_exited():
	hide_tooltip()

func _on_Settings_pressed():
	$click.play()
	toggle_panel("settings_panel")

func _on_BottomInfo_close_button_pressed(direct:bool = false):
	close_button_over = false
	if bottom_info_shown:
		bottom_info_shown = false
		hide_tooltip()
		if $UI/BottomInfo/CloseButton.on_close != "":
			call($UI/BottomInfo/CloseButton.on_close)
		$UI/BottomInfo/CloseButton.on_close = ""
		bottom_info_action = ""
		if not get_tree().get_nodes_in_group("gray_tiles").is_empty():
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(get_tree().get_first_node_in_group("gray_tiles").material, "shader_parameter/amount", 0.0, 0.2)
			for gray_tile in get_tree().get_nodes_in_group("gray_tiles"):
				tween.tween_callback(gray_tile.queue_free).set_delay(0.15)
				gray_tile.remove_from_group("gray_tiles")
		HUD.refresh()
		if not direct:
			$UI/BottomInfo/MoveAnim.play_backwards("MoveLabel")
			await $UI/BottomInfo/MoveAnim.animation_finished
		if not bottom_info_shown:
			$UI/BottomInfo.visible = false

func cancel_place_soil():
	HUD.get_node("Top/Resources/Soil").visible = false

#Used in planet view only
var close_button_over:bool = false

func _on_CloseButton_close_button_over():
	close_button_over = true

func _on_CloseButton_close_button_out():
	close_button_over = false

func fade_out_title(fn:String):
	$Title/Menu/VBoxContainer/NewGame.disconnect("pressed",Callable(self,"_on_NewGame_pressed"))
	$Title/Menu/VBoxContainer/Continue.disconnect("pressed",Callable(self,"_on_continue_pressed"))
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($Title, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_property($TitleBackground, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_property($Star/Sprite2D.material, "shader_parameter/brightness_offset", 0.0, 0.5)
	tween.tween_property($Star, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_property($Star/Sprite2D.material, "shader_parameter/alpha", 0.0, 0.5)
	await tween.finished
	$Star.visible = false
	$Title.visible = false
	$Settings/Settings.visible = true
	HUD = preload("res://Scenes/HUD.tscn").instantiate()
	HUD.hide()
	if fn == "new_game":
		if DRs > 0:
			switch_music(null)
			viewing_dimension = true
			set_default_dim_bonuses()
			add_dimension()
			dimension.refresh_univs(true)
		else:
			new_game(0, true)
			switch_music(Data.ambient_music.pick_random(), u_i.time_speed)
	else:
		call(fn)
		#add_panels()
		$Autosave.start()
		switch_music(Data.ambient_music.pick_random(), u_i.get("time_speed", 1.0))
	
func _on_NewGame_pressed():
	if Settings.op_cursor and Input.is_action_pressed("ctrl"):
		settings_panel._on_OPCursor_toggled(false)
		var popup_input = preload("res://Scenes/PopupInput.tscn").instantiate()
		popup_input.label_text = "Enter the number of DRs to start the game with:"
		popup_input.check_input = func(x): return int(x) >= 0
		popup_input.error_text = "Input must be 0 or greater"
		$UI.add_child(popup_input)
		popup_input.connect("confirm", Callable(self, "fade_out_title").bind("new_game"))
		var set_vars = func():
			c_u = -1
			DRs = int(popup_input.input.text)
			help = Data.default_help.duplicate()
			help.erase("hide_dimension_stuff")
		popup_input.connect("confirm", set_vars)
	else:
		fade_out_title("new_game")

func _on_LoadGame_pressed():
	toggle_panel("load_save_panel")

func _on_Autosave_timeout():
	if Settings.enable_autosave:
		fn_save_game()
		if not viewing_dimension:
			save_views(true)

func show_YN_panel(type:String, text:String = tr("ARE_YOU_SURE"), args:Array = []):
	if $Panels.has_node("YN_panel"):
		$Panels.get_node("YN_panel").free()
	var YN_panel = preload("res://Scenes/PopupWindow.tscn").instantiate()
	YN_panel.set_text(text)
	YN_panel.set_OK_text(tr("NO"))
	YN_panel.name = "YN_panel"
	if args.is_empty():
		YN_panel.add_button(tr("YES"), Callable(self,"%s_confirm" % type))
	else:
		YN_panel.add_button(tr("YES"), Callable(self,"%s_confirm" % type).bindv(args))
	$Panels.add_child(YN_panel)
	#if type in ["buy_pickaxe", "destroy_building", "destroy_buildings", "op_galaxy", "conquer_all", "destroy_tri_probe", "reset_dimension"]:

func upgrade_ship_weapon_confirm(path: int):
	ship_customize_screen.upgrade_ship_weapon(path)

func destroy_rover_confirm(rover_destroy_callable: Callable):
	rover_destroy_callable.call()

func terraform_planet_confirm():
	terraform_panel.terraform_planet()

func delete_save_confirm(save_str):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	var saved_c_sv = ""
	if err == OK:
		saved_c_sv = config.get_value("game", "saved_c_sv", "")
	if saved_c_sv == save_str:
		$Title/Menu/VBoxContainer/Continue.visible = false
		$Title/Menu.size.y = 0.0
		config.set_value("game", "saved_c_sv", "")
		config.save("user://settings.cfg")
	load_save_panel.on_delete_confirm(save_str)

func return_to_menu_confirm():
	$Ship.visible = false
	$Autosave.stop()
	await switch_view("")
	c_v = ""
	$Title/Menu/VBoxContainer/Continue.connect("pressed",Callable(self,"_on_continue_pressed"))
	refresh_continue_button()
	switch_music(preload("res://Audio/Title.ogg"))
	HUD.queue_free()
	var tween = create_tween()
	tween.tween_property($Star/Sprite2D.material, "shader_parameter/alpha", 1.0, 1.0)
	$Title/Menu/VBoxContainer/NewGame.connect("pressed",Callable(self,"_on_NewGame_pressed"))
	$Title.visible = true
	$Star.visible = true
	animate_title_buttons()
	universe_data.clear()
	view.queue_redraw()
	dim_num = 1

func generate_new_univ_confirm():
	universe_data.append({"id":0, "lv":1, "xp":0, "xp_to_lv":10, "shapes":[], "name":tr("UNIVERSE"), "cluster_num":1000, "view":{"pos":Vector2(640 * 0.5, 360 * 0.5), "zoom":2, "sc_mult":0.1}})
	universe_data[0].speed_of_light = 1.0#e(3.0, 8)#m/s
	universe_data[0].planck = 1.0#e(6.626, -34)#J.s
	universe_data[0].boltzmann = 1.0#e(1.381, -23)#J/K
	universe_data[0].gravitational = 1.0#e(6.674, -11)#m^3/kg/s^2
	universe_data[0].charge = 1.0#e(1.602, -19)#C
	universe_data[0].dark_energy = 1.0
	universe_data[0].age = 1.0
	universe_data[0].difficulty = 1.0
	universe_data[0].time_speed = 1.0
	universe_data[0].antimatter = 0.0
	dimension.set_bonuses()
	Data.MUs.MV.pw = maths_bonus.MUCGF_MV
	Data.MUs.MSMB.pw = maths_bonus.MUCGF_MSMB
	for el in PD_panel.bonuses.keys():
		chemistry_bonus[el] = PD_panel.bonuses[el]
	dimension.refresh_univs()

func destroy_tri_probe_confirm(probe_id:int):
	probe_data.remove_at(probe_id)
	vehicle_panel.probe_over_id = -1
	vehicle_panel.refresh()

func discover_univ_confirm():
	send_probes_panel.discover_univ()

func reset_dimension_confirm(DR_num:int):
	c_u = -1
	DRs += DR_num
	for i in len(universe_data):
		Helper.remove_recursive("user://%s/Univ%s" % [c_sv, i])
	if not achievement_data.progression.has("new_dimension"):
		earn_achievement("progression", "new_dimension")
	universe_data.clear()
	help.erase("hide_dimension_stuff")
	dim_num += 1
	if not help.has("DR_reset"):
		dimension.get_node("ColorRect").visible = true
		switch_music(null)
	else:
		dimension.refresh_univs(true)
	stats_dim = Data.default_stats.duplicate(true)
	fn_save_game()

func buy_pickaxe_confirm(_costs:Dictionary):
	shop_panel.buy_pickaxe(_costs)

func destroy_buildings_confirm(tile_ids:Array):
	if tile_data[tile_ids[0]].bldg.name == Building.GREENHOUSE:
		view.obj.get_node("TileFeatures").clear_layer(2)
	for id in tile_ids:
		view.obj.destroy_bldg(id, true)
	show_collect_info(view.obj.items_collected)
	HUD.refresh()

func destroy_building_confirm(tile_over:int):
	view.obj.destroy_bldg(tile_over)
	show_collect_info(view.obj.items_collected)
	HUD.refresh()

func send_ships_confirm():
	send_ships_panel.send_ships()

func op_galaxy_confirm(l_id:int, g_id:int):
	switch_view("galaxy", {"fn":"set_custom_coords", "fn_args":[["c_g", "c_g_g"], [l_id, g_id]]})

func conquer_all_confirm(energy_cost:float, insta_conquer:bool):
	if energy >= energy_cost:
		energy -= energy_cost
		if insta_conquer:
			for planet in planet_data:
				if not planet.has("conquered"):
					planet.conquered = true
					planet.erase("HX_data")
					stats_univ.planets_conquered += 1
					stats_dim.planets_conquered += 1
					stats_global.planets_conquered += 1
			stats_univ.systems_conquered += 1
			stats_dim.systems_conquered += 1
			stats_global.systems_conquered += 1
			if not new_bldgs.has(Building.SOLAR_PANEL):
				new_bldgs[Building.SOLAR_PANEL] = true
			system_data[c_s].conquered = true
			view.obj.refresh_planets()
			space_HUD.get_node("ConquerAll").visible = false
		else:
			is_conquering_all = true
			c_p = ships_travel_data.c_coords.p
			switch_view("battle")
	else:
		popup(tr("NOT_ENOUGH_ENERGY"), 2.0)

func show_collect_info(info:Dictionary):
	if info.has("stone") and Helper.get_sum_of_dict(info.stone) == 0:
		info.erase("stone")
	if info.is_empty():
		return
	add_resources(info)
	var info2:Dictionary = info.duplicate(true)
	if info2.has("stone"):
		info2.stone = Helper.get_sum_of_dict(info2.stone)
	Helper.put_rsrc($UI/Panel/VBox, 32, info2)
	Helper.add_label(tr("YOU_COLLECTED"), 0)
	$UI/Panel.visible = true
	$UI/Panel/AnimationPlayer.play("Fade")
	$CollectPanelTimer.start(min(2.5, 0.5 + 0.3 * $UI/Panel/VBox.get_child_count()))
	$CollectPanelAnim.stop()

func _on_CollectPanelTimer_timeout():
	$CollectPanelAnim.play("Fade")

func _on_CollectPanelAnim_animation_finished(anim_name):
	$UI/Panel.visible = false

func _on_Ship_pressed():
	if Input.is_action_pressed("shift"):
		switch_view("STM")#Ship travel minigame
	else:
		if science_unlocked.has("CD"):
			if not is_instance_valid(ships_panel) or not ships_panel.visible:
				toggle_panel("ships_panel")
				ships_panel._on_DriveButton_pressed()

func _on_Ship_mouse_entered():
	show_tooltip("%s: %s\n%s" % [tr("TIME_LEFT"), Helper.time_to_str(ships_travel_data.travel_length - Time.get_unix_time_from_system() + ships_travel_data.travel_start_date), tr("PLAY_SHIP_MINIGAME")])

func _on_mouse_exited():
	hide_tooltip()

func mine_tile(tile_id:int = -1):
	if pickaxe.has("name"):
		if shop_panel.visible:
			toggle_panel("shop_panel")
		if tile_id == -1:
			put_bottom_info(tr("START_MINE"), "about_to_mine")
			view.obj.place_gray_tiles_mining()
		else:
			c_t = tile_id
			switch_view("mining")
	else:
		popup_window(tr("NO_PICKAXE"), tr("NO_PICKAXE_TITLE"), [tr("BUY_ONE")], [Callable(self, "open_shop_pickaxe")], tr("LATER"))

func game_fade(fn, args:Array = []):
	game_tween = create_tween()
	game_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	await game_tween.finished
	if fn is Array:
		for i in len(fn):
			callv(fn[i], args[i])
	else:
		callv(fn, args)
	game_tween = create_tween()
	game_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func add_new_ship_data():
	ship_data.append({
		"lv": 1,
		"HP": 15,
		"attack": 11,
		"defense": 11,
		"accuracy": 11,
		"agility": 11,
		"XP": 0,
		"XP_to_lv": Constants.base_ship_XP_to_lv,
		"bullet": [1, 1, 1],
		"laser": [1, 1, 1],
		"bomb": [1, 1, 1],
		"light": [1, 1, 1],
		"respec_count": 0,
		"allocated_HP":0,
		"allocated_attack":0,
		"allocated_defense":0,
		"allocated_accuracy":0,
		"allocated_agility":0,
		"ship_class":ShipClass.STANDARD,
	})
	if len(ship_data) == 1:
		ship_data[-1].initial_position = Vector2(230, 158)
	elif len(ship_data) == 2:
		ship_data[-1].initial_position = Vector2(576, 158)
	elif len(ship_data) == 3:
		ship_data[-1].initial_position = Vector2(230, 389)
	elif len(ship_data) == 4:
		ship_data[-1].initial_position = Vector2(576, 389)

func get_1st_ship():
	add_new_ship_data()
	switch_view("ship_customize_screen", {"ship_id":0, "respeccing":true, "label_text":tr("CUSTOMIZE_NEW_SHIP")})

func get_2nd_ship():
	if len(ship_data) == 1:
		add_new_ship_data()
		Helper.add_ship_XP(1, 300)
		if not achievement_data.progression.has("2nd_ship"):
			earn_achievement("progression", "2nd_ship")
		switch_view("ship_customize_screen", {"ship_id":1, "respeccing":true, "label_text":tr("CUSTOMIZE_NEW_SHIP")})

func get_3rd_ship():
	if len(ship_data) == 2:
		add_new_ship_data()
		Helper.add_ship_XP(2, 15000)
		if not achievement_data.progression.has("3rd_ship"):
			earn_achievement("progression", "3rd_ship")
		switch_view("ship_customize_screen", {"ship_id":2, "respeccing":true, "label_text":tr("CUSTOMIZE_NEW_SHIP")})

func get_4th_ship():
	if len(ship_data) == 3:
		popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
		add_new_ship_data()
		Helper.add_ship_XP(3, 250000)
		if not achievement_data.progression.has("4th_ship"):
			earn_achievement("progression", "4th_ship")
		switch_view("ship_customize_screen", {"ship_id":3, "respeccing":true, "label_text":tr("CUSTOMIZE_NEW_SHIP")})

func earn_achievement(type:String, ach_id:String):
	var ach = preload("res://Scenes/AchievementEarned.tscn").instantiate()
	ach.get_node("Panel/Type").text = type.capitalize()
	ach.get_node("Panel/Desc").text = achievements[type.to_lower()][ach_id]
	ach.get_node("Panel/TextureRect").texture = stats_panel.get_node("Achievements/ScrollContainer/HBox/Slots/%s/%s" % [type, ach_id]).achievement_icon
	achievement_data[type][ach_id] = true
	ach.add_to_group("achievement_nodes")
	$UI.add_child(ach)
	ach.get_node("AnimationPlayer").connect("animation_finished",Callable(self,"on_ach_anim_finished").bind(ach))
	await get_tree().create_timer(0.8 * len(get_tree().get_nodes_in_group("achievement_nodes"))).timeout
	ach.get_node("AnimationPlayer").play("FadeInOut")

func on_ach_anim_finished(anin_name:String, node):
	node.remove_from_group("achievement_nodes")
	node.queue_free()

func refresh_achievements():
	for i in len(achievements.money):
		if not achievement_data.money.has(str(i)):
			if money >= pow(10, (i+1) * 3):
				earn_achievement("money", str(i))
	if not achievement_data.conquest.has("0"):
		if stats_global.planets_conquered >= 2:
			earn_achievement("conquest", "0")
	for i in range(1, 7):
		if not achievement_data.conquest.has(str(i)):
			if stats_global.planets_conquered >= pow(10, i):
				earn_achievement("conquest", str(i))
	if not achievement_data.conquest.has("fully_conquer_system"):
		if stats_global.systems_conquered >= 1:
			earn_achievement("conquest", "fully_conquer_system")
	if not achievement_data.conquest.has("fully_conquer_galaxy"):
		if stats_global.galaxies_conquered >= 1:
			earn_achievement("conquest", "fully_conquer_galaxy")
	if not achievement_data.conquest.has("fully_conquer_cluster"):
		if stats_global.clusters_conquered >= 1:
			earn_achievement("conquest", "fully_conquer_cluster")
	for i in len(achievements.construct):
		if not achievement_data.construct.has(str(i)):
			if stats_global.bldgs_built >= pow(10, (i+1) * 2):
				earn_achievement("construct", str(i))


func _on_StarFade_animation_finished(anim_name):
	if $Stars/WhiteStars.modulate.a <= 0:
		$Stars/WhiteStars.visible = false

func _on_Mods_pressed():
	$click.play()
	fade_in_panel("mods")


func _on_Discord_pressed():
	OS.shell_open("https://discord.com/invite/gDHcDA3")


func _on_GitHub_pressed():
	OS.shell_open("https://github.com/Apple0726/helixteus-3")


func _on_Godot_pressed():
	OS.shell_open("https://godotengine.org/")


func _on_Discord_mouse_entered():
	show_tooltip(tr("DISCORD_BUTTON"))


func _on_GitHub_mouse_entered():
	show_tooltip(tr("GITHUB_BUTTON"))


func _on_Godot_mouse_entered():
	show_tooltip(tr("GODOT_BUTTON"))

var curr_MM_p = 0

func _on_MMTimer_timeout():
	if is_instance_valid(HUD) and is_ancestor_of(HUD):
		var curr_time = Time.get_unix_time_from_system()
		var planets_with_MM:Array = boring_machine_data.keys()
		if len(planets_with_MM) == 0:
			$MMTimer.start()
			return
		if curr_MM_p > len(planets_with_MM)-1:
			curr_MM_p = 0
		var p = planets_with_MM[curr_MM_p]
		if boring_machine_data[p].has("tiles"):
			var p_i = open_obj("Systems", boring_machine_data[p].c_s_g)[boring_machine_data[p].c_p]
			var _tile_data
			if p == c_p_g:
				_tile_data = tile_data
			else:
				_tile_data = open_obj("Planets", p)
			if len(_tile_data) == 0:
				curr_MM_p += 1
				$MMTimer.start()
				return
			var await_counter:int = 0
			for t_id in boring_machine_data[p].tiles:
				var tile = _tile_data[t_id]
				if tile == null or not tile.has("bldg"):
					continue
				var prod_mult = Helper.get_prod_mult(tile) * tile.get("mining_outpost_bonus", 1.0)
				var tiles_mined = (curr_time - tile.bldg.collect_date) * tile.bldg.path_1_value * prod_mult
				if tiles_mined >= 1:
					add_resources(Helper.mass_generate_rock(tile, p_i, int(tiles_mined)))
					tile.bldg.collect_date += int(tiles_mined) / tile.bldg.path_1_value / prod_mult
					tile.depth += int(tiles_mined)
					if tile.has("crater") and tile.crater.has("init_depth") and tile.depth > 3 * tile.crater.init_depth:
						Helper.remove_crater_bonuses(_tile_data, t_id, tile.crater.metal)
						tile.erase("crater")
				await_counter += 1
				if await_counter % int(1000.0 / Engine.get_frames_per_second()) == 0:
					await get_tree().process_frame
			if p != c_p_g:
				Helper.save_obj("Planets", p, _tile_data)
		else:
			var _planet_data:Array
			var p_i:Dictionary
			if boring_machine_data[p].c_s_g == c_s_g:
				p_i = planet_data[boring_machine_data[p].c_p]
			else:
				_planet_data = open_obj("Systems", boring_machine_data[p].c_s_g)
				if _planet_data.is_empty():
					boring_machine_data.erase(p)
					$MMTimer.start()
					return
				p_i = _planet_data[boring_machine_data[p].c_p]
			var prod_mult = Helper.get_prod_mult(p_i) * p_i.get("mining_outpost_bonus", 1.0)
			var tiles_mined = (curr_time - p_i.bldg.collect_date) * p_i.bldg.path_1_value * prod_mult
			if tiles_mined >= 1:
				var rsrc_mined = Helper.mass_generate_rock(p_i, p_i, int(tiles_mined))
				for rsrc in rsrc_mined.keys():
					if rsrc == "stone":
						for el in rsrc_mined[rsrc].keys():
							rsrc_mined[rsrc][el] *= p_i.tile_num
					else:
						rsrc_mined[rsrc] *= p_i.tile_num
				add_resources(rsrc_mined)
				p_i.bldg.collect_date += int(tiles_mined) / p_i.bldg.path_1_value / prod_mult
				p_i.depth += int(tiles_mined)
			if boring_machine_data[p].c_s_g != c_s_g:
				Helper.save_obj("Systems", boring_machine_data[p].c_s_g, _planet_data)
		curr_MM_p += 1
		if is_instance_valid(HUD):
			HUD.update_money_energy_SP()
	$MMTimer.start()


func _on_PanelAnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		$UI/Panel.visible = false


func _on_command_text_submitted(new_text):
	cmd_node.visible = false
	cmd_history_index = -1
	var arr:Array = new_text.substr(1).to_lower().split(" ")
	var cmd:String = arr[0]
	var fail:bool = false
	match cmd:
		"setmoney":
			money = float(arr[1])
		"setstone":
			stone = {"Si":float(arr[1])}
		"setmin":
			minerals = float(arr[1])
		"setmincap":
			mineral_capacity = float(arr[1])
		"setenergy":
			energy = float(arr[1])
		"setenergycap":
			energy_capacity = float(arr[1])
		"setsp":
			SP = float(arr[1])
		"setmat":
			if mats.has(arr[1].to_lower()):
				mats[arr[1].to_lower()] = float(arr[2])
			else:
				popup("No such material", 1.5)
				return
		"setmet":
			if mets.has(arr[1].to_lower()):
				mets[arr[1].to_lower()] = float(arr[2])
			else:
				popup("No such metal", 1.5)
				return
		"setatom":
			if atoms.has(arr[1].capitalize()):
				atoms[arr[1].capitalize()] = float(arr[2])
			else:
				popup("No such atom", 1.5)
				return
		"setpart":
			if particles.has(arr[1].to_lower()):
				particles[arr[1].to_lower()] = float(arr[2])
			else:
				popup("No such particle", 1.5)
				return
		"speedup":
			if c_v == "planet":
				for tile in tile_data:
					if tile and tile.has("wormhole") and tile.wormhole.has("investigation_length"):
						tile.wormhole.investigation_length = 1
			for probe in probe_data:
				if probe and probe.has("start_date"):
					var diff_time = probe.start_date + probe.explore_length - Time.get_unix_time_from_system()
					probe.start_date -= diff_time
					probe.explore_length = 1
		"setmulv":
			MUs[arr[1].to_upper()] = int(arr[2])
		"setlv":
			universe_data[c_u].lv = int(arr[1])
		"switchview":
			if c_v == "cave":
				cave.exit_cave()
			else:
				switch_view(arr[1])
		"setunivprop":
			if universe_data[c_u].has(arr[1]):
				universe_data[c_u][arr[1]] = float(arr[2])
			else:
				popup("Universes do not have a property called \"%s\"" % arr[1], 2.5)
				return
		"get2ndship":
			get_2nd_ship()
		"get3rdship":
			get_3rd_ship()
		"get4thship":
			get_4th_ship()
		"addshipxp":#addshipxp 0 lv 10
			Helper.add_ship_XP(int(arr[1]), float(arr[2]))
		"unlockbldgs":
			for i in len(Building.names):
				new_bldgs[i] = true
		_:
			fail = true
	if not fail:
		popup("Command executed", 1.5)
	else:
		popup("Command \"%s\" does not exist" % [cmd], 2)
	cmd_history.push_front(new_text)
	HUD.refresh()


func _on_continue_pressed():
	c_sv = refresh_continue_button()
	if c_sv != "":
		fade_out_title("load_game")

func add_right_click_menu(items:Array, on_close_no_action_callable = null):
	var menu = load("res://Scenes/RightClickMenu.tscn").instantiate()
	menu.items = items
	menu.position = mouse_pos
	if on_close_no_action_callable:
		menu.on_close_no_action.connect(on_close_no_action_callable)
	hide_tooltip()
	$Panels/Control.add_child(menu)
	return menu
