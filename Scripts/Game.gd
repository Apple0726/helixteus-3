extends Node2D

const TEST:bool = false
const VERSION:String = "v0.25.4"
const SYS_NUM:int = 400

var generic_panel_scene = preload("res://Scenes/Panels/GenericPanel.tscn")
var upgrade_panel_scene = preload("res://Scenes/Panels/UpgradePanel.tscn")
var planet_HUD_scene = preload("res://Scenes/Planet/PlanetHUD.tscn")
var space_HUD_scene = preload("res://Scenes/SpaceHUD.tscn")
var planet_details_scene = preload("res://Scenes/Planet/PlanetDetails.tscn")
var mining_HUD_scene = preload("res://Scenes/Views/Mining.tscn")
var science_tree_scene = preload("res://Scenes/Views/ScienceTree.tscn")
var overlay_scene = preload("res://Scenes/Overlay.tscn")
var element_overlay_scene = preload("res://Scenes/ElementOverlay.tscn")
var annotator_scene = preload("res://Scenes/Annotator.tscn")
var rsrc_scene = preload("res://Scenes/Resource.tscn")
var rsrc_stored_scene = preload("res://Scenes/ResourceStored.tscn")
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
var wormhole_scene = preload("res://Scenes/Wormhole.tscn")
var surface_BG = preload("res://Graphics/Decoratives/Surface.jpg")
var crust_BG = preload("res://Graphics/Decoratives/Crust.jpg")
var star_texture = preload("res://Graphics/Effects/spotlight_8_s.png")
var star_shader = preload("res://Shaders/Star.shader")
var planet_textures:Array
var galaxy_textures:Array
var bldg_textures:Dictionary
var default_font:Font

var tutorial:Node2D

var construct_panel:Control
var megastructures_panel:Control
var gigastructures_panel:Control
var shop_panel:Control
var ship_panel:Control
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
var greenhouse_panel:Panel
var shipyard_panel:Panel
var PC_panel:Panel
var AMN_panel:Control
var SPR_panel:Control
var planetkiller_panel:Control
var inventory:Control
var settings:Control
var dimension:Control
var planet_details:Control
var overlay:Control
var element_overlay:Control
var annotator:Control
var mods:Control
var wiki:Panel
var stats_panel:Panel
var load_panel:Panel
var tooltip
onready var YN_panel:ConfirmationDialog = $UI/ConfirmationDialog

const SYSTEM_SCALE_DIV = 100.0
const GALAXY_SCALE_DIV = 750.0
const CLUSTER_SCALE_DIV = 1600.0
const SC_SCALE_DIV = 400.0
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

############ Save data ############

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
var neutron_cap:float
var electron_cap:float
#Dimension remnants
var DRs:float
var dim_num:int = 1
var subjects:Dictionary
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

#Stores production values boosted by an aurora (useful to recalculate resource production after buying AIE upgrade)
var aurora_prod:Dictionary = {}

#Display help when players see/do things for the first time. true: show help
var help:Dictionary = {}

var science_unlocked:Dictionary
var infinite_research:Dictionary
var MUs:Dictionary#Levels of mineral upgrades
#Measures to not overwhelm beginners. false: not visible
var show:Dictionary

#Used to notify the player with an icon when new buildings are unlocked
var new_bldgs:Dictionary = {}

#Stores information of all objects discovered
var universe_data:Array
var galaxy_data:Array# = [{"id":0, "l_id":0, "type":0, "modulate":Color.white, "name":"Milky Way", "pos":Vector2.ZERO, "rotation":0, "diff":1, "B_strength":e(5, -10), "dark_matter":1.0, "discovered":false, "conquered":false, "parent":0, "system_num":SYS_NUM, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(15000 + 1280, 15000 + 720), "zoom":0.5}}]
var system_data:Array
var planet_data:Array
var tile_data:Array
var caves_generated:int

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

var hotbar:Array

var STM_lv:int#ship travel minigame level
var rover_id:int#Rover id when in cave

var p_num:int
var s_num:int
var g_num:int#Total number of galaxies generated
var c_num:int

var stats_univ:Dictionary
var stats_dim:Dictionary
var stats_global:Dictionary

enum ObjectiveType {BUILD, UPGRADE, MINERAL_UPG, SAVE, MINE, CONQUER, CRUST, CAVE, LEVEL, WORMHOLE, SIGNAL, DAVID, COLLECT_PARTS, MANIPULATORS, EMMA, TERRAFORM}
enum ClusterType {GROUP, CLUSTER}
var objective:Dictionary# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}

var autocollect:Dictionary
var save_date:int
var bookmarks:Dictionary
var unique_bldgs_discovered:Dictionary

############ End save data ############
var block_scroll:bool = false
var overlay_CS:float = 0.5
var overlay_data = {	"galaxy":{"overlay":0, "visible":false, "custom_values":[{"left":2, "right":30, "modified":false}, {"left":1, "right":5, "modified":false}, null, null, null, {"left":0.5, "right":15, "modified":false}, {"left":250, "right":100000, "modified":false}, {"left":1, "right":1, "modified":false}, {"left":1, "right":1, "modified":false}, null]},
						"cluster":{"overlay":0, "visible":false, "custom_values":[{"left":200, "right":10000, "modified":false}, null, null, null, {"left":1, "right":100, "modified":false}, {"left":0.2, "right":5, "modified":false}, {"left":0.8, "right":1.2, "modified":false}, null]},
}
var c_sv:String = ""#current_save
var save_created
var u_i:Dictionary
var view_history:Array = []
var view_history_pos:int = -1

#Stores data of the item that you clicked in your inventory
var item_to_use = {"name":"", "type":"", "num":0}

var mining_HUD
var science_tree_view = {"pos":Vector2.ZERO, "zoom":1.0}
var cave
var ruins
var STM
var battle
var is_conquering_all:bool = false

var cave_filters = {
	"money":false,
	"minerals":false,
	"stone":false,
}

# Stores the locations of all boring machines the player has built
# to make autocollecting metals possible while minimizing lag
var MM_data = {
	
}

var mat_info = {	"coal":{"value":15},#One kg of coal = $10
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

var speedups_info = {	"speedup1":{"costs":{"money":400}, "time":2*60000, "name":"X_MINUTE_SPEEDUP", "name_param":2},
						"speedup2":{"costs":{"money":2800}, "time":15*60000, "name":"X_MINUTE_SPEEDUP", "name_param":15},
						"speedup3":{"costs":{"money":11000}, "time":60*60000, "name":"X_HOUR_SPEEDUP", "name_param":1},
						"speedup4":{"costs":{"money":65000}, "time":6*60*60000, "name":"X_HOUR_SPEEDUP", "name_param":6},
						"speedup5":{"costs":{"money":255000}, "time":24*60*60000, "name":"X_HOUR_SPEEDUP", "name_param":24},
						"speedup6":{"costs":{"money":1750000}, "time":7*24*60*60000, "name":"X_DAY_SPEEDUP", "name_param":7},
}

var overclocks_info = {	"overclock1":{"costs":{"money":2800}, "mult":1.5, "duration":10*60000},
						"overclock2":{"costs":{"money":17000}, "mult":2, "duration":30*60000},
						"overclock3":{"costs":{"money":90000}, "mult":2.5, "duration":60*60000},
						"overclock4":{"costs":{"money":340000}, "mult":3, "duration":2*60*60000},
						"overclock5":{"costs":{"money":2200000}, "mult":4, "duration":6*60*60000},
						"overclock6":{"costs":{"money":18000000}, "mult":5, "duration":24*60*60000},
}

var seeds_produce = {"lead_seeds":{"costs":{"cellulose":0.05}, "produce":{"lead":0.1}},
					"copper_seeds":{"costs":{"cellulose":0.06}, "produce":{"copper":0.1*met_info.lead.value / met_info.copper.value}},
					"iron_seeds":{"costs":{"cellulose":0.07}, "produce":{"iron":0.1*met_info.lead.value / met_info.iron.value}},
					"aluminium_seeds":{"costs":{"cellulose":0.08}, "produce":{"aluminium":0.1*met_info.lead.value / met_info.aluminium.value}},
					"silver_seeds":{"costs":{"cellulose":0.09}, "produce":{"silver":0.1*met_info.lead.value / met_info.silver.value}},
					"gold_seeds":{"costs":{"cellulose":0.1}, "produce":{"gold":0.1*met_info.lead.value / met_info.gold.value}},
}
var craft_mining_info = {	"mining_liquid":{"costs":{"coal":200, "glass":20}, "speed_mult":1.5, "durability":400},
							"purple_mining_liquid":{"costs":{"H":4000, "O":2000, "glass":500}, "speed_mult":4.0, "durability":800},
}

var craft_cave_info = {
	"drill1":{"costs":{"iron":100, "aluminium":20}, "limit":8},
	"drill2":{"costs":{"aluminium":600, "titanium":150}, "limit":16},
	"drill3":{"costs":{"platinum":4000, "diamond":3000}, "limit":24},
	"portable_wormhole1":{"costs":{"glass":80, "aluminium":80}, "limit":8},
	"portable_wormhole2":{"costs":{"quartz":300, "diamond":20}, "limit":16},
	"portable_wormhole3":{"costs":{"platinum":5000, "quillite":1000}, "limit":24},
}

var other_items_info = {
	"hx_core":{"XP":6},
	"hx_core2":{"XP":800},
	"hx_core3":{"XP":120000},
	"hx_core4":{"XP":1.6e7},
	"ship_locator":{}}

var item_groups = [	{"dict":speedups_info, "path":"Items/Speedups"},
					{"dict":overclocks_info, "path":"Items/Overclocks"},
					{"dict":other_items_info, "path":"Items/Others"},
					]
#Density is in g/cm^3
var element = {	"Si":{"density":2.329},
				"O":{"density":1.429}}

var achievement_data:Dictionary = {}
var achievements:Dictionary = {
	"money":{
		"0":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(1000, false, 308), "rsrc":tr("MONEY")}),
		"1":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 6), false, 308), "rsrc":tr("MONEY")}),
		"2":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 9), false, 308), "rsrc":tr("MONEY")}),
		"3":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 12), false, 308), "rsrc":tr("MONEY")}),
		"4":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 15), false, 308), "rsrc":tr("MONEY")}),
		"5":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 18), false, 308), "rsrc":tr("MONEY")}),
		"6":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 21), false, 308), "rsrc":tr("MONEY")}),
		"7":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 24), false, 308), "rsrc":tr("MONEY")}),
		"8":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 27), false, 308), "rsrc":tr("MONEY")}),
		"9":tr("SAVE_OBJECTIVE").format({"num":Helper.format_num(e(1, 30), false, 308), "rsrc":tr("MONEY")}),
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
		"tier_2_unique_bldg":tr("FIND_TIER_X_UNIQUE_BLDG") % 2,
		"tier_3_unique_bldg":tr("FIND_TIER_X_UNIQUE_BLDG") % 3,
		"tier_4_unique_bldg":tr("FIND_TIER_X_UNIQUE_BLDG") % 4,
		"tier_5_unique_bldg":tr("FIND_TIER_X_UNIQUE_BLDG") % 5,
		"find_all_unique_bldgs":tr("FIND_ALL_UNIQUE_BLDGS"),
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

#Holds information of the tooltip that can be hidden by the player by pressing F7
var help_str:String
var bottom_info_action:String = ""
#Settings
var pitch_affected:bool = false
var autosave_interval:int = 10
var autosell:bool = true
var enable_shaders:bool = true
var screen_shake:bool = true
var cave_gen_info:bool = false
var op_cursor:bool = false

var music_player = AudioStreamPlayer.new()

var dialog:AcceptDialog
var metal_textures:Dictionary = {}
var game_tween:Tween
var b_i_tween:Tween#bottom_info_tween
var view_tween:Tween
var tooltip_tween:Tween
var stars_tween:Tween
var tile_brightness:Array = []
var tile_avg_mod:Array = []

func place_BG_stars():#shown in title screen and planet view
	for i in 500:
		var star:Sprite = Sprite.new()
		star.texture = star_texture
		star.scale *= 0.15
		star.modulate = Helper.get_star_modulate("%s%s" % [["M", "K", "G", "F", "A", "B", "O"][randi() % 7], randi() % 10])
		star.rotation = rand_range(0, 2*PI)
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		$Stars/Stars.add_child(star)
	for i in 50:
		var star:Sprite = Sprite.new()
		star.texture = star_texture
		star.scale *= 0.25
		star.modulate = Helper.get_star_modulate("%s%s" % [["M", "K", "G", "F", "A", "B", "O"][randi() % 7], randi() % 10])
		star.rotation = rand_range(0, 2*PI)
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		star.material = ShaderMaterial.new()
		star.material.shader = star_shader
		star.material.set_shader_param("brightness_offset", 1.5)
		star.material.set_shader_param("time_offset", 10.0 * randf())
		$Stars/Stars.add_child(star)

func place_BG_sc_stars():#shown in (super)cluster view
	for i in 2000:
		var star:Sprite = Sprite.new()
		star.texture = preload("res://Graphics/Misc/STMBullet.png")
		star.scale *= 0.05
		star.modulate.a = rand_range(0.2, 0.3)
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		$Stars/WhiteStars.add_child(star)
	for i in 100:
		var star:Sprite = Sprite.new()
		star.texture = preload("res://Graphics/Misc/STMBullet.png")
		star.scale *= 0.07
		star.modulate.a = 0.4
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		$Stars/WhiteStars.add_child(star)

var current_viewport_dimensions:Vector2
func update_viewport_dimensions():
	if settings.get_node("TabContainer/GRAPHICS/DisplayRes").selected != 0:
		get_viewport().size = current_viewport_dimensions
	
func _ready():
	current_viewport_dimensions = get_viewport().size
	get_viewport().connect("size_changed", self, "update_viewport_dimensions")
	for key in Mods.added_mats:
		mat_info[key] = Mods.added_mats[key]
	for key in Mods.added_mets:
		met_info[key] = Mods.added_mets[key]
	for key in Mods.added_picks:
		pickaxes_info[key] = Mods.added_picks[key]
	for key in Mods.added_speedups:
		speedups_info[key] = Mods.added_speedups[key]
	for key in Mods.added_overclocks:
		overclocks_info[key] = Mods.added_overclocks[key]
	
	place_BG_stars()
	place_BG_sc_stars()
	default_font = preload("res://Resources/default_theme.tres").default_font
	$UI/Version.text = "Alpha %s: %s" % [VERSION, "21 Dec 2022"]
	for i in range(3, 13):
		planet_textures.append(load("res://Graphics/Planets/%s.png" % i))
		if i <= 10:
			var tile_texture = load("res://Graphics/Tiles/%s.jpg" % i)
			var tile_img:Image = tile_texture.get_data()
			tile_img.lock()
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
	for bldg in Data.costs:
		var dir_str = "res://Graphics/Buildings/%s.png" % bldg
		if ResourceLoader.exists(dir_str):
			bldg_textures[bldg] = load(dir_str)
	for bldg in Data.unique_bldg_icons:
		var dir_str = "res://Graphics/Buildings/Unique/%s.png" % bldg
		if ResourceLoader.exists(dir_str):
			bldg_textures[bldg] = load(dir_str)
	game_tween = Tween.new()
	add_child(game_tween)
	b_i_tween = Tween.new()#bottom_info_tween
	add_child(b_i_tween)
	view_tween = Tween.new()
	add_child(view_tween)
	tooltip_tween = Tween.new()
	add_child(tooltip_tween)
	stars_tween = Tween.new()
	add_child(stars_tween)
	for metal in met_info:
		metal_textures[metal] = load("res://Graphics/Metals/%s.png" % [metal])
	if not TranslationServer.get_locale() in ["de", "zh", "es", "ja", "nl", "hu"]:
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
		$Title/Languages.change_language()
		OS.vsync_enabled = config.get_value("graphics", "vsync", true)
		pitch_affected = config.get_value("audio", "pitch_affected", true)
		enable_shaders = config.get_value("graphics", "enable_shaders", true)
		screen_shake = config.get_value("graphics", "screen_shake", true)
		$Autosave.wait_time = config.get_value("saving", "autosave", 10)
		autosave_interval = 10
		if OS.get_name() == "HTML5" and not config.get_value("misc", "HTML5", false):
			long_popup("You're playing the browser version of Helixteus 3. While it's convenient, it has\nmany issues not present in the executables:\n\n - High RAM usage, especially on Firefox\n - Less FPS\n - Import/export save feature does not work\n - Audio glitches\n - Saving delay (5-10 seconds)", "Browser version", [], [], "I understand")
			config.set_value("misc", "HTML5", true)
		autosell = config.get_value("game", "autosell", true)
		cave_gen_info = config.get_value("game", "cave_gen_info", false)
		op_cursor = config.get_value("misc", "op_cursor", false)
		if op_cursor:
			Input.set_custom_mouse_cursor(preload("res://Cursor.png"))
		var notation:String =  config.get_value("game", "notation", "SI")
		if notation == "standard":
			Helper.notation = 0
		elif notation == "SI":
			Helper.notation = 1
		else:
			Helper.notation = 2
		config.save("user://settings.cfg")
	Data.reload()
	settings = load("res://Scenes/Panels/Settings.tscn").instance()
	settings.visible = false
	$Panels/Control.add_child(settings)
	load_panel = preload("res://Scenes/Panels/LoadPanel.tscn").instance()
	load_panel.visible = false
	$Panels/Control.add_child(load_panel)
	mods = load("res://Scenes/Panels/Mods.tscn").instance()
	mods.visible = false
	$Panels/Control.add_child(mods)
	PD_panel = preload("res://Scenes/Panels/PDPanel.tscn").instance()
	PD_panel.visible = false
	$Panels/Control.add_child(PD_panel)
	animate_title_buttons()
	for mod in Mods.mod_list:
		var main = Mods.mod_list[mod]
		main.phase_2()

func animate_title_buttons():
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	$TitleBackground.modulate.a = 0.0
	$Title.modulate.a = 0.0
	$Title/Menu.modulate.a = 0.0
	$Title/Menu.rect_position = Vector2(83, 464)
	tween.tween_property($TitleBackground, "modulate", Color.white, 1)
	tween.tween_property($Title, "modulate", Color.white, 1).set_delay(0.2)
	tween.tween_property($Stars/Stars/Sprite.material, "shader_param/brightness_offset", 2.0, 1.2).set_delay(0.5)
	tween.tween_property($Stars/Stars, "modulate", Color.white, 1.2)
	tween.tween_property($Title/Menu, "modulate", Color.white, 1).set_delay(0.5)
	tween.tween_property($Title/Menu, "rect_position", Vector2(103, 464), 1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT).set_delay(0.5)
	
func switch_music(src, pitch:float = 1.0):
	#Music fading
	var tween = $MusicTween
	if music_player.playing:
		tween.stop_all()
		tween.remove_all()
		tween.interpolate_property(music_player, "volume_db", null, -30, 1, Tween.TRANS_QUAD, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
	if not src:
		return
	music_player.stream = src
	music_player.pitch_scale = pitch * u_i.time_speed if u_i and pitch_affected else pitch
	music_player.play()
	tween.interpolate_property(music_player, "volume_db", -20, 0, 2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()

func load_univ():
	if is_instance_valid(RC_panel) and $Panels/Control.is_a_parent_of(RC_panel):
		RC_panel.queue_free()
	RC_panel = preload("res://Scenes/Panels/RCPanel.tscn").instance()
	RC_panel.visible = false
	$Panels/Control.add_child(RC_panel)
	view_history.clear()
	view_history_pos = -1
	var save_game = File.new()
	if save_game.file_exists("user://%s/Univ%s/main.hx3" % [c_sv, c_u]):
		save_game.open("user://%s/Univ%s/main.hx3" % [c_sv, c_u], File.READ)
		var save_game_dict:Dictionary = save_game.get_var()
		save_game.close()
		for key in save_game_dict:
			if key in self:
				self[key] = save_game_dict[key]
		for key in mat_info:
			if not mats.has(key):
				mats[key] = 0
		help.erase("flash_send_probe_btn")
		stats_univ = save_game_dict.get("stats_univ", Data.default_stats.duplicate(true))
		for stat in Data.default_stats:
			var val = Data.default_stats[stat]
			if not stats_univ.has(stat):
				if val is Dictionary:
					stats_univ[stat] = val.duplicate(true)
				else:
					stats_univ[stat] = val
		if save_game_dict.has("caves_generated"):
			caves_generated = save_game_dict.caves_generated
		capacity_bonus_from_substation = 0
		u_i = universe_data[c_u]
		if science_unlocked.has("CI"):
			stack_size = 32
		if science_unlocked.has("CI2"):
			stack_size = 64
		if science_unlocked.has("CI3"):
			stack_size = 128
		if not autocollect.empty():
			var time_elapsed = (OS.get_system_time_msecs() - save_date) / 1000.0
			if autocollect.has("ship_XP"):
				var xp_mult = Helper.get_spaceport_xp_mult(autocollect.ship_XP)
				for i in len(ship_data):
					Helper.add_ship_XP(i, xp_mult * pow(1.15, u_i.lv) * time_elapsed / (4.0 / autocollect.ship_XP))
					for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
						Helper.add_weapon_XP(i, weapon.to_lower(), xp_mult * pow(1.04, u_i.lv) / 16.0 * time_elapsed / (4.0 / autocollect.ship_XP))
			var min_mult:float = pow(maths_bonus.IRM, infinite_research.MEE)
			var energy_mult:float = pow(maths_bonus.IRM, infinite_research.EPE)
			var SP_mult:float = pow(maths_bonus.IRM, infinite_research.RLE)
			Helper.add_minerals(((autocollect.rsrc.minerals + autocollect.MS.minerals + autocollect.GS.minerals) * min_mult) * time_elapsed)
			energy += ((autocollect.rsrc.energy + autocollect.MS.energy + autocollect.GS.energy) * energy_mult) * time_elapsed
			SP += ((autocollect.rsrc.SP + autocollect.MS.SP + autocollect.GS.SP) * SP_mult) * time_elapsed
			var plant_time_elapsed = min(time_elapsed, mats.cellulose / abs(autocollect.mats.cellulose)) if not is_zero_approx(autocollect.mats.cellulose) else 0
			if autocollect.mats.has("soil") and not is_zero_approx(autocollect.mats.soil):
				plant_time_elapsed = min(plant_time_elapsed, mats.soil / abs(autocollect.mats.soil))
			for mat in autocollect.mats:
				if mat == "minerals":
					Helper.add_minerals(autocollect.mats[mat] * plant_time_elapsed)
				else:
					mats[mat] += autocollect.mats[mat] * plant_time_elapsed
			for met in autocollect.mets:
				mets[met] += autocollect.mets[met] * plant_time_elapsed
			for atom in autocollect.atoms:
				atoms[atom] += autocollect.atoms[atom] * time_elapsed
			if not autocollect.has("particles"):#Save migration
				autocollect.particles = {"proton":0, "neutron":0, "electron":0}
			particles.proton += autocollect.particles.proton * time_elapsed * u_i.time_speed
			particles.neutron += autocollect.particles.neutron * time_elapsed * u_i.time_speed
			particles.electron += autocollect.particles.electron * time_elapsed * u_i.time_speed
			if particles.neutron > neutron_cap:
				var diff:float = particles.neutron - neutron_cap
				var amount_decayed:float = diff * pow(0.5, time_elapsed * u_i.time_speed / 900.0) #900 seconds = 15 minutes
				particles.neutron -= diff - amount_decayed
				particles.proton += (diff - amount_decayed) / 2.0
				particles.electron += (diff - amount_decayed) / 2.0
		if c_v == "mining" or c_v == "cave":
			c_v = "planet"
		elif c_v == "science_tree":
			c_v = l_v
		elif c_v == "battle":
			c_v = "system"
		view.set_process(true)
		var file = Directory.new()
		if file.file_exists("user://%s/Univ%s/Systems/%s.hx3" % [c_sv, c_u, c_s_g]):
			planet_data = open_obj("Systems", c_s_g)
		if file.file_exists("user://%s/Univ%s/Galaxies/%s.hx3" % [c_sv, c_u, c_g_g]):
			system_data = open_obj("Galaxies", c_g_g)
		if file.file_exists("user://%s/Univ%s/Clusters/%s.hx3" % [c_sv, c_u, c_c]):
			galaxy_data = open_obj("Clusters", c_c)
		else:
			galaxy_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "modulate":Color.white, "name":tr("MILKY_WAY"), "pos":Vector2.ZERO, "rotation":0, "diff":u_i.difficulty, "B_strength":1e-9 * u_i.charge * u_i.dark_energy, "dark_matter":1.0, "parent":0, "system_num":400, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(7500 + 1280 * 2, 7500 + 720 * 2), "zoom":0.25}}]
			Helper.save_obj("Clusters", 0, galaxy_data)
	else:
		popup("load error", 1.5)

func load_game():
	var save_info = File.new()
	save_info.open("user://%s/save_info.hx3" % [c_sv], File.READ)
	var save_info_dict:Dictionary = save_info.get_var()
	save_info.close()
	save_created = save_info_dict.save_created
	help = save_info_dict.help
	c_u = save_info_dict.c_u
	universe_data = save_info_dict.universe_data
	DRs = save_info_dict.get("DRs", 0)
	dim_num = save_info_dict.get("dim_num", 1)
	subjects = save_info_dict.get("subjects", {"maths":{"DRs":0, "lv":0},
					"physics":{"DRs":0, "lv":0},
					"chemistry":{"DRs":0, "lv":0},
					"biology":{"DRs":0, "lv":0},
					"philosophy":{"DRs":0, "lv":0},
					"engineering":{"DRs":0, "lv":0},
					"dimensional_power":{"DRs":0, "lv":0},
		})
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
	Data.MUs.AIE.pw = maths_bonus.MUCGF_AIE
	physics_bonus = save_info_dict.physics_bonus
	if not physics_bonus.has("age"):
		physics_bonus.age = 15
	chemistry_bonus = save_info_dict.chemistry_bonus
	biology_bonus = save_info_dict.biology_bonus
	engineering_bonus = save_info_dict.engineering_bonus
	achievement_data = save_info_dict.get("achievement_data", {})
	if achievement_data.empty() or achievement_data.money is Array:#Save migration
		for ach in achievements:
			achievement_data[ach] = {}
	if not save_info_dict.version in ["v0.25", "v0.25.1", "v0.25.2", "v0.25.3", "v0.25.4"]:
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
		if not $UI.is_a_parent_of(HUD):
			$UI.add_child(HUD)

func remove_files(dir:Directory):
	dir.list_dir_begin(true)
	var file_name = dir.get_next()
	while file_name != "":
		dir.remove(file_name)
		file_name = dir.get_next()

func new_game(tut:bool, univ:int = 0, new_save:bool = false):
	view_history.clear()
	view_history_pos = -1
	var file = File.new()
	var dir = Directory.new()
	stats_univ = Data.default_stats.duplicate(true)
	if new_save:
		stats_global = stats_univ.duplicate(true)
		stats_dim = stats_univ.duplicate(true)
		var sv_id:int = 1
		c_sv = "Save1"
		while dir.open("user://%s" % c_sv) == OK:
			sv_id += 1
			c_sv = "Save%s" % sv_id
		dir.make_dir("user://%s" % c_sv)
		save_created = OS.get_system_time_msecs()
		DRs = 0
		dim_num = 1
		help = Data.default_help.duplicate()
		for ach in achievements:
			achievement_data[ach] = {}
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
		maths_bonus = {
			"BUCGF":1.3,
			"MUCGF_MV":1.9,
			"MUCGF_MSMB":1.6,
			"MUCGF_AIE":2.3,
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
		chemistry_bonus = {}
		biology_bonus = {
			"PGSM":1.0,
			"PYM":1.0,
			"H2O":1.0,
			"CH4":1.0,
			"CO2":1.0,
			"NH3":1.0,
			"H":0.0,
			"He":1.0,
			"O":1.0,
			"Ne":1.0,
			"Xe":0.0,
		}
		engineering_bonus = {
			"BCM":1.0,
			"PS":1.0,
			"RSM":1.0,
		}
		subjects = {"maths":{"DRs":0, "lv":0},
					"physics":{"DRs":0, "lv":0},
					"chemistry":{"DRs":0, "lv":0},
					"biology":{"DRs":0, "lv":0},
					"philosophy":{"DRs":0, "lv":0},
					"engineering":{"DRs":0, "lv":0},
					"dimensional_power":{"DRs":0, "lv":0}}
	else:
		universe_data[univ].generated = true
	u_i = universe_data[univ]
	dir.make_dir("user://%s/Univ%s" % [c_sv, univ])
	dir.make_dir("user://%s/Univ%s/Caves" % [c_sv, univ])
	dir.make_dir("user://%s/Univ%s/Planets" % [c_sv, univ])
	dir.make_dir("user://%s/Univ%s/Systems" % [c_sv, univ])
	dir.make_dir("user://%s/Univ%s/Galaxies" % [c_sv, univ])
	dir.make_dir("user://%s/Univ%s/Clusters" % [c_sv, univ])
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
	neutron_cap = 0
	electron_cap = 0
	science_unlocked = {}
	cave_filters = {
		"money":false,
		"minerals":false,
		"stone":false,
	}
	MM_data = {}
	aurora_prod = {}
	new_bldgs = {}

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

	particles = {	"proton":0,
					"neutron":0,
					"electron":0,
	}

	#Display help when players see/do things for the first time. true: show help

	MUs = {	"MV":1,
			"MSMB":1,
			"IS":1,
			"AIE":1,
			"STMB":1,
			"SHSR":1,
			"CHR":1,
	}#Levels of mineral upgrades

	#Measures to not overwhelm beginners. false: not visible
	show = {}
	new_bldgs = {"ME":true}
	if subjects.dimensional_power.lv >= 1:
		for mat in mat_info.keys():
			show[mat] = true
		for met in met_info.keys():
			show[met] = true
	if not tut:
		show.construct_button = true
	#Stores information of all objects discovered
	u_i.cluster_data = [{"id":0, "visible":true, "type":0, "shapes":[], "class":ClusterType.GROUP, "name":tr("LOCAL_GROUP"), "pos":Vector2.ZERO, "diff":u_i.difficulty, "FM":u_i.dark_energy, "parent":0, "galaxy_num":55, "galaxies":[], "view":{"pos":Vector2(640, 360), "zoom":1 / 4.0}, "rich_elements":{}}]
	galaxy_data = [{"id":0, "l_id":0, "type":0, "shapes":[], "modulate":Color.white, "name":tr("MILKY_WAY"), "pos":Vector2.ZERO, "rotation":0, "diff":u_i.difficulty, "B_strength":1e-9 * u_i.charge * u_i.dark_energy, "dark_matter":1.0, "parent":0, "system_num":400, "systems":[{"global":0, "local":0}], "view":{"pos":Vector2(7500, 7500) * 0.5 + Vector2(640, 360), "zoom":0.5}}]
	var s_b:float = pow(u_i.boltzmann, 4) / pow(u_i.planck, 3) / pow(u_i.speed_of_light, 2)
	system_data = [{"id":0, "l_id":0, "name":tr("SOLAR_SYSTEM"), "pos":Vector2(-7500, -7500), "diff":u_i.difficulty, "parent":0, "planet_num":7, "planets":[], "view":{"pos":Vector2(640, -100), "zoom":1}, "stars":[{"type":"main_sequence", "class":"G2", "size":1, "temperature":5500, "mass":u_i.planck, "luminosity":s_b, "pos":Vector2(0, 0)}]}]
	planet_data = []
	tile_data = []
	caves_generated = 0

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
							"emma_free":false,
							"artifact_found":false,
							"emma_joined":false,
							"ship_spotted":false,
	}
	ships_c_coords = {"c":0, "g":0, "s":0, "p":2}#Local coords of the planet that the ships are on
	ships_c_g_coords = {"c":0, "g":0, "s":0}#ship global coordinates (current)
	ships_dest_coords = {"c":0, "g":0, "s":0, "p":2}#Local coords of the destination planet
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

	objective = {}# = {"type":ObjectiveType.BUILD, "data":"PP", "current":0, "goal":0}
	autocollect = {
		"mats":{"cellulose":0},
		"mets":{},
		"atoms":{},
		"particles":{"proton":0, "neutron":0, "electron":0},
		"MS":{"minerals":0, "energy":0, "SP":0},
		"GS":{"minerals":0, "energy":0, "SP":0},
		"rsrc":{"minerals":0, "energy":0, "SP":0},
		"rsrc_list":{}}
	save_date = OS.get_system_time_msecs()
	generate_planets(0)
	if univ == 0:
		#Home planet information
		planet_data[2]["name"] = tr("HOME_PLANET")
		planet_data[2].type = 5
		planet_data[2]["conquered"] = true
		planet_data[2]["size"] = round(rand_range(12000, 12100))
		planet_data[2].view = {"pos":Vector2(340, 80), "zoom":3.0 / Helper.get_wid(planet_data[2].size)}
		stats_univ.biggest_planet = planet_data[2].size
		planet_data[2]["angle"] = PI / 2
		planet_data[2]["tiles"] = []
		planet_data[2].pressure = 1
		planet_data[2].lake_1 = {"element":"H2O"}
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
	unique_bldgs_discovered = {}
	Helper.save_obj("Systems", 0, planet_data)
	generate_tiles(2)
	
	c_v = "planet"
	Helper.save_obj("Galaxies", 0, system_data)
	Helper.save_obj("Clusters", 0, galaxy_data)
	fn_save_game()
	if not is_a_parent_of(HUD):
		$UI.add_child(HUD)
	HUD.refresh()
	if tut:
		tutorial = load("res://Scenes/Tutorial.tscn").instance()
		tutorial.visible = false
		tutorial.tut_num = 1
	add_planet()
	$Autosave.start()
	var init_time = OS.get_system_time_msecs()
	add_panels()
	view.modulate.a = 0
	view.first_zoom = true
	view.progress = 0
	view.zoom_factor = 1.03
	view.zooming = "in"
	view.set_process(true)
	if tut:
		$UI.add_child(tutorial)

func add_panels():
	upgrade_panel = upgrade_panel_scene.instance()
	inventory = preload("res://Scenes/Panels/Inventory.tscn").instance()
	shop_panel = generic_panel_scene.instance()
	shop_panel.set_script(load("Scripts/ShopPanel.gd"))
	ship_panel = preload("res://Scenes/Panels/ShipPanel.tscn").instance()
	construct_panel = generic_panel_scene.instance()
	construct_panel.set_script(load("Scripts/ConstructPanel.gd"))
	megastructures_panel = generic_panel_scene.instance()
	megastructures_panel.set_script(load("Scripts/MegastructuresPanel.gd"))
	gigastructures_panel = preload("res://Scenes/Panels/GigastructuresPanel.tscn").instance()
	craft_panel = generic_panel_scene.instance()
	craft_panel.set_script(load("Scripts/CraftPanel.gd"))
	vehicle_panel = preload("res://Scenes/Panels/VehiclePanel.tscn").instance()
	RC_panel = preload("res://Scenes/Panels/RCPanel.tscn").instance()
	MU_panel = preload("res://Scenes/Panels/MUPanel.tscn").instance()
	SC_panel = preload("res://Scenes/Panels/SCPanel.tscn").instance()
	production_panel = preload("res://Scenes/Panels/ProductionPanel.tscn").instance()
	send_ships_panel = preload("res://Scenes/Panels/SendShipsPanel.tscn").instance()
	send_fighters_panel = preload("res://Scenes/Panels/SendFightersPanel.tscn").instance()
	terraform_panel = preload("res://Scenes/Panels/TerraformPanel.tscn").instance()
	greenhouse_panel = preload("res://Scenes/Panels/GreenhousePanel.tscn").instance()
	shipyard_panel = preload("res://Scenes/Panels/ShipyardPanel.tscn").instance()
	PC_panel = preload("res://Scenes/Panels/PCPanel.tscn").instance()
	AMN_panel = preload("res://Scenes/Panels/ReactionsPanel.tscn").instance()
	AMN_panel.set_script(load("Scripts/AMNPanel.gd"))
	SPR_panel = preload("res://Scenes/Panels/ReactionsPanel.tscn").instance()
	SPR_panel.set_script(load("Scripts/SPRPanel.gd"))
	planetkiller_panel = preload("res://Scenes/Panels/PlanetkillerPanel.tscn").instance()
	wiki = preload("res://Scenes/Panels/Wiki.tscn").instance()
	stats_panel = preload("res://Scenes/Panels/StatsPanel.tscn").instance()
	
	send_probes_panel = preload("res://Scenes/Panels/SendProbesPanel.tscn").instance()
	send_probes_panel.visible = false
	$Panels/Control.add_child(send_probes_panel)
	
	wiki.visible = false
	$Panels/Control.add_child(wiki)
	
	stats_panel.visible = false
	$Panels/Control.add_child(stats_panel)
	
	planetkiller_panel.visible = false
	$Panels/Control.add_child(planetkiller_panel)
	
	AMN_panel.visible = false
	$Panels/Control.add_child(AMN_panel)
	
	SPR_panel.visible = false
	$Panels/Control.add_child(SPR_panel)
	
	send_ships_panel.visible = false
	$Panels/Control.add_child(send_ships_panel)
	
	send_fighters_panel.visible = false
	$Panels/Control.add_child(send_fighters_panel)
	
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

	gigastructures_panel.visible = false
	$Panels/Control.add_child(gigastructures_panel)

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

	upgrade_panel.visible = false
	$Panels/Control.add_child(upgrade_panel)
	
	element_overlay = element_overlay_scene.instance()
	element_overlay.visible = false
	$UI.add_child(element_overlay)

func popup(txt, dur):
	var node = $UI/Popup
	node.text = txt
	node.visible = true
	node.modulate.a = 0
	yield(get_tree(), "idle_frame")
	node.rect_size.x = 0
	var x_pos = 640 - node.rect_size.x / 2
	node.rect_position.x = x_pos
	var tween:Tween = node.get_node("Tween")
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(node, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.15)
	tween.interpolate_property(node, "rect_position", Vector2(x_pos, 83), Vector2(x_pos, 80), 0.15)
	tween.start()
	yield(get_tree().create_timer(dur), "timeout")
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
	dialog.theme = preload("res://Resources/default_theme.tres")
	dialog.popup_exclusive = true
	dialog.visible = false
	$UI.add_child(dialog)
	$UI/PopupBackground.visible = true
	dialog.window_title = title
	dialog.get_label().autowrap = true
	var width = min(800, default_font.get_string_size(txt).x) + 40
	dialog.rect_min_size.x = width
	dialog.rect_min_size.y = 0
	dialog.rect_size.y = 0
	dialog.rect_size.x = width
	dialog.dialog_text = txt
	dialog.visible = true
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
	shop_panel.get_node("VBox/Tabs/Pickaxes")._on_Button_pressed()

var bottom_info_shown:bool = false
func put_bottom_info(txt:String, action:String, on_close:String = ""):
	b_i_tween.stop_all()
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
	more_info.rect_size.x = 0#This "trick" lets us resize the label to fit the text
	more_info.rect_position.x = -more_info.get_minimum_size().x / 2.0
	more_info.modulate.a = 1
	bottom_info_action = action
	$UI/BottomInfo/CloseButton.on_close = on_close
	b_i_tween.interpolate_property($UI/BottomInfo, "rect_position", null, Vector2(0, 680), 0.5, Tween.TRANS_CIRC, Tween.EASE_OUT)
	b_i_tween.start()

func fade_in_panel(panel:Control):
	panel.visible = true
	$Panels/Control.move_child(panel, $Panels/Control.get_child_count())
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 1), 0.1)
	var s = panel.rect_size
	panel.tween.interpolate_property(panel, "rect_position", Vector2(-s.x / 2.0, -s.y / 2.0 + 20), Vector2(-s.x / 2.0, -s.y / 2.0), 0.3, Tween.TRANS_BACK, Tween.EASE_OUT)
	panel.tween.interpolate_property($Panels/Blur.material, "shader_param/amount", null, 1.0, 0.2)
	if panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.disconnect("tween_all_completed", self, "on_fade_complete")
	panel.tween.start()
	hide_tooltip()
	hide_adv_tooltip()

func fade_out_panel(panel:Control):
	var s = panel.rect_size
	panel.tween.interpolate_property(panel, "modulate", null, Color(1, 1, 1, 0), 0.1)
	panel.tween.interpolate_property($Panels/Blur.material, "shader_param/amount", null, 0.0, 0.2)
	panel.tween.start()
	if not panel.tween.is_connected("tween_all_completed", self, "on_fade_complete"):
		panel.tween.connect("tween_all_completed", self, "on_fade_complete", [panel])

func on_fade_complete(panel:Control):
	panel.visible = false
	hide_tooltip()
	hide_adv_tooltip()

func toggle_panel(_panel):
	if is_instance_valid(active_panel):
		fade_out_panel(active_panel)
		if active_panel == _panel:
			active_panel = null
			return
	active_panel = _panel
	fade_in_panel(_panel)
	_panel.refresh()

func set_to_ship_coords():
	var diff_cluster:bool = c_c != ships_dest_coords.c
	c_c = ships_dest_coords.c
	c_g_g = ships_dest_g_coords.g
	c_g = ships_dest_coords.g
	c_s_g = ships_dest_g_coords.s
	c_s = ships_dest_coords.s
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
		if tile_data.empty():
			HUD.planet_grid_btns.remove_child(HUD.planet_grid_btns.get_node(str(bookmark.c_p_g)))
			bookmarks.planet.erase(str(bookmark.c_p_g))
			popup(tr("BOOKMARK_P_ERROR"), 2.0)
			return true#Error
		c_p = bookmark.c_p
		c_p_g = bookmark.c_p_g
	if bookmark.has("c_s_g"):
		planet_data = open_obj("Systems", bookmark.c_s_g)
		if planet_data.empty():
			HUD.system_grid_btns.remove_child(HUD.system_grid_btns.get_node(str(bookmark.c_s_g)))
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

func delete_galaxy():
	galaxy_data[c_g].clear()
	Helper.save_obj("Clusters", c_c, galaxy_data)

#															V function to execute after removing objects but before adding new ones
#func switch_view(new_view:String, first_time:bool = false, fn:String = "", fn_args:Array = [], save_zooms:bool = true, fade_anim:bool = true):
func switch_view(new_view:String, other_params:Dictionary = {}):
	_on_BottomInfo_close_button_pressed()
	if $UI.has_node("BuildingShortcuts"):
		$UI.get_node("BuildingShortcuts").queue_free()
	$UI/Panel.visible = false
	var old_view:String = c_v
	if view_tween.is_active():
		return
	if not other_params.has("dont_fade_anim"):
		view_tween.interpolate_property(view, "modulate", null, Color(1.0, 1.0, 1.0, 0.0), 0.15)
		view_tween.start()
		if is_instance_valid(planet_HUD) and new_view != "planet":
			var anim_player:AnimationPlayer = planet_HUD.get_node("AnimationPlayer")
			anim_player.play_backwards("MoveButtons")
		if is_instance_valid(space_HUD) and not new_view in ["system", "galaxy", "cluster", "universe"]:
			var anim_player:AnimationPlayer = space_HUD.get_node("AnimationPlayer")
			anim_player.play_backwards("MoveButtons")
		if is_instance_valid(HUD) and new_view in ["battle", "cave", "dimension", "STM", "planet_details", ""]:
			var anim_player:AnimationPlayer = HUD.get_node("AnimationPlayer2")
			anim_player.play_backwards("MoveStuff")
		if c_v == "planet" and is_instance_valid(view.obj):
			view.obj.timer.stop()
		yield(view_tween, "tween_all_completed")
	hide_tooltip()
	hide_adv_tooltip()
	if not other_params.has("first_time"):
		save_views(true)
	if viewing_dimension:
		remove_dimension()
		switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
	else:
		if not other_params.has("first_time"):
			match c_v:
				"planet":
					remove_planet(not other_params.has("dont_save_zooms"))
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
				"universe":
					remove_universe()
					remove_space_HUD()
				"mining":
					remove_mining()
				"science_tree":
					$UI/Help.visible = false
					remove_science_tree()
				"cave":
					$UI.add_child(HUD)
					if is_instance_valid(cave):
						remove_child(cave)
					cave = null
					switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
				"STM":
					$UI.add_child(HUD)
					remove_child(STM)
					STM = null
					switch_music(load("res://Audio/ambient" + String(Helper.rand_int(1, 3)) + ".ogg"))
				"battle":
					$UI.add_child(HUD)
					HUD.refresh()
					battle.queue_free()
			if c_v in  ["science_tree", "STM"]:
				c_v = l_v
			elif new_view != "":
				l_v = c_v
				if new_view != "dimension":
					c_v = new_view
				else:
					viewing_dimension = true
					add_dimension()
	if other_params.has("fn"):
		var fn:String = other_params.fn
		var fn_args:Array = other_params.fn_args if other_params.has("fn_args") else []
		if fn == "set_bookmark_coords":
			if set_bookmark_coords(fn_args[0]):
				c_v = old_view
		else:
			callv(fn, fn_args)
	if new_view in ["universe", "cluster", "galaxy", "system", "planet"]:
		$MMTimer.start()
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
	else:
		$MMTimer.stop()
	if not viewing_dimension:
		match new_view:
			"planet":
				add_planet()
			"planet_details":
				planet_details = planet_details_scene.instance()
				add_child(planet_details)
				if is_instance_valid(HUD) and $UI.is_a_parent_of(HUD):
					$UI.remove_child(HUD)
			"system":
				add_system()
				add_space_HUD()
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
				if help.has("science_tree"):
					$UI/Help.visible = true
					$UI/Help.text = tr("SC_TREE_ZOOM")
					help.erase("science_tree")
			"cave":
				if is_instance_valid(HUD) and $UI.is_a_parent_of(HUD):
					$UI.remove_child(HUD)
				cave = cave_scene.instance()
				cave.rover_data = rover_data[rover_id]
				add_child(cave)
				switch_music(preload("res://Audio/cave1.ogg"), 0.95 if tile_data[c_t].has("aurora") else 1.0)
			"STM":
				$Ship.visible = false
				if is_instance_valid(HUD) and $UI.is_a_parent_of(HUD):
					$UI.remove_child(HUD)
				STM = STM_scene.instance()
				add_child(STM)
				switch_music(preload("res://Audio/STM.mp3"))
			"battle":
				$Ship.visible = false
				if is_instance_valid(HUD) and $UI.is_a_parent_of(HUD):
					$UI.remove_child(HUD)
				battle = battle_scene.instance()
				add_child(battle)
		if c_v in ["planet", "system", "galaxy", "cluster", "universe", "mining", "science_tree"] and is_instance_valid(HUD) and is_a_parent_of(HUD):
			HUD.refresh()
		if c_v == "universe" and HUD.dimension_btn.visible:
			HUD.switch_btn.visible = false
	if not other_params.has("first_time"):
		fn_save_game()
	if not other_params.has("dont_fade_anim"):
		view_tween.interpolate_property(view, "modulate", null, Color(1.0, 1.0, 1.0, 1.0), 0.25)
		view_tween.start()

func add_science_tree():
	$ScienceTreeBG.visible = enable_shaders
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

func add_mining():
	HUD.get_node("Bottom/Hotbar").visible = false
	mining_HUD = mining_HUD_scene.instance()
	add_child(mining_HUD)

func remove_mining():
	Helper.save_obj("Planets", c_p_g, tile_data)
	if is_instance_valid(tutorial) and tutorial.tut_num == 15 and objective.empty():
		tutorial.fade()
	HUD.get_node("Bottom/Hotbar").visible = true
	if is_instance_valid(mining_HUD):
		remove_child(mining_HUD)
	mining_HUD = null

func remove_science_tree():
	$ScienceTreeBG.visible = false
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
	var loading = loading_scene.instance()
	loading.position = Vector2(640, 360)
	add_child(loading)
	loading.name = "Loading"

func open_obj(type:String, id:int):
	var arr:Array = []
	var save:File = File.new()
	var file_path:String = "user://%s/Univ%s/%s/%s.hx3" % [c_sv, c_u, type, id]
	if save.file_exists(file_path):
		save.open(file_path, File.READ)
		arr = save.get_var() if save.get_len() > 0 else []
		save.close()
	return arr
	
func obj_exists(type:String, id:int):
	var save:File = File.new()
	var file_path:String = "user://%s/Univ%s/%s/%s.hx3" % [c_sv, c_u, type, id]
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
			if ships_c_g_coords.s == c_s_g:
				system_data[c_s].explored = true
		"galaxy":
			view.shapes_data = galaxy_data[c_g].shapes
			view.add_obj("Galaxy", galaxy_data[c_g]["view"]["pos"], galaxy_data[c_g]["view"]["zoom"])
			add_space_HUD()
			if ships_c_g_coords.g == c_g_g:
				galaxy_data[c_g].explored = true
		"cluster":
			view.shapes_data = u_i.cluster_data[c_c].shapes
			view.add_obj("Cluster", u_i.cluster_data[c_c]["view"]["pos"], u_i.cluster_data[c_c]["view"]["zoom"])
			add_space_HUD()
			if ships_c_coords.c == c_c:
				u_i.cluster_data[c_c].explored = true
		"universe":
			view.shapes_data = universe_data[c_u].shapes
			view.add_obj("Universe", universe_data[c_u]["view"]["pos"], universe_data[c_u]["view"]["zoom"], universe_data[c_u]["view"]["sc_mult"])
		"science_tree":
			view.add_obj("ScienceTree", science_tree_view.pos, science_tree_view.zoom)
			var sc_UI = preload("res://Scenes/ScienceUI.tscn").instance()
			$UI.add_child(sc_UI)
			sc_UI.sc_tree = view.obj
			sc_UI.name = "ScienceUI"
	view.update()

func add_space_HUD():
	if not is_instance_valid(space_HUD) or not $UI.is_a_parent_of(space_HUD):
		space_HUD = space_HUD_scene.instance()
		$UI.add_child(space_HUD)
		if c_v in ["galaxy", "cluster"]:
			space_HUD.get_node("VBoxContainer/Overlay").visible = true
			add_overlay()
		if c_v in ["galaxy", "cluster", "universe"]:
			space_HUD.get_node("VBoxContainer/Annotate").visible = true
			add_annotator()
		space_HUD.get_node("VBoxContainer/ElementOverlay").visible = c_v == "system" and science_unlocked.has("ATM")
		space_HUD.get_node("VBoxContainer/Megastructures").visible = c_v == "system" and science_unlocked.has("MAE")
		space_HUD.get_node("VBoxContainer/Gigastructures").visible = c_v == "galaxy" and science_unlocked.has("GS")
		space_HUD.get_node("ConquerAll").visible = c_v == "system" and (universe_data[c_u].lv >= 32 or subjects.dimensional_power.lv >= 1) and not system_data[c_s].has("conquered") and ships_c_g_coords.s == c_s_g
		space_HUD.get_node("SendFighters").visible = c_v == "galaxy" and science_unlocked.has("FG") and not galaxy_data[c_g].has("conquered") or c_v == "cluster" and science_unlocked.has("FG2") and not u_i.cluster_data[c_c].has("conquered")
		if c_v == "universe":
			space_HUD.get_node("SendProbes").visible = true
		else:
			space_HUD.get_node("SendProbes").visible = false

func add_overlay():
	overlay = overlay_scene.instance()
	overlay.visible = false
	$UI.add_child(overlay)
	overlay.refresh_overlay()

func remove_overlay():
	if is_instance_valid(overlay) and $UI.is_a_parent_of(overlay):
		if $GrayscaleRect.modulate.a > 0:
			$GrayscaleRect/AnimationPlayer.play_backwards("Fade")
		$UI.remove_child(overlay)
		overlay.queue_free()

func add_annotator():
	annotator = annotator_scene.instance()
	annotator.visible = false
	$UI.add_child(annotator)

func remove_annotator():
	if is_instance_valid(annotator) and $UI.is_a_parent_of(annotator):
		$UI.remove_child(annotator)
		annotator.free()

func remove_space_HUD():
	if is_instance_valid(space_HUD) and $UI.is_a_parent_of(space_HUD):
		$UI.remove_child(space_HUD)
		space_HUD.queue_free()
	remove_overlay()
	remove_annotator()

func add_dimension():
	if is_instance_valid(HUD) and $UI.is_a_parent_of(HUD):
		$UI.remove_child(HUD)
	if is_instance_valid(dimension):
		dimension.visible = true
		dimension.refresh_univs()
		$Ship.visible = false
	else:
		dimension = preload("res://Scenes/Views/Dimension.tscn").instance()
		add_child(dimension)

func add_universe():
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
		add_loading()
		reset_collisions()
		if c_c != 0:
			galaxy_data.clear()
		if not u_i.cluster_data[c_c].has("name"):
			if u_i.cluster_data[c_c].class == ClusterType.GROUP:
				u_i.cluster_data[c_c].name = tr("GALAXY_GROUP") + " %s" % c_c
			else:
				u_i.cluster_data[c_c].name = tr("GALAXY_CLUSTER") + " %s" % c_c
		generate_galaxy_part()
	else:
		add_obj("cluster")
	$Stars/WhiteStars.visible = true
	$Stars/AnimationPlayer.play("StarFade")
	if enable_shaders:
		$ClusterBG.fade_in()
		var dist:Vector2 = cartesian2polar(u_i.cluster_data[c_c].pos.x, u_i.cluster_data[c_c].pos.y)
		var hue:float = fmod(dist.x + 300, 1000.0) / 1000.0
		var sat:float = pow(fmod(dist.y + PI, 10.0) / 10.0, 0.2)
		$ClusterBG.change_color(Color.from_hsv(hue, sat, 0.6))
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/UniverseView.png")
	if len(ship_data) == 3 and u_i.lv >= 60:
		long_popup(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_4th_ship()

func add_galaxy():
	if obj_exists("Clusters", c_c):
		galaxy_data = open_obj("Clusters", c_c)
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	if not galaxy_data[c_g].has("discovered"):
		if not galaxy_data[c_g].has("name"):
			galaxy_data[c_g].name = "%s %s" % [tr("GALAXY"), c_g]
		yield(start_system_generation(), "completed")
	add_obj("galaxy")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/ClusterView.png")
	if len(ship_data) == 2 and u_i.lv >= 40:
		long_popup(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_3rd_ship()

func start_system_generation():
	yield(get_tree(), "idle_frame")
	add_loading()
	reset_collisions()
	gc_remaining = floor(pow(galaxy_data[c_g]["system_num"], 0.8) / 250.0)
	if c_g_g != 0:
		system_data.clear()
	yield(generate_system_part(), "completed")
	
func add_system():
	if obj_exists("Galaxies", c_g_g):
		system_data = open_obj("Galaxies", c_g_g)
	planet_data = open_obj("Systems", c_s_g)
	if not system_data[c_s].has("discovered") or planet_data.empty():
		if c_s_g != 0:
			planet_data.clear()
		generate_planets(c_s)
	show.bookmarks = true
	add_obj("system")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/GalaxyView.png")
	if len(ship_data) == 1 and u_i.lv >= 20:
		long_popup(tr("WANDERING_SHIP_DESC"), tr("WANDERING_SHIP"))
		get_2nd_ship()

func add_planet():
	stars_tween.interpolate_property($Stars/Stars, "modulate", null, Color(1, 1, 1, 1), 0.3)
	stars_tween.start()
	planet_data = open_obj("Systems", c_s_g)
	if not planet_data[c_p].has("discovered") or open_obj("Planets", c_p_g).empty():
		generate_tiles(c_p)
	add_obj("planet")
	HUD.switch_btn.texture_normal = preload("res://Graphics/Buttons/SystemView.png")
	view.obj.icons_hidden = view.scale.x >= 0.25
	planet_HUD = planet_HUD_scene.instance()
	$UI.add_child(planet_HUD)
	if stats_global.bldgs_built == 0:
		planet_HUD.get_node("VBoxContainer/Construct").material.set_shader_param("enabled", true)

func remove_dimension():
	if not $UI.is_a_parent_of(HUD):
		$UI.add_child(HUD)
	viewing_dimension = false
	dimension.visible = false
	view.dragged = true

func remove_universe():
	view.remove_obj("universe")

func remove_cluster():
	if enable_shaders:
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
	stars_tween.interpolate_property($Stars/Stars, "modulate", null, Color(1, 1, 1, 0), 0.2)
	stars_tween.start()
	view.remove_obj("planet", save_zooms)
	vehicle_panel.tile_id = -1
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
	if a["outer_radius"] < b["outer_radius"]:
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
			c_i["galaxy_num"] = Helper.rand_int(10, 100)
		else:
			c_i["galaxy_num"] = Helper.rand_int(500, 5000)
		var pos:Vector2
		var dist_from_center = pow(randf(), 0.5) * max_dist_from_center + 160
		if _i == 1:
			dist_from_center = 200
			c_i.class = ClusterType.GROUP
			c_i.galaxy_num = Helper.rand_int(80, 100)
		c_i.rich_elements = {}
		var _rich_elements = rich_element_list.duplicate()
		_rich_elements.shuffle()
		for j in range(0, int(range_lerp(dist_from_center, 0, 12000, 1, 5))):
			c_i.rich_elements[_rich_elements[j]] = 8 * (1 + randf()) * range_lerp(dist_from_center, 0, 16000, 1, 40) * u_i.dark_energy
		pos = polar2cartesian(dist_from_center, rand_range(0, 2 * PI))
		c_i["pos"] = pos
		c_i["id"] = c_id + c_num
		c_i.FM = Helper.clever_round((1 + pos.length() / 1000.0) * u_i.dark_energy)#Ferromagnetic materials
		c_i.diff = Helper.clever_round(1 + pos.length() * 2.0)
		u_i.cluster_data.append(c_i)
	c_num += total_clust_num
	fn_save_game()

func generate_galaxy_part():
	var progress = 0.0
	while progress != 1:
		progress = generate_galaxies(c_c)
		$Loading.update_bar(progress, tr("GENERATING_CLUSTER") % [u_i.cluster_data[c_c]["galaxies"].size(), u_i.cluster_data[c_c]["galaxy_num"]])
		yield(get_tree().create_timer(0.0000000000001),"timeout")  #Progress Bar doesnt update without this
	g_num += u_i.cluster_data[c_c].galaxy_num
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
		g_i["parent"] = id
		g_i["systems"] = []
		g_i["shapes"] = []
		g_i["type"] = randi() % 7
		var rand = randf()
		g_i.dark_matter = rand_range(0.85, 1.15) #Influences planet numbers and size
		if g_i.type == 6:
			g_i["system_num"] = int(5000 + 10000 * pow(randf(), 2))
			g_i["B_strength"] = Helper.clever_round(1e-9 * rand_range(3, 5) * FM * u_i.charge)#Influences star classes
			var sat:float = rand_range(0, 0.5)
			var hue:float = rand_range(sat / 5.0, 1 - sat / 5.0)
			g_i.modulate = Color().from_hsv(hue, sat, 1.0)
			g_i.dark_matter -= 0.05
		else:
			g_i["system_num"] = int(pow(randf(), 2) * 8000) + 2000
			g_i["B_strength"] = Helper.clever_round(1e-9 * rand_range(0.5, 4) * FM * u_i.charge)
			if randf() < 0.6: #Dwarf galaxy
				g_i["system_num"] /= 10
		g_i.dark_matter = Helper.clever_round(pow(g_i.dark_matter, -log(rand)*u_i.dark_energy/2.5 + 1))
		g_i["rotation"] = rand_range(0, 2 * PI)
		g_i["view"] = {"pos":Vector2(640, 360), "zoom":0.2}
		var pos
		var N = obj_shapes.size()
		if N >= total_gal_num / 6:
			obj_shapes.sort_custom(self, "sort_shapes")
			obj_shapes = obj_shapes.slice(int((N - 1) * 0.7), N - 1)
			min_dist_from_center = obj_shapes[0]["outer_radius"]
		
		var radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.5)
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
		var starting_galaxy = c_c == 0 and galaxy_num == total_gal_num and i == 0
		if starting_galaxy:
			show.g_bk_button = true
			g_i = galaxy_data[0]
			radius = 200 * pow(g_i["system_num"] / GALAXY_SCALE_DIV, 0.5)
			obj_shapes.append({"pos":g_i["pos"], "radius":radius, "outer_radius":g_i["pos"].length() + radius})
			u_i.cluster_data[id]["galaxies"].append({"global":0, "local":0})
		else:
			if id == 0:#if the galaxies are in starting cluster
				g_i.diff = Helper.clever_round(1 + pos.distance_to(galaxy_data[0].pos) / 70)
			else:
				g_i.diff = Helper.clever_round(u_i.cluster_data[id].diff * rand_range(120, 150) / max(100, pow(pos.length(), 0.5)))
			u_i.cluster_data[id]["galaxies"].append({"global":g_i.id, "local":g_i.l_id})
			galaxy_data.append(g_i)
	if progress == 1:
		u_i.cluster_data[id]["discovered"] = true
		if id != 0:
			var view_zoom = 500.0 / max_outer_radius
			u_i.cluster_data[id]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}
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
			galaxy_data[c_g]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}
	else:
		for i in range(0, N, 500):
			systems_collision_detection(c_g, i)
			update_loading_bar(i, N, tr("GENERATING_GALAXY"))
			yield(get_tree().create_timer(0.0000000000001),"timeout")
#	if c_g_g == 0 and second_ship_hints.spawned_at == -1:
#		#Second ship can only appear in a system in the rectangle formed by solar system and center of galaxy
#		var rect:Rect2 = Rect2(Vector2.ZERO, system_data[0].pos)
#		rect = rect.abs()
#		for system in system_data:
#			if system.id == 0:
#				continue
#			if rect.has_point(system.pos) and randf() < 0.1:
#				system.second_ship = Helper.rand_int(1, system.planet_num)
#				second_ship_hints.spawned_at = system.id
#				break
	s_num += galaxy_data[c_g].system_num
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
		galaxy_data[id]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}

func get_sys_diff(pos:Vector2, id:int, s_i:Dictionary):
	var stars = s_i.stars
	var combined_star_mass = 0
	for star in stars:
		combined_star_mass += star.mass
	if c_g_g == 0:
		return Helper.clever_round((1 + pos.distance_to(system_data[0].pos) * pow(combined_star_mass, 0.5) / 5000) * galaxy_data[id].diff)
	else:
		return Helper.clever_round(galaxy_data[id].diff * pow(combined_star_mass, 0.4) * rand_range(120, 150) / max(100, pow(pos.length(), 0.5)))
	
func generate_systems(id:int):
	randomize()
	var total_sys_num = galaxy_data[id]["system_num"]
	var spiral:bool = galaxy_data[id].type == 6
	
	#For reference, globular clusters are tightly packed old stars (class G etc)
	#Most of the stars in them are around the same temperature, but put some outliers
	#They have low metallicity

	#Open clusters are
	var B = galaxy_data[id].B_strength#Magnetic field strength
	var dark_matter = galaxy_data[id].dark_matter
	var G = u_i.gravitational
	for i in range(0, total_sys_num):
		if c_g_g == 0 and i == 0:
			show.s_bk_button = true
			continue
		var s_i = {}
		s_i["parent"] = id
		s_i["planets"] = []
		
		var num_stars:int = max(-log(randf()/dark_matter)/1.5 + 1, 1)
		var stars = []
		var hypergiant_system:bool = c_c == 1 and fourth_ship_hints.hypergiant_system_spawn_galaxy == id and fourth_ship_hints.hypergiant_system_spawn_system == -1
		var dark_matter_system:bool = c_c == 3 and fourth_ship_hints.dark_matter_spawn_galaxy == id and fourth_ship_hints.dark_matter_spawn_system == -1
		for _j in range(0, num_stars):
			var star = {}#Higher a: lower temperature (older) stars
			var a = (1.65 if gc_stars_remaining == 0 else 4.0) * pow(u_i.age, 0.25)
			a *= pow(e(1, -9) / B, physics_bonus.BI)#Higher B: hotter stars
			#Solar masses
			var mass:float = -log(randf()) / a
			var star_size = 1
			var star_class = ""
			#Temperature in K
			var temp = 0
			if mass < 0.08:#Y, T, L
				star_size = range_lerp(mass, 0, 0.08, 0.01, 0.1)
				temp = range_lerp(mass, 0, 0.08, 250, 2400)
			elif mass >= 0.08 and mass < 0.45:#M
				star_size = range_lerp(mass, 0.08, 0.45, 0.1, 0.7)
				temp = range_lerp(mass, 0.08, 0.45, 2400, 3700)
			elif mass >= 0.45 and mass < 0.8:#K
				star_size = range_lerp(mass, 0.45, 0.8, 0.7, 0.96)
				temp = range_lerp(mass, 0.45, 0.8, 3700, 5200)
			elif mass >= 0.8 and mass < 1.04:#G
				star_size = range_lerp(mass, 0.8, 1.04, 0.96, 1.15)
				temp = range_lerp(mass, 0.8, 1.04, 5200, 6000)
			elif mass >= 1.04 and mass < 1.4:#F
				star_size = range_lerp(mass, 1.04, 1.4, 1.15, 1.4)
				temp = range_lerp(mass, 1.04, 1.4, 6000, 7500)
			elif mass >= 1.4 and mass < 2.1:#A
				star_size = range_lerp(mass, 1.4, 2.1, 1.4, 1.8)
				temp = range_lerp(mass, 1.4, 2.1, 7500, 10000)
			elif mass >= 2.1 and mass < 9:#B
				star_size = range_lerp(mass, 2.1, 9, 1.8, 6.6)
				temp = range_lerp(mass, 2.1, 9, 10000, 30000)
			elif mass >= 9 and mass < 100:#O
				star_size = range_lerp(mass, 9, 100, 6.6, 22)
				temp = range_lerp(mass, 16, 100, 30000, 70000)
			elif mass >= 100 and mass < 1000:#Q
				star_size = range_lerp(mass, 100, 1000, 22, 60)
				temp = range_lerp(mass, 100, 1000, 70000, 120000)
			elif mass >= 1000 and mass < 10000:#R
				star_size = range_lerp(mass, 1000, 10000, 60, 200)
				temp = range_lerp(mass, 1000, 10000, 120000, 210000)
			elif mass >= 10000:#Z
				var pw = pow(mass, 1/3.0) / pow(10000, 1/3.0)
				star_size = pw * 200
				temp = pw * 210000
			
			var star_type = ""
			if mass >= 0.08:
				star_type = "main_sequence"
			else:
				star_type = "brown_dwarf"
			var hypergiant:int = -1
			if mass > 0.2 and mass < 1.3 and randf() < 0.03:
				star_type = "white_dwarf"
				temp = 4000 + exp(10 * randf())
				star_size = rand_range(0.008, 0.02)
				mass = rand_range(0.4, 0.8)
			elif mass > 0.25:
				var r = randf()
				var star_size_tier = log(G/r) - log(G)*pow(r, 4) + 1
				if star_size_tier > 7.0:
					mass = rand_range(5, 30)
					star_type = "hypergiant"
					var tier:int = ceil(star_size_tier - 7.0)
					star_size *= max(rand_range(550000, 700000) / temp, rand_range(3.0, 4.0)) * pow(1.2, tier - 1)
					star_type = "hypergiant " + Helper.get_roman_num(tier)
					hypergiant = tier
				elif star_size_tier > 5.0:
					star_type = "supergiant"
					star_size *= max(rand_range(360000, 440000) / temp, rand_range(1.7, 2.1))
				elif star_size_tier > 3.5:
					star_type = "giant"
					star_size *= max(rand_range(240000, 280000) / temp, rand_range(1.2, 1.4))
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
			star["luminosity"] = Helper.clever_round(4 * PI * pow(star_size * e(6.957, 8), 2) * e(5.67, -8) * s_b * pow(temp, 4) / e(3.828, 26), 4)
			star["mass"] = Helper.clever_round(mass * u_i.planck, 4)
			star["size"] = Helper.clever_round(star_size, 4)
			star["type"] = star_type
			if hypergiant != -1:
				star.hypergiant = hypergiant
			star["class"] = star_class
			star["temperature"] = Helper.clever_round(temp, 4)
			star["pos"] = Vector2.ZERO
			stars.append(star)
		var combined_star_mass = 0
		for star in stars:
			combined_star_mass += star.mass
		stars.sort_custom(self, "sort_by_mass")
		var planet_num:int = clamp(round(pow(combined_star_mass, 0.2) * rand_range(3, 9) * pow(dark_matter, 0.25)), 2, 50)
		s_i["planet_num"] = planet_num
		if galaxy_data[id].has("conquered"):
			s_i.conquered = true
			stats_univ.planets_conquered += planet_num
			stats_dim.planets_conquered += planet_num
			stats_global.planets_conquered += planet_num
		
		var s_id = system_data.size()
		s_i["id"] = s_id + s_num
		s_i["l_id"] = s_id
		s_i["stars"] = stars
		s_i.pos = Vector2.ZERO
		galaxy_data[id]["systems"].append({"global":s_i.id, "local":s_i.l_id})
		system_data.append(s_i)
	galaxy_data[id]["discovered"] = true

func sort_by_mass(star1:Dictionary, star2:Dictionary):
	if star1.mass > star2.mass:
		return true
	return false

func get_max_star_prop(s_id:int, prop:String):
	var max_star_prop = 0	
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
	var circles:Array = [{"pos":Vector2.ZERO, "radius":center_star_r_in_pixels}]
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
			var th:float = rand_range(0, 2 * PI)
			pos = polar2cartesian(r, th)
			for circ in circles:
				if pos.distance_to(circ.pos) < radius_in_pixels + circ.radius:
					colliding = true
					r_offset += 10.0
					break
		star.pos = pos
		star_boundary = max(star_boundary, pos.length() + radius_in_pixels)
		circles.append({"pos":pos, "radius":radius_in_pixels})
	for i in range(0, N_stars):
		var star = system_data[id].stars[i]
		var star_size = star.size
		var star_temp = star.temperature
		var star_lum = star.luminosity
		var MSes = ["M_DS", "M_MB", "M_PK", "M_CBS"]
		if c_g_g == 0:
			MSes.erase("M_MB")
		var MS = MSes[randi() % len(MSes)]
		if MS in ["M_DS", "M_MB"] and randf() < min(sqrt(star_temp) / pow(star_size, 1.5) / 100.0, 0.15):
			star.MS = MS
		elif randf() < min(pow(star_lum, 0.1) / 25.0, 0.15):
			star.MS = MS
		if star.has("MS"):
			star.MS_lv = randi() % (Data.MS_num_stages[star.MS] + 1)
			star.bldg = {}
			if star.MS == "M_MB":
				star.repair_cost = Data.MS_costs[star.MS].money * 72 * rand_range(1, 3)
			else:
				star.repair_cost = Data.MS_costs[star.MS + "_" + str(star.MS_lv)].money * 24 * rand_range(1, 3)
	var planet_num = system_data[id].planet_num
	var max_distance
	var j = 0
	while pow(1.3, j) * 240 < star_boundary * 2.63:
		j += 1
	var dark_matter = galaxy_data[c_g].dark_matter
	system_data[id]["planets"].clear()
	var hypergiant_system:bool = c_s_g == fourth_ship_hints.hypergiant_system_spawn_system
	var dark_matter_system:bool = c_s_g == fourth_ship_hints.dark_matter_spawn_system
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
		p_i["type"] = Helper.rand_int(3, 10)
		if p_num == 0:# Starting solar system has smaller planets
			p_i["size"] = int((2000 + rand_range(0, 7000) * (i + 1) / 2.0) * pow(u_i.gravitational, 0.5))
			p_i.pressure = pow(10, rand_range(-3, log(p_i.size / 5.0) / log(10) - 3)) * u_i.boltzmann
		else:
			p_i["size"] = int((2000 + rand_range(0, 12000) * (i + 1) / 2.0) * pow(u_i.gravitational, 0.5))
			p_i.pressure = pow(10, rand_range(-3, log(p_i.size) / log(10) - 2)) * u_i.boltzmann
		p_i["angle"] = rand_range(0, 2 * PI)
		if p_num == 0 and i == 2:
			p_i.angle = rand_range(PI/4, 3*PI/4)
		#p_i["distance"] = pow(1.3,i+(max(1.0,log(combined_star_size*(0.75+0.25/max(1.0,log(combined_star_size)))))/log(1.3)))
		p_i["distance"] = pow(1.3,i + j) * rand_range(240, 270)
		if hypergiant_system:
			p_i.distance *= 60
		# 1 solar radius = 2.63 px = 0.0046 AU
		# 569 px = 1 AU = 215.6 solar radii
		max_distance = p_i["distance"]
		p_i["parent"] = id
		p_i["view"] = {"pos":Vector2.ZERO, "zoom":1.0}
		p_i["tiles"] = []
		var p_id = planet_data.size()
		p_i["id"] = p_id + p_num
		p_i["l_id"] = p_id
		system_data[id]["planets"].append({"local":p_id, "global":p_id + p_num})
		var dist_in_km = p_i.distance / 569.0 * e(1.5, 8)#                             V bond albedo
		var temp = max_star_temp * pow(star_size_in_km / (2 * dist_in_km), 0.5) * pow(1 - 0.1, 0.25)
		p_i.temperature = temp# in K
		var gas_giant:bool = c_s_g != 0 and p_i.size >= max(18000, 30000 * pow(combined_star_mass * u_i.gravitational, 0.25))
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
		p_i.core_start_depth = round(rand_range(0.4, 0.46) * p_i.size * 1000)
		p_i.surface = add_surface_materials(temp, p_i.crust)
		p_i.liq_seed = randi()
		p_i.liq_period = rand_range(60, 300)
		if id + s_num == 0 and c_u == 0:#Only water in solar system
			if randf() < 0.2:
				p_i.lake_1 = {"element":"H2O"}
			if randf() < 0.2:
				p_i.lake_2 = {"element":"H2O"}
		elif p_i.temperature <= 1000:
			p_i.lake_1 = {"element":get_random_element(list_of_element_probabilities)}
			p_i.lake_2 = {"element":get_random_element(list_of_element_probabilities)}
		p_i.HX_data = []
		var diff:float = system_data[id].diff
		var power:float = diff * pow(p_i.size / 2500.0, 0.5)
		var num:int = 0
		var total_num:int = Helper.rand_int(1, 12)
		if not p_i.has("conquered"):
			while num < total_num:
				num += 1
				var lv:int = max(ceil(rand_range(0.5, 0.9) * log(power) / log(1.15)), 1)
				var _class:int = 1
				if randf() < log(diff) / log(100) - 1.0:#difficulty < 100 = no green enemies, difficulty = 1000 = 50% chance of green enemies, difficulty > 10000 = no more red enemies, always green or higher
					_class += 1
				if randf() < log(diff / 100.0) / log(100) - 1.0:
					_class += 1
				if randf() < log(diff / 10000.0) / log(100) - 1.0:
					_class += 1
				if p_num == 0:
					if lv > 4:
						lv = 4
					if i == 2:
						lv = 1
				if num == total_num:
					lv = max(ceil(log(power) / log(1.15)), 1)
				var HP = round(rand_range(0.8, 1.2) * 15 * pow(1.16, lv - 1))
				if _class == 2:
					HP = round(HP * rand_range(4.0, 6.0))
				elif _class >= 3:
					HP = round(HP * rand_range(8.0, 12.0))
				var def = round(randf() * 7.0 + 3.0)
				var atk = round(rand_range(0.8, 1.2) * (15 - def) * pow(1.15, lv - 1))
				var acc = round(rand_range(0.8, 1.2) * 8 * pow(1.15, lv - 1))
				var eva = round(rand_range(0.8, 1.2) * 8 * pow(1.15, lv - 1))
				var _money = round(rand_range(1, 2) * pow(1.3, lv - 1) * 50000)
				var XP = round(pow(1.25, lv - 1) * 5)
				p_i.HX_data.append({"class":_class, "type":Helper.rand_int(1, 4), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva, "money":_money, "XP":XP})
				power -= floor(pow(1.15, lv))
				if power <= 1:
					break
			p_i.HX_data.shuffle()
		var wid:int = Helper.get_wid(p_i.size)
		var view_zoom = 3.0 / wid
		p_i.view = {"pos":Vector2(340, 80), "zoom":view_zoom}
		if c_u != 0 and p_num == 0 and i == 3:
			p_i.discovered = true
			p_i.conquered = true
			p_i.angle = PI / 2
			p_i.pressure = 1
		stats_univ.biggest_planet = max(p_i.size, stats_univ.biggest_planet)
		stats_dim.biggest_planet = max(p_i.size, stats_dim.biggest_planet)
		stats_global.biggest_planet = max(p_i.size, stats_global.biggest_planet)
		if c_s_g != 0:
			if p_i.type in [11, 12]:
				if randf() < min(sqrt(p_i.size) / 3000.0 + pow(p_i.pressure, 0.3) / 100.0, 0.15) * pow(u_i.age, 0.15):
					p_i.MS = "M_MME"
			elif randf() < min(p_i.size / 500000.0 + pow(p_i.pressure, 0.7) / 400.0, 0.15) * pow(u_i.age, 0.15):
				p_i.MS = "M_SE"
			if p_i.has("MS"):
				p_i.MS_lv = randi() % (Data.MS_num_stages[p_i.MS] + 1)
				p_i.bldg = {}
				p_i.repair_cost = Data.MS_costs[p_i.MS + "_" + str(p_i.MS_lv)].money * 24 * rand_range(1, 3)
		planet_data.append(p_i)
	if c_s_g != 0:
		var view_zoom = 400 / max_distance
		system_data[id]["view"] = {"pos":Vector2(640, 360), "zoom":view_zoom}
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

func get_hottest_star_temp(s_id):
	var res = system_data[s_id].stars[0].temperature
	for i in range(1, len(system_data[s_id].stars)):
		if system_data[s_id].stars[i].temperature > res:
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

func generate_volcano(t_id:int, VEI:float, artificial:bool = false):
	var richness:float = VEI if VEI <= 7.0 else pow(VEI - 6.0, 1.6) + 6.0
	var size:int = stepify(VEI - 2, 2) + 1
	var half_size:int = size / 2
	var wid:int = Helper.get_wid(planet_data[c_p].size)
	var i:int = t_id % wid
	var j:int = t_id / wid
	for k in range(max(0, i - half_size), min(i + half_size + 1, wid)):
		for l in range(max(0, j - half_size), min(j + half_size + 1, wid)):
			var t_id2:int = k % wid + l * wid
			var tile2 = tile_data[t_id2]
			if tile2 and tile2.has("lake"):
				continue
			if abs(i - k) + abs(j - l) <= half_size + 1 - (int(VEI) & 1):
				tile_data[t_id2] = {} if not tile2 else tile2
				tile2 = tile_data[t_id2]
				if tile2.has("ash"):
					if not tile2.has("cave"):
						var diff = max(richness - tile2.ash.richness, 0)
						if tile2.has("bldg") and tile2.bldg.name == "ME":
							autocollect.rsrc.minerals += diff * tile2.bldg.path_1_value * (tile2.bldg.overclock_mult if tile2.bldg.has("overclock_mult") else 1.0)
						tile2.ash.richness = max(richness, tile2.ash.richness)
				else:
					tile2.ash = {"richness":richness}
					if tile2.has("bldg") and tile2.bldg.name == "ME":
						autocollect.rsrc.minerals += (richness - 1.0) * tile2.bldg.path_1_value * (tile2.bldg.overclock_mult if tile2.bldg.has("overclock_mult") else 1.0)
					if artificial:
						tile2.ash.artificial = true
				if not achievement_data.exploration.has("volcano_cave") and tile2.has("cave"):
					earn_achievement("exploration", "volcano_cave")
				if not achievement_data.exploration.has("volcano_aurora_cave") and tile2.has("cave") and tile2.has("aurora"):
					earn_achievement("exploration", "volcano_aurora_cave")
	tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
	tile_data[t_id].volcano = {"VEI":VEI}

func generate_tiles(id:int):
	tile_data.clear()
	var p_i:Dictionary = planet_data[id]
	#wid is number of tiles horizontally/vertically
	#So total number of tiles is wid squared
	var wid:int = Helper.get_wid(p_i.size)
	tile_data.resize(pow(wid, 2))
	#Aurora spawn
	var diff:int = 0
	var tile_from:int = -1
	var tile_to:int = -1
	var rand:float = randf()
	var thiccness:int = ceil(Helper.rand_int(1, 3) * wid / 50.0)
	var pulsation:float = rand_range(0.4, 1)
	var amplitude:float = 0.85
	var max_star_temp = get_max_star_prop(c_s, "temperature")
	var num_auroras:int = 2
	var home_planet:bool = c_p_g == 2 and c_u == 0
	var B_strength:float = galaxy_data[c_g].B_strength
	for i in num_auroras:
		if not home_planet and (randf() < 0.35 * pow(p_i.pressure, 0.15)):
			#au_int: aurora_intensity
			var au_int = Helper.clever_round(80000 * rand_range(1, 2) * B_strength * max_star_temp)
			if tile_from == -1:
				tile_from = Helper.rand_int(0, wid)
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
			stats_global.highest_au_int = max(au_int, stats_global.highest_au_int)
			stats_dim.highest_au_int = max(au_int, stats_dim.highest_au_int)
			stats_univ.highest_au_int = max(au_int, stats_univ.highest_au_int)
			if wid / 3 == 1:
				diff = thiccness + 1
			else:
				diff = Helper.rand_int(thiccness + 1, wid / 3) * sign(rand_range(-1, 1))
	#We assume that the star system's age is inversely proportional to the coldest star's temperature
	#Age is a factor in crater rarity. Older systems have more craters
	var coldest_star_temp = get_coldest_star_temp(c_s)
	var noise = OpenSimplexNoise.new()
	noise.seed = p_i.liq_seed
	noise.octaves = 1
	noise.period = p_i.liq_period#Higher period = bigger lakes
	if p_i.has("lake_1"):
		var phase_1_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_1.element + ".tscn")
		var phase_1 = phase_1_scene.instance()
		if chemistry_bonus.has(p_i.lake_1.element):
			phase_1.modify_PD(chemistry_bonus[p_i.lake_1.element])
		p_i.lake_1.state = Helper.get_state(p_i.temperature, p_i.pressure, phase_1)
		phase_1.free()
	if p_i.has("lake_2"):
		var phase_2_scene = load("res://Scenes/PhaseDiagrams/" + p_i.lake_2.element + ".tscn")
		var phase_2 = phase_2_scene.instance()
		if chemistry_bonus.has(p_i.lake_2.element):
			phase_2.modify_PD(chemistry_bonus[p_i.lake_2.element])
		p_i.lake_2.state = Helper.get_state(p_i.temperature, p_i.pressure, phase_2)
		phase_2.free()
	var volcano_probability:float = 0.0
	if randf() < log(20.0 / sqrt(coldest_star_temp/u_i.gravitational) + 1.0):
		volcano_probability = min(sqrt(u_i.gravitational) / sqrt(randf()) / pow(wid, 2), 0.15)
	var empty_tiles = []
	var crater_num:int = 0
	var total_VEI:float = 0.0
	for i in wid:
		for j in wid:
			var level:float = noise.get_noise_2d(i / float(wid) * 512, j / float(wid) * 512)
			var t_id = i % wid + j * wid
			if level > 0.5 and p_i.has("lake_1"):
				if p_i.lake_1.state != "g":
					tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
					if not tile_data[t_id].has("ash"):
						tile_data[t_id].lake = 1
					continue
			if level < -0.5 and p_i.has("lake_2"):
				if p_i.lake_2.state != "g":
					tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
					if not tile_data[t_id].has("ash"):
						tile_data[t_id].lake = 2
					continue
			if home_planet:
				continue
			if randf() < 0.1 / pow(wid, 0.9):
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				var floor_size:int = rand_range(25 * min(wid / 8.0, 1), 40 * rand_range(1, 1 + wid / 100.0))
				var num_floors:int = Helper.rand_int(1, int(wid / 2.5)) + 2
				var modifiers:Dictionary = {}
				if c_s_g != 0:
					var N:int = log(1.0 / randf() + 1.1) * log(system_data[c_s].diff) / log(10)
					var modifiers2:Dictionary = Data.cave_modifiers.duplicate(true)
					if c_g_g == 0:
						N = min(N, 2)
						for mod in modifiers2.keys():
							if modifiers2[mod].tier == 2:
								modifiers2.erase(mod)
					if N > len(modifiers2.keys()):
						N = len(modifiers2.keys())
					for k in N:
						var modifier_keys:Array = modifiers2.keys()
						modifier_keys.shuffle()
						var key:String = modifier_keys[0]
						if modifiers2[key].has("double_treasure_at"):
							var mod_power:float = log(1.0 / randf() + 0.5) / max(range_lerp(log(system_data[c_s].diff) / log(20), 0.0, 4.0, 2.0, 1.0), 1.0)
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
				if not modifiers.empty():
					tile_data[t_id].cave.modifiers = modifiers
				if not achievement_data.exploration.has("aurora_cave") and tile_data[t_id].has("aurora"):
					earn_achievement("exploration", "aurora_cave")
				if not achievement_data.exploration.has("volcano_aurora_cave") and tile_data[t_id].has("ash") and tile_data[t_id].has("aurora"):
					earn_achievement("exploration", "volcano_aurora_cave")
				continue
			if c_s_g != 0 and randf() < volcano_probability:
				var VEI:float = log(1e6/(coldest_star_temp * u_i.gravitational * randf()) + exp(3.0))
				total_VEI += VEI
				generate_volcano(t_id, VEI)
				continue
			var crater_size = max(0.25, pow(p_i.pressure, 0.3))
			if randf() < 15 / crater_size / pow(coldest_star_temp, 0.8):
				tile_data[t_id] = {} if not tile_data[t_id] else tile_data[t_id]
				if tile_data[t_id].has("ash"):
					continue
				tile_data[t_id].crater = {}
				tile_data[t_id].crater.variant = randi() % 2 + 1
				var depth = ceil(pow(10, rand_range(2, 3)) * pow(crater_size, 0.8))
				tile_data[t_id].crater.init_depth = depth
				tile_data[t_id].depth = depth
				tile_data[t_id].crater.metal = "lead"
				crater_num += 1
				for met in met_info:
					if met == "lead":
						continue
					if randf() < 0.3 / pow(met_info[met].rarity, 0.95):
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
	var unique_bldgs_list = {	"spaceport":log(p_i.pressure + 1), 
								"mineral_replicator":1.0 + total_VEI / 6.0,
								"observatory":max(-log(p_i.pressure / 2.0 + 0.001), 0),
								"mining_outpost":1.0 + 15.0 * crater_num / pow(wid, 2),
								"aurora_generator":5.0 if diff == 0 else 1.0,
								"substation":max(-log(p_i.pressure / 10.0 + 0.1), 0),
								"cellulose_synthesizer":log(p_i.pressure * (1.0 + p_i.atmosphere.CH4 + p_i.atmosphere.CO2 + p_i.atmosphere.H + p_i.atmosphere.O + p_i.atmosphere.H2O) + 1)}
	var unique_bldgs_list_without_NFR = unique_bldgs_list.duplicate()
	if c_s_g != 0:
		unique_bldgs_list.nuclear_fusion_reactor = log(p_i.pressure * (1.0 + p_i.atmosphere.CH4 + p_i.atmosphere.H + p_i.atmosphere.H2O) + 1)
	var S = 0.0
	var S2 = 0.0
	for unique_bldg in unique_bldgs_list.keys():
		S += unique_bldgs_list[unique_bldg]
	for unique_bldg in unique_bldgs_list.keys():
		unique_bldgs_list[unique_bldg] /= S
	for unique_bldg in unique_bldgs_list_without_NFR.keys():
		S2 += unique_bldgs_list_without_NFR[unique_bldg]
	for unique_bldg in unique_bldgs_list_without_NFR.keys():
		unique_bldgs_list_without_NFR[unique_bldg] /= S2
	var nuclear_fusion_reactor_tiles = []
	var base_unique_bldg_probability = 0.0
	if randf() < 500.0 / coldest_star_temp:
		base_unique_bldg_probability = 1 if p_i.temperature < 273 else -pow((p_i.temperature / 273.0 - 1), 2) + 1
	planet_data[id].unique_bldgs = {}
	if not home_planet:
		var spaceport_spawned = false
		for t_id in empty_tiles:
			if t_id in nuclear_fusion_reactor_tiles:
				continue
			if randf() < 0.1 / pow(wid, 0.5) * base_unique_bldg_probability:
				var i = t_id % wid
				var j = t_id / wid
				var unique_bldg
				var rand2 = randf()
				var k = 0
				var S3 = 0
				if i == wid-1 or j == wid-1:
					for _unique_bldg in unique_bldgs_list_without_NFR.keys():
						if rand2 < unique_bldgs_list_without_NFR[_unique_bldg] + S3:
							unique_bldg = _unique_bldg
							break
						else:
							k += 1
							S3 += unique_bldgs_list_without_NFR[_unique_bldg]
				else:
					for _unique_bldg in unique_bldgs_list.keys():
						if rand2 < unique_bldgs_list[_unique_bldg] + S3:
							unique_bldg = _unique_bldg
							break
						else:
							k += 1
							S3 += unique_bldgs_list[_unique_bldg]
					if unique_bldg == "nuclear_fusion_reactor":
						nuclear_fusion_reactor_tiles.append_array([t_id+1, t_id+wid, t_id+wid+1])
				if unique_bldg == "spaceport":
					if spaceport_spawned:
						continue
					spaceport_spawned = true					#Save migration
				var obj = {"tile":t_id, "tier":int(-log(randf() / u_i.get("age", 1) / u_i.cluster_data[c_c].FM) / 4.0 + 1)}
				if randf() < 1.0 - 0.5 * exp(-pow(p_i.temperature - 273, 2) / 20000.0) / pow(obj.tier, 2):
					obj.repair_cost = 250000 * system_data[c_s].diff * pow(obj.tier, 50) * rand_range(1, 3) * Data.unique_bldg_repair_cost_multipliers[unique_bldg]
				if p_i.unique_bldgs.has(unique_bldg):
					p_i.unique_bldgs[unique_bldg].append(obj)
				else:
					p_i.unique_bldgs[unique_bldg] = [obj]
	if p_i.id == 6:#Guaranteed wormhole spawn on furthest planet in solar system
		var random_tile:int = randi() % len(tile_data)
		erase_tile(random_tile)
		var dest_id:int = Helper.rand_int(1, SYS_NUM - 1)#				local_destination_system_id		global_dest_s_id
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id}
		p_i.wormhole = true
	elif c_s_g != 0 and randf() < 0.1:#10% chance to spawn a wormhole on a planet outside solar system
		var random_tile:int = randi() % len(tile_data)
		erase_tile(random_tile)
		var dest_id:int = randi() % len(system_data)
		tile_data[random_tile].wormhole = {"active":false, "new":true, "l_dest_s_id":dest_id, "g_dest_s_id":dest_id + system_data[0].id}
		p_i.wormhole = true#								new: whether the wormhole should generate a new wormhole on another planet
	if p_i.has("lake_1") and p_i.lake_1.state == "g":
		p_i.erase("lake_1")
	if p_i.has("lake_2") and p_i.lake_2.state == "g":
		p_i.erase("lake_2")
	planet_data[id]["discovered"] = true
	if home_planet:
		tile_data[42] = {}
		tile_data[42].cave = {"num_floors":5, "floor_size":25, "period":65, "debris":0.3}
		tile_data[215] = {}
		tile_data[215].cave = {"num_floors":8, "floor_size":30, "period":50, "debris":0.4}
		tile_data[112] = {}
		tile_data[112].ship = true
		p_i.unique_bldgs = {"spaceport":[{"tile":113, "tier":1, "repair_cost":10000 * Data.unique_bldg_repair_cost_multipliers.spaceport}],
							"mineral_replicator":[{"tile":55, "tier":1, "repair_cost":10000 * Data.unique_bldg_repair_cost_multipliers.mineral_replicator}]}
	elif c_p_g == 2:
		var N:int = len(tile_data)
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
		var mineral_replicator = {"tile":random_tile3, "tier":int(-log(randf() / u_i.get("age", 1)) / 4.0 + 1)}
		var spaceport:Dictionary
		mineral_replicator.repair_cost = 10000 * system_data[c_s].diff * pow(mineral_replicator.tier, 50) * rand_range(1, 5) * Data.unique_bldg_repair_cost_multipliers.mineral_replicator
		if random_tile == N-1:
			spaceport = {"tile":random_tile - 1, "tier":int(-log(randf() / u_i.get("age", 1)) / 4.0 + 1)}
			erase_tile(random_tile - 1) 														# Save migration
		else:
			spaceport = {"tile":random_tile + 1, "tier":int(-log(randf() / u_i.get("age", 1)) / 4.0 + 1)}
			erase_tile(random_tile + 1)
		spaceport.repair_cost = 10000 * system_data[c_s].diff * pow(spaceport.tier, 50) * rand_range(1, 5) * Data.unique_bldg_repair_cost_multipliers.spaceport
		p_i.unique_bldgs = {"spaceport":[spaceport], "mineral_replicator":[mineral_replicator]}
		tile_data[random_tile2].cave = {"num_floors":8, "floor_size":30, "period":50, "debris":0.4}
	for bldg in p_i.unique_bldgs.keys():
		for i in len(p_i.unique_bldgs[bldg]):
			var tier = p_i.unique_bldgs[bldg][i].tier
			var t_id = p_i.unique_bldgs[bldg][i].tile
			for j in ([t_id, t_id+1, t_id+wid, t_id+1+wid] if bldg == "nuclear_fusion_reactor" else [t_id]):
				if tile_data[j]:
					tile_data[j].unique_bldg = {"name":bldg, "tier":tier, "id":i}
				else:
					tile_data[j] = {"unique_bldg":{"name":bldg, "tier":tier, "id":i}}
				if p_i.unique_bldgs[bldg][i].has("repair_cost"):
					tile_data[j].unique_bldg.repair_cost = p_i.unique_bldgs[bldg][i].repair_cost
			if not p_i.unique_bldgs[bldg][i].has("repair_cost"):
				Helper.set_unique_bldg_bonuses(p_i, tile_data[t_id].unique_bldg, t_id, wid)
			if not achievement_data.exploration.has("tier_2_unique_bldg") and tier >= 2:
				earn_achievement("exploration", "tier_2_unique_bldg")
			if not achievement_data.exploration.has("tier_3_unique_bldg") and tier >= 3:
				earn_achievement("exploration", "tier_3_unique_bldg")
			if not achievement_data.exploration.has("tier_4_unique_bldg") and tier >= 4:
				earn_achievement("exploration", "tier_4_unique_bldg")
			if not achievement_data.exploration.has("tier_5_unique_bldg") and tier >= 5:
				earn_achievement("exploration", "tier_5_unique_bldg")
			if unique_bldgs_discovered.has(bldg):
				unique_bldgs_discovered[bldg] += 1
			else:
				unique_bldgs_discovered[bldg] = 1
			if not achievement_data.exploration.has("find_all_unique_bldgs") and len(unique_bldgs_discovered.keys()) == 8:
				earn_achievement("exploration", "find_all_unique_bldgs")
	
	#Give lake data to adjacent tiles
	var lake_1_au_int:float = 0.0
	var lake_2_au_int:float = 0.0
	if not achievement_data.exploration.has("find_neon_lake"):
		if p_i.has("lake_1") and p_i.lake_1.element == "Ne" or p_i.has("lake_2") and p_i.lake_2.element == "Ne":
			earn_achievement("exploration", "find_neon_lake")
	if not achievement_data.exploration.has("find_xenon_lake"):
		if p_i.has("lake_1") and p_i.lake_1.element == "Xe" or p_i.has("lake_2") and p_i.lake_2.element == "Xe":
			earn_achievement("exploration", "find_xenon_lake")
	if p_i.has("lake_1"):
		if p_i.lake_1.element == "Ne":
			lake_1_au_int = Helper.clever_round(1.2e5 * (rand_range(1, 2)) * B_strength * max_star_temp)
		elif p_i.lake_1.element == "Xe":
			lake_1_au_int = Helper.clever_round(3.6e6 * (rand_range(1, 2)) * B_strength * max_star_temp)
	if p_i.has("lake_2"):
		if p_i.lake_2.element == "Ne":
			lake_2_au_int = Helper.clever_round(1.2e5 * (rand_range(1, 2)) * B_strength * max_star_temp)
		elif p_i.lake_2.element == "Xe":
			lake_2_au_int = Helper.clever_round(3.6e6 * (rand_range(1, 2)) * B_strength * max_star_temp)
	var planet_with_nothing = true
	for i in wid:
		for j in wid:
			var t_id = i % wid + j * wid
			var tile = tile_data[t_id]
			if tile:
				planet_with_nothing = false
			if tile and tile.has("lake"):
				var lake_info = p_i["lake_%s" % tile.lake]
				var distance_from_lake:int = 1
				if lake_info.element in ["H", "Xe"]:
					distance_from_lake += Data.lake_bonus_values[lake_info.element][lake_info.state] + biology_bonus[lake_info.element]
				for k in range(max(0, i - distance_from_lake), min(i + distance_from_lake + 1, wid)):
					for l in range(max(0, j - distance_from_lake), min(j + distance_from_lake + 1, wid)):
						var id2 = k % wid + l * wid
						if tile_data[id2] and tile_data[id2].has("lake") or Vector2(k, l) == Vector2(i, j):
							continue
						if not tile_data[id2]:
							tile_data[id2] = {}
						if tile.lake == 1 and lake_1_au_int > 0.0:
							if tile_data[id2].has("aurora"):
								if not tile_data[id2].has("lake_elements"):
									tile_data[id2].aurora.au_int += lake_1_au_int + 1.0
								else:
									tile_data[id2].aurora.au_int = max(lake_1_au_int, tile_data[id2].aurora.au_int)
							else:
								tile_data[id2].aurora = {"au_int":lake_1_au_int}
						elif tile.lake == 2 and lake_2_au_int > 0.0:
							if tile_data[id2].has("aurora"):
								if not tile_data[id2].has("lake_elements"):
									tile_data[id2].aurora.au_int += lake_2_au_int + 1.0
								else:
									tile_data[id2].aurora.au_int = max(lake_2_au_int, tile_data[id2].aurora.au_int)
							else:
								tile_data[id2].aurora = {"au_int":lake_2_au_int}
						if tile_data[id2].has("lake_elements"):
							tile_data[id2].lake_elements[lake_info.element] = lake_info.state
						else:
							tile_data[id2].lake_elements = {lake_info.element:lake_info.state}
	if not achievement_data.exploration.has("planet_with_nothing") and planet_with_nothing:
		earn_achievement("exploration", "planet_with_nothing")
	Helper.save_obj("Planets", c_p_g, tile_data)
	Helper.save_obj("Systems", c_s_g, planet_data)
	tile_data.clear()

func erase_tile(random_tile:int):
	if not tile_data[random_tile] or not tile_data[random_tile].has("aurora"):
		tile_data[random_tile] = {}
	else:
		tile_data[random_tile] = {"aurora":tile_data[random_tile].aurora}

func make_atmosphere_composition(temp:float, pressure:float, list_of_element_probabilities:Dictionary):
	var atm = {}
	var S:float = 0
	for el in list_of_element_probabilities.keys():
		var phase_scene = load("res://Scenes/PhaseDiagrams/" + el + ".tscn")
		var phase = phase_scene.instance()
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
	var big_planet_factor:float = clamp(range_lerp(size, 12500, 45000, 1, 5), 1, 5)
	var FM:float = u_i.cluster_data[c_c].FM
	if not gas_giant or depth == "core":
		if depth == "crust":
			var O = rand_range(1.0, 1.9)
			elements = {	"O":O,
							"Si":O * rand_range(3.9, 4),
							"Al":0.05 * randf(),
							"Fe":0.035 * FM * randf(),
							"Na":0.025 * randf(),
							"Ti":0.005 * randf(),
							"H":0.01 * big_planet_factor * randf(),
							"C":0.01 * big_planet_factor * randf(),
							"He":0.003 * big_planet_factor * randf(),
						}
		elif depth == "mantle":
			var O = rand_range(1.5, 1.9)
			elements = {	"O":O,
							"Si":O * rand_range(3.9, 4),
							"Al":0.05 * randf(),
							"Fe":0.035 * randf(),
							"Na":0.025 * randf(),
							"H":0.01 * big_planet_factor * randf(),
							"C":0.01 * big_planet_factor * randf(),
							"Ti":0.005 * randf(),
							"He":0.003 * big_planet_factor * randf(),
						}
		else:
			var x:float = rand_range(1, 10) * FM
			var y:float = rand_range(0, 5) * FM
			elements["Fe"] = x/(x+1)
			elements["Ni"] = (1 - Helper.get_sum_of_dict(elements)) * y/(y+1)
			elements["O"] = (1 - Helper.get_sum_of_dict(elements)) * rand_range(0, 0.19)
			elements["Si"] = elements["O"] * rand_range(3.9, 4)
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
	var surface_mat_info = {	"coal":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":rand_range(50, 150)},
								"glass":{"chance":0.1, "amount":4},
								"sand":{"chance":0.8, "amount":50},
								#"clay":{"chance":rand_range(0.05, 0.3), "amount":rand_range(30, 80)},
								"soil":{"chance":rand_range(0.1, 0.8), "amount":rand_range(30, 100)},
								"cellulose":{"chance":exp(-0.001 * pow(temp - 273, 2)), "amount":rand_range(15, 45)}
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

func show_adv_tooltip(txt:String, imgs:Array = [], size:int = 17):
	if is_instance_valid(tooltip):
		tooltip.queue_free()
	tooltip = preload("res://Scenes/AdvTooltip.tscn").instance()
	tooltip.modulate.a = 0.0
	$Tooltips.add_child(tooltip)
	add_text_icons(tooltip, txt, imgs, size, true)
	yield(get_tree(), "idle_frame")
	set_tooltip_position()
	tooltip_tween.interpolate_property(tooltip, "modulate", null, Color.white, 0.1)
	tooltip_tween.start()

func show_tooltip(txt:String, hide:bool = true):
	if is_instance_valid(tooltip):
		tooltip.queue_free()
	tooltip = preload("res://Scenes/Tooltip.tscn").instance()
	tooltip.modulate.a = 0.0
	tooltip.text = txt
	$Tooltips.add_child(tooltip)
	if tooltip.rect_size.x > 400:
		tooltip.autowrap = true
		tooltip.rect_size.x = 400
	set_tooltip_position()
	tooltip_tween.interpolate_property(tooltip, "modulate", null, Color.white, 0.1)
	tooltip_tween.start()

func hide_tooltip():
	if is_instance_valid(tooltip):
		tooltip.visible = false

func hide_adv_tooltip():
	hide_tooltip()

func add_text_icons(RTL:RichTextLabel, txt:String, imgs:Array, size:int = 17, _tooltip:bool = false):
	RTL.text = ""
	var arr = txt.split("@i")#@i: where images are placed
	var i = 0
	for st in arr:
		if RTL.append_bbcode(st) != OK:
			return
		if i < len(imgs) and imgs[i]:
			RTL.add_image(imgs[i], 0, size)
		i += 1
	if _tooltip:
		var arr2 = txt.split("\n")
		var max_width = 0
		for st in arr2:
			var bb_start:int = st.find("[")
			var bb_end:int = st.find("]")
			while bb_start != -1 and bb_end != -1:
				st = st.replace(st.substr(bb_start, bb_end - bb_start + 1), "")
				bb_start = st.find("[")
				bb_end = st.find("]")
			var width = min(default_font.get_string_size(st).x + 10, 400)
			max_width = max(width, max_width)
		RTL.rect_size.x = max_width# + 60
		RTL.rect_min_size.x = max_width# + 60
	yield(get_tree(), "idle_frame")
	if is_instance_valid(RTL):
		RTL.rect_min_size.y = RTL.get_content_height()
		RTL.rect_size.y = RTL.get_content_height()

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
	elif temp < 1000000:
		cl = "Z" + String(max(floor(10 - (temp - 210000) / 790000 * 10), 0))
	return cl

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
		if atoms.has(cost) and atoms[cost] < costs[cost]:
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
				new_bldgs.GF = true
			elif cost == "coal":
				new_bldgs.SE = true
			elif cost == "stone":
				new_bldgs.SC = true

func e(n, e):
	return n * pow(10, e)

var quadrant_top_left:PoolVector2Array = [Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]
var quadrant_top_right:PoolVector2Array = [Vector2(640, 0), Vector2(1280, 0), Vector2(1280, 360), Vector2(640, 360)]
var quadrant_bottom_left:PoolVector2Array = [Vector2(0, 360), Vector2(640, 360), Vector2(640, 720), Vector2(0, 720)]
var quadrant_bottom_right:PoolVector2Array = [Vector2(640, 360), Vector2(1280, 360), Vector2(1280, 720), Vector2(640, 720)]
onready var fps_text = $Tooltips/FPS

func _process(delta):
	if delta != 0:
		fps_text.text = "%s FPS" % [Engine.get_frames_per_second()]
		if autocollect:
			var min_mult:float = pow(maths_bonus.IRM, infinite_research.MEE) * u_i.time_speed
			var energy_mult:float = pow(maths_bonus.IRM, infinite_research.EPE) * u_i.time_speed
			var SP_mult:float = pow(maths_bonus.IRM, infinite_research.RLE) * u_i.time_speed
			var min_to_add:float = delta * (autocollect.MS.minerals + autocollect.GS.minerals) * min_mult
			var energy_to_add = delta * (autocollect.MS.energy + autocollect.GS.energy) * energy_mult
			SP += delta * (autocollect.MS.SP + autocollect.GS.SP) * SP_mult
			min_to_add += autocollect.rsrc.minerals * delta * min_mult
			energy_to_add += autocollect.rsrc.energy * delta * energy_mult
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
			particles.proton += autocollect.particles.proton * delta * u_i.time_speed
			particles.neutron += autocollect.particles.neutron * delta * u_i.time_speed
			particles.electron += autocollect.particles.electron * delta * u_i.time_speed
			if particles.neutron > neutron_cap * Helper.get_IR_mult("NSF"):
				var diff:float = particles.neutron - neutron_cap * Helper.get_IR_mult("NSF")
				var amount_decayed:float = diff * pow(0.5, delta * u_i.time_speed / 900.0) #900 seconds = 15 minutes
				particles.neutron -= diff - amount_decayed
				particles.proton += (diff - amount_decayed) / 2.0
				particles.electron += (diff - amount_decayed) / 2.0
			if particles.electron > electron_cap * Helper.get_IR_mult("ESF"):
				particles.electron = electron_cap * Helper.get_IR_mult("ESF")
			if is_instance_valid(HUD) and is_a_parent_of(HUD):
				HUD.update_minerals()
				HUD.update_money_energy_SP()
			if tutorial and tutorial.tut_num == 24 and objective.has("current"):
				if objective.current != SP:
					HUD.refresh()

var mouse_pos = Vector2.ZERO
onready var item_cursor = $Tooltips/ItemCursor

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

func set_tooltip_position():
	if op_cursor:
		if Geometry.is_point_in_polygon(mouse_pos, quadrant_top_left) or Geometry.is_point_in_polygon(mouse_pos, quadrant_bottom_left):
			tooltip.rect_position = mouse_pos - Vector2(-9, tooltip.rect_size.y + 9)
		else:
			tooltip.rect_position = mouse_pos - tooltip.rect_size - Vector2(9, 9)
	else:
		if mouse_pos.x < 1280 - tooltip.rect_size.x:
			tooltip.rect_position.x = mouse_pos.x + 9
		else:
			tooltip.rect_position.x = mouse_pos.x - tooltip.rect_size.x - 9
		if mouse_pos.y < 720 - tooltip.rect_size.y - 16:
			tooltip.rect_position.y = mouse_pos.y + 9
		else:
			tooltip.rect_position.y = mouse_pos.y - tooltip.rect_size.y - 9

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if not stats_global.empty() and c_u != -1:
			stats_global.mouse_travel_distance += event.relative.length()
			stats_dim.mouse_travel_distance += event.relative.length()
			stats_univ.mouse_travel_distance += event.relative.length()
		$Tooltips/CtrlShift.rect_position = mouse_pos - Vector2(87, 17)
	elif event is InputEventKey:
		if event.is_pressed() and not stats_global.empty() and c_u != -1:
			stats_global.keyboard_presses += 1
			stats_dim.keyboard_presses += 1
			stats_univ.keyboard_presses += 1
		$Tooltips/CtrlShift/Ctrl.visible = Input.is_action_pressed("ctrl")
		$Tooltips/CtrlShift/Shift.visible = Input.is_action_pressed("shift")
		$Tooltips/CtrlShift/Alt.visible = Input.is_action_pressed("alt")
	elif event is InputEventMouseButton and not stats_global.empty() and c_u != -1:
		if Input.is_action_just_pressed("left_click"):
			stats_global.clicks += 1
			stats_dim.clicks += 1
			stats_univ.clicks += 1
		if Input.is_action_just_pressed("right_click"):
			stats_global.right_clicks += 1
			stats_dim.right_clicks += 1
			stats_univ.right_clicks += 1
		if Input.is_action_just_pressed("scroll"):
			stats_global.scrolls += 1
			stats_dim.scrolls += 1
			stats_univ.scrolls += 1
	if is_instance_valid(stats_panel) and stats_panel.visible and stats_panel.get_node("Statistics").visible and stats_panel.curr_stat_tab == "_on_UserInput_pressed":
		stats_panel._on_UserInput_pressed()
	if is_instance_valid(tooltip):
		set_tooltip_position()
	if item_cursor.visible:
		item_cursor.position = mouse_pos
#	if ship_locator:
#		ship_locator.position = mouse_pos
#		var ship_pos:Vector2 = system_data[second_ship_hints.spawned_at].pos
#		var local_mouse_pos:Vector2 = view.obj.to_local(mouse_pos)
#		ship_locator.get_node("Arrow").rotation = atan2(ship_pos.y - local_mouse_pos.y, ship_pos.x - local_mouse_pos.x)
#		if c_v == "STM" and event.get_relative() != Vector2.ZERO:
#			STM.move_ship_inst = true

	#Press F11 to toggle fullscreen
	if Input.is_action_just_released("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		settings.get_node("TabContainer/GRAPHICS/Fullscreen").pressed = OS.window_fullscreen

	if Input.is_action_just_released("right_click"):
		if bottom_info_action != "":
			if not c_v in ["STM", ""]:
				item_to_use.num = 0
				update_item_cursor()
		elif not tutorial or tutorial.tut_num >= 26:
			if is_instance_valid(sub_panel):
				sub_panel.visible = false
				sub_panel = null
			elif is_instance_valid(active_panel):
				if c_v != "":
					if is_instance_valid(sub_panel):
						sub_panel.visible = false
						sub_panel = null
					else:
						fade_out_panel(active_panel)
						active_panel = null
				else:
					toggle_panel(active_panel)
				hide_tooltip()
				hide_adv_tooltip()
	
	#F3 to toggle overlay
	if Input.is_action_just_released("toggle"):
		if is_instance_valid(overlay):
			overlay.toggle_btn.pressed = not overlay.toggle_btn.pressed
		elif is_instance_valid(element_overlay):
			element_overlay.toggle_btn.pressed = not element_overlay.toggle_btn.pressed
		
	#J to hide help
	if Input.is_action_just_released("J") and help_str != "":
		if help.has(help_str):
			help.erase(help_str)
		else:
			help[help_str] = true
		hide_tooltip()
		hide_adv_tooltip()
		$UI/Panel.visible = false
		if $UI.has_node("BuildingShortcuts"):
			$UI.get_node("BuildingShortcuts").queue_free()
	
	var cmd_node = $Tooltips/Command
	#/ to type a command
	if Input.is_action_just_released("command") and not cmd_node.visible and c_v != "":
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
			"fc":
				if c_v == "planet":
					for tile in tile_data:
						if tile:
							if tile.has("bldg") and tile.bldg.has("is_constructing"):
								var diff_time = tile.bldg.construction_date + tile.bldg.construction_length - OS.get_system_time_msecs()
								tile.bldg.construction_length = 1
								if tile.bldg.has("collect_date"):
									tile.bldg.collect_date -= diff_time
								if tile.bldg.has("start_date"):
									tile.bldg.start_date -= diff_time
								if tile.bldg.has("overclock_date"):
									tile.bldg.overclock_date -= diff_time
							elif tile.has("wormhole") and tile.wormhole.has("investigation_length"):
								tile.wormhole.investigation_length = 1
				for probe in probe_data:
					if probe and probe.has("start_date"):
						var diff_time = probe.start_date + probe.explore_length - OS.get_system_time_msecs()
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
				if arr[2] == "xp":
					Helper.add_ship_XP(int(arr[1]), float(arr[3]))
				elif arr[2] in ["bullet", "laser", "bomb", "light"]:
					Helper.add_weapon_XP(int(arr[1]), arr[2], float(arr[3]))
				else:
					popup("\"%s\" isn't a valid XP type" % arr[2], 2.0)
					return
			"fixshipdata":
				for sh in ship_data:
					sh.rage = 0
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
	
	if Input.is_action_just_pressed("S") and Input.is_action_pressed("ctrl"):
		if c_v != "":
			fn_save_game()
			save_views(false)

func _unhandled_key_input(event):
	var hotbar_presses = [Input.is_action_just_released("1"), Input.is_action_just_released("2"), Input.is_action_just_released("3"), Input.is_action_just_released("4"), Input.is_action_just_released("5"), Input.is_action_just_released("6"), Input.is_action_just_released("7"), Input.is_action_just_released("8"), Input.is_action_just_released("9"), Input.is_action_just_released("0")]
	if not c_v in ["battle", "cave", ""] and not viewing_dimension and not shop_panel.visible and not craft_panel.visible and not shipyard_panel.visible and not upgrade_panel.visible and not is_instance_valid(overlay):
		for i in 10:
			if len(hotbar) > i and hotbar_presses[i]:
				var _name = hotbar[i]
				if get_item_num(_name) > 0:
					inventory.on_slot_press(_name)

func fn_save_game():
	var save_info_file = File.new()
	save_info_file.open("user://%s/save_info.hx3" % [c_sv], File.WRITE)
	var save_info:Dictionary = {
		"save_created":save_created,
		"save_modified":OS.get_system_time_msecs(),
		"help":help,
		"c_u":c_u,
		"universe_data":universe_data,
		"version":VERSION,
		"DRs":DRs,
		"dim_num":dim_num,
		"subjects":subjects,
		"maths_bonus":maths_bonus,
		"physics_bonus":physics_bonus,
		"chemistry_bonus":chemistry_bonus,
		"biology_bonus":biology_bonus,
		"engineering_bonus":engineering_bonus,
		"stats_global":stats_global,
		"stats_dim":stats_dim,
		"achievement_data":achievement_data,
	}
	save_info_file.store_var(save_info)
	save_info_file.close()
	if c_u == -1:
		return
	var save_game = File.new()
	save_game.open("user://%s/Univ%s/main.hx3" % [c_sv, c_u], File.WRITE)
	if c_v == "cave" and is_instance_valid(cave):
		var cave_data_file = File.new()
		cave_data_file.open("user://%s/Univ%s/Caves/%s.hx3" % [c_sv, c_u, cave.id], File.WRITE)
		var cave_data_dict = {
			"seeds":cave.seeds.duplicate(true),
			"tiles_mined":cave.tiles_mined.duplicate(true),
			"enemies_rekt":cave.enemies_rekt.duplicate(true),
			"chests_looted":cave.chests_looted.duplicate(true),
			"partially_looted_chests":cave.partially_looted_chests.duplicate(true),
			"hole_exits":cave.hole_exits.duplicate(true),
		}
		cave_data_file.store_var(cave_data_dict)
		cave_data_file.close()
	save_date = OS.get_system_time_msecs()
	var save_game_dict = {
		"money":money,
		"minerals":minerals,
		"mineral_capacity":mineral_capacity,
		"energy_capacity":energy_capacity,
		"capacity_bonus_from_substation":capacity_bonus_from_substation,
		"neutron_cap":neutron_cap,
		"electron_cap":electron_cap,
		"stone":stone,
		"energy":energy,
		"SP":SP,
		"aurora_prod":aurora_prod,
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
		"second_ship_hints":second_ship_hints,
		"third_ship_hints":third_ship_hints,
		"fourth_ship_hints":fourth_ship_hints,
		"ships_c_coords":ships_c_coords,
		"ships_dest_coords":ships_dest_coords,
		"ships_depart_pos":ships_depart_pos,
		"ships_dest_pos":ships_dest_pos,
		"ships_travel_view":ships_travel_view,
		"ships_c_g_coords":ships_c_g_coords,
		"ships_dest_g_coords":ships_dest_g_coords,
		"ships_travel_start_date":ships_travel_start_date,
		"ships_travel_length":ships_travel_length,
		"p_num":p_num,
		"s_num":s_num,
		"g_num":g_num,
		"c_num":c_num,
		"stats_univ":stats_univ,
		"objective":objective,
		"autocollect":autocollect,
		"save_date":save_date,
		"bookmarks":bookmarks,
		"unique_bldgs_discovered":unique_bldgs_discovered,
		"cave_filters":cave_filters,
		"caves_generated":caves_generated,
		"MM_data":MM_data,
	}
	save_game.store_var(save_game_dict)
	save_game.close()

func save_views(autosave:bool):
	if is_instance_valid(view.obj) and is_a_parent_of(view.obj):
		view.save_zooms(c_v)
	if c_v in ["planet", "mining"]:
		Helper.save_obj("Planets", c_p_g, tile_data)
		Helper.save_obj("Systems", c_s_g, planet_data)
	elif c_v == "system":
		Helper.save_obj("Systems", c_s_g, planet_data)
		Helper.save_obj("Galaxies", c_g_g, system_data)
	elif c_v == "galaxy":
		if send_probes_panel.is_processing() or send_fighters_panel.is_processing():
			Helper.save_obj("Galaxies", c_g_g, system_data)
		Helper.save_obj("Clusters", c_c, galaxy_data)
	elif c_v == "cluster":
		Helper.save_obj("Clusters", c_c, galaxy_data)
	if not autosave:
		popup(tr("GAME_SAVED"), 1.2)

var ship_locator

func show_ship_locator():
	ship_locator = preload("res://Scenes/ShipLocator.tscn").instance()
	add_child(ship_locator)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func hide_ship_locator():
	remove_child(ship_locator)
	ship_locator = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func show_item_cursor(texture):
	item_cursor.get_node("Sprite").texture = texture
	item_cursor.get_node("Num").text = "x " + String(item_to_use.num)
	#update_item_cursor()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	item_cursor.position = mouse_pos
	item_cursor.visible = true

func update_item_cursor():
	if item_to_use.num <= 0:
		_on_BottomInfo_close_button_pressed()
		item_to_use = {"name":"", "type":"", "num":0}
	else:
		item_cursor.get_node("Num").text = "x " + String(item_to_use.num)
	if is_instance_valid(HUD):
		HUD.update_hotbar()

func hide_item_cursor():
	item_to_use = {"name":"", "type":"", "num":0}
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
	$UI/Panel.visible = false
	view.obj.finish_construct()

func _on_Settings_mouse_entered():
	show_tooltip(tr("SETTINGS") + " (P)")

func _on_Settings_mouse_exited():
	hide_tooltip()

func _on_Settings_pressed():
	$click.play()
	toggle_panel(settings)

func _on_BottomInfo_close_button_pressed(direct:bool = false):
	close_button_over = false
	if bottom_info_shown:
		bottom_info_shown = false
		hide_tooltip()
		if $UI/BottomInfo/CloseButton.on_close != "":
			call($UI/BottomInfo/CloseButton.on_close)
		$UI/BottomInfo/CloseButton.on_close = ""
		bottom_info_action = ""
		if tutorial and tutorial.tut_num == 6:
			tutorial.fade(0.4, false)
			tutorial.get_node("RsrcCheckTimer").start()
		HUD.refresh()
		if not direct:
			b_i_tween.stop_all()
			b_i_tween.remove_all()
			b_i_tween.interpolate_property($UI/BottomInfo, "rect_position", null, Vector2(0, 720), 0.5, Tween.TRANS_CIRC, Tween.EASE_OUT)
			b_i_tween.start()
			yield(b_i_tween, "tween_all_completed")
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
	$Title/Menu/VBoxContainer/NewGame.disconnect("pressed", self, "_on_NewGame_pressed")
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property($Title, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_property($TitleBackground, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_property($Stars/Stars/Sprite.material, "shader_param/brightness_offset", 0.0, 0.5)
	tween.tween_property($Stars/Stars, "modulate", Color(1, 1, 1, 0), 0.5)
	yield(tween, "finished")
	$Stars/Stars/Sprite.visible = false
	$Title.visible = false
	$Settings/Settings.visible = true
	switch_music(load("res://Audio/ambient" + str(Helper.rand_int(1, 3)) + ".ogg"))
	HUD = preload("res://Scenes/HUD.tscn").instance()
	if fn == "new_game":
		new_game(false, 0, true)
	else:
		call(fn)
		add_panels()
		$Autosave.start()
	
func _on_NewGame_pressed():
	fade_out_title("new_game")

func _on_LoadGame_pressed():
	toggle_panel(load_panel)

func _on_Autosave_timeout():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		if config.get_value("saving", "enable_autosave", true):
			fn_save_game()
			if not viewing_dimension:
				save_views(true)

var YN_str:String = ""
func show_YN_panel(type:String, text:String, args:Array = [], title:String = "Please Confirm..."):
	$UI/PopupBackground.visible = true
	var width = min(800, default_font.get_string_size(text).x) + 40
	YN_panel.rect_min_size.x = width
	YN_panel.rect_min_size.y = 0
	YN_panel.rect_size.y = 0
	YN_panel.rect_size.x = width
	YN_panel.dialog_text = text
	YN_panel.window_title = title
	YN_panel.popup_centered()
	YN_str = type
	if type in ["buy_pickaxe", "destroy_building", "destroy_buildings", "op_galaxy", "conquer_all", "destroy_tri_probe", "reset_dimension"]:
		if YN_panel.is_connected("confirmed", self, "%s_confirm" % type):
			YN_panel.disconnect("confirmed", self, "%s_confirm" % type)
		YN_panel.connect("confirmed", self, "%s_confirm" % type, args)
	else:
		YN_panel.connect("confirmed", self, "%s_confirm" % type)

func return_to_menu_confirm():
	$Ship.visible = false
	$Autosave.stop()
	switch_view("")
	switch_music(load("res://Audio/Title.ogg"))
	HUD.queue_free()
	$Title/Menu/VBoxContainer/NewGame.connect("pressed", self, "_on_NewGame_pressed")
	$Title.visible = true
	$Stars/Stars/Sprite.visible = true
	animate_title_buttons()

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
	Data.MUs.AIE.pw = maths_bonus.MUCGF_AIE
	for el in PD_panel.bonuses.keys():
		chemistry_bonus[el] = PD_panel.bonuses[el]
	dimension.refresh_univs()
	YN_panel.disconnect("confirmed", self, "generate_new_univ_confirm")

func destroy_tri_probe_confirm(probe_id:int):
	probe_data.remove(probe_id)
	vehicle_panel.probe_over_id = -1
	vehicle_panel.refresh()
	YN_panel.disconnect("confirmed", self, "destroy_tri_probe_confirm")

func discover_univ_confirm():
	send_probes_panel.discover_univ()
	YN_panel.disconnect("confirmed", self, "discover_univ_confirm")

func reset_dimension_confirm(DR_num:int):
	c_u = -1
	DRs += DR_num
	for i in len(universe_data):
		Helper.remove_recursive("user://%s/Univ%s" % [c_sv, i])
	if not achievement_data.progression.has("new_dimension"):
		earn_achievement("progression", "new_dimension")
	universe_data.clear()
	dim_num += 1
	if not help.has("DR_reset"):
		dimension.get_node("ColorRect").visible = true
		switch_music(null)
	else:
		dimension.refresh_univs(true)
	YN_panel.disconnect("confirmed", self, "reset_dimension_confirm")
	stats_dim = Data.default_stats.duplicate(true)
	fn_save_game()

func buy_pickaxe_confirm(_costs:Dictionary):
	shop_panel.buy_pickaxe(_costs)
	YN_panel.disconnect("confirmed", self, "buy_pickaxe_confirm")

func destroy_buildings_confirm(arr:Array):
	for id in arr:
		view.obj.destroy_bldg(id, true)
	show_collect_info(view.obj.items_collected)
	HUD.refresh()
	YN_panel.disconnect("confirmed", self, "destroy_buildings_confirm")

func destroy_building_confirm(tile_over:int):
	view.obj.destroy_bldg(tile_over)
	show_collect_info(view.obj.items_collected)
	HUD.refresh()
	YN_panel.disconnect("confirmed", self, "destroy_building_confirm")

func send_ships_confirm():
	send_ships_panel.send_ships()
	YN_panel.disconnect("confirmed", self, "send_ships_confirm")

func new_game_confirm():
	fade_out_title("new_game")
	YN_panel.disconnect("confirmed", self, "new_game_confirm")

func op_galaxy_confirm(l_id:int, g_id:int):
	switch_view("galaxy", {"fn":"set_custom_coords", "fn_args":[["c_g", "c_g_g"], [l_id, g_id]]})
	YN_panel.disconnect("confirmed", self, "op_galaxy_confirm")

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
			system_data[c_s].conquered = true
			view.obj.refresh_planets()
			space_HUD.get_node("ConquerAll").visible = false
		else:
			is_conquering_all = true
			c_p = ships_c_coords.p
			switch_view("battle")
	else:
		popup(tr("NOT_ENOUGH_ENERGY"), 2.0)

func show_collect_info(info:Dictionary):
	if info.has("stone") and Helper.get_sum_of_dict(info.stone) == 0:
		info.erase("stone")
	if info.empty():
		return
	add_resources(info)
	var info2:Dictionary = info.duplicate(true)
	if info2.has("stone"):
		info2.stone = Helper.get_sum_of_dict(info2.stone)
	Helper.put_rsrc($UI/Panel/VBox, 32, info2)
	Helper.add_label(tr("YOU_COLLECTED"), 0)
	$UI/Panel.visible = true
	$UI/Panel.modulate.a = 1.0
	$CollectPanelTimer.start(min(2.5, 0.5 + 0.3 * $UI/Panel/VBox.get_child_count()))
	$CollectPanelAnim.stop()

func _on_CollectPanelTimer_timeout():
	$CollectPanelAnim.play("Fade")

func _on_CollectPanelAnim_animation_finished(anim_name):
	$UI/Panel.visible = false
	$UI/Panel.modulate.a = 1.0

func _on_Ship_pressed():
	if Input.is_action_pressed("shift"):
		switch_view("STM")#Ship travel minigame
	else:
		if science_unlocked.has("CD"):
			if not ship_panel.visible:
				toggle_panel(ship_panel)
				ship_panel._on_DriveButton_pressed()

func _on_Ship_mouse_entered():
	show_tooltip("%s: %s\n%s" % [tr("TIME_LEFT"), Helper.time_to_str(ships_travel_length - OS.get_system_time_msecs() + ships_travel_start_date), tr("PLAY_SHIP_MINIGAME")])

func _on_mouse_exited():
	hide_tooltip()

func _on_ConfirmationDialog_popup_hide():
	yield(get_tree(), "idle_frame")
	if YN_panel.is_connected("confirmed", self, "%s_confirm" % YN_str):
		YN_panel.disconnect("confirmed", self, "%s_confirm" % YN_str)

func mine_tile(tile_id:int = -1):
	if pickaxe.has("name"):
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

func game_fade(fn, args:Array = []):
	game_tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 0), 0.5)
	game_tween.start()
	yield(game_tween, "tween_all_completed")
	if fn is Array:
		for i in len(fn):
			callv(fn[i], args[i])
	else:
		callv(fn, args)
	game_tween.interpolate_property(self, "modulate", null, Color(1, 1, 1, 1), 0.5)
	game_tween.start()

func get_2nd_ship():
	if len(ship_data) == 1:
		ship_data.append({"name":tr("SHIP"), "lv":1, "HP":18, "total_HP":18, "atk":15, "def":3, "acc":13, "eva":8, "points":2, "max_points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "ability":"none", "superweapon":"none", "rage":0, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
		Helper.add_ship_XP(1, 2000)
		Helper.add_weapon_XP(1, "bullet", 50)
		Helper.add_weapon_XP(1, "laser", 50)
		Helper.add_weapon_XP(1, "bomb", 50)
		Helper.add_weapon_XP(1, "light", 60)
		if not achievement_data.progression.has("2nd_ship"):
			earn_achievement("progression", "2nd_ship")

func get_3rd_ship():
	if len(ship_data) == 2:
		ship_data.append({"name":tr("SHIP"), "lv":1, "HP":22, "total_HP":22, "atk":12, "def":4, "acc":12, "eva":15, "points":2, "max_points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "ability":"none", "superweapon":"none", "rage":0, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
		Helper.add_ship_XP(2, 60000)
		Helper.add_weapon_XP(2, "bullet", 140)
		Helper.add_weapon_XP(2, "laser", 140)
		Helper.add_weapon_XP(2, "bomb", 140)
		Helper.add_weapon_XP(2, "light", 180)
		if not achievement_data.progression.has("3rd_ship"):
			earn_achievement("progression", "3rd_ship")

func get_4th_ship():
	if len(ship_data) == 3:
		popup(tr("SHIP_CONTROL_SUCCESS"), 1.5)
		ship_data.append({"name":tr("SHIP"),  "lv":1, "HP":18, "total_HP":18, "atk":14, "def":8, "acc":14, "eva":14, "points":2, "max_points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "ability":"none", "superweapon":"none", "rage":0, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
		Helper.add_ship_XP(3, 1000000)
		Helper.add_weapon_XP(3, "bullet", 400)
		Helper.add_weapon_XP(3, "laser", 400)
		Helper.add_weapon_XP(3, "bomb", 400)
		Helper.add_weapon_XP(3, "light", 450)
		if not achievement_data.progression.has("4th_ship"):
			earn_achievement("progression", "4th_ship")


func _on_Command_gui_input(event):
	get_tree().set_input_as_handled()

func earn_achievement(type:String, ach_id:String):
	var ach = preload("res://Scenes/AchievementEarned.tscn").instance()
	ach.get_node("Panel/Type").text = type.capitalize()
	ach.get_node("Panel/Desc").text = achievements[type.to_lower()][ach_id]
	ach.get_node("Panel/TextureRect").texture = stats_panel.get_node("Achievements/ScrollContainer/HBox/Slots/%s/%s" % [type, ach_id]).achievement_icon
	achievement_data[type][ach_id] = true
	ach.add_to_group("achievement_nodes")
	$UI.add_child(ach)
	ach.get_node("AnimationPlayer").connect("animation_finished", self, "on_ach_anim_finished", [ach])
	yield(get_tree().create_timer(0.5 * len(get_tree().get_nodes_in_group("achievement_nodes"))), "timeout")
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
	toggle_panel(mods)


func _on_Discord_pressed():
	OS.shell_open("https://discord.com/invite/gDHcDA3")


func _on_GitHub_pressed():
	OS.shell_open("https://github.com/Apple0726/helixteus-3")


func _on_Godot_pressed():
	OS.shell_open("https://godotengine.org/")


func _on_Discord_mouse_entered():
	show_tooltip("DISCORD_BUTTON")


func _on_GitHub_mouse_entered():
	show_tooltip("GITHUB_BUTTON")


func _on_Godot_mouse_entered():
	show_tooltip("GODOT_BUTTON")

var curr_MM_p = 0

func _on_MMTimer_timeout():
	if c_sv != "":
		var curr_time = OS.get_system_time_msecs()
		var planets_with_MM:Array = MM_data.keys()
		if len(planets_with_MM) == 0:
			return
		if curr_MM_p > len(planets_with_MM)-1:
			curr_MM_p = 0
		var p = planets_with_MM[curr_MM_p]
		if MM_data[p].has("tiles"):
			var p_i = open_obj("Systems", MM_data[p].c_s_g)[MM_data[p].c_p]
			var _tile_data
			if p == c_p_g:
				_tile_data = tile_data
			else:
				_tile_data = open_obj("Planets", p)
			if len(_tile_data) == 0:
				return
			for t_id in MM_data[p].tiles:
				var tile = _tile_data[t_id]
				if not tile or not tile.has("bldg"):
					continue
				var prod_mult = Helper.get_prod_mult(tile)
				var tiles_mined = (curr_time - tile.bldg.collect_date) / 1000.0 * tile.bldg.path_1_value * prod_mult
				if tiles_mined >= 1:
					add_resources(Helper.mass_generate_rock(tile, p_i, int(tiles_mined)))
					tile.bldg.collect_date += int(tiles_mined) * 1000.0 / tile.bldg.path_1_value / prod_mult
					tile.depth += int(tiles_mined)
					if tile.has("crater") and tile.crater.has("init_depth") and tile.depth > 3 * tile.crater.init_depth:
						tile.erase("crater")
			if p != c_p_g:
				Helper.save_obj("Planets", p, _tile_data)
		else:
			var _planet_data:Array
			var p_i:Dictionary
			if MM_data[p].c_s_g == c_s_g:
				p_i = planet_data[MM_data[p].c_p]
			else:
				_planet_data = open_obj("Systems", MM_data[p].c_s_g)
				if _planet_data.empty():
					MM_data.erase(p)
					return
				p_i = _planet_data[MM_data[p].c_p]
			var prod_mult = Helper.get_prod_mult(p_i)
			var tiles_mined = (curr_time - p_i.bldg.collect_date) / 1000.0 * p_i.bldg.path_1_value * prod_mult
			if tiles_mined >= 1:
				var rsrc_mined = Helper.mass_generate_rock(p_i, p_i, int(tiles_mined))
				for rsrc in rsrc_mined.keys():
					if rsrc == "stone":
						for el in rsrc_mined[rsrc].keys():
							rsrc_mined[rsrc][el] *= p_i.tile_num
					else:
						rsrc_mined[rsrc] *= p_i.tile_num
				add_resources(rsrc_mined)
				p_i.bldg.collect_date += int(tiles_mined) / p_i.bldg.path_1_value / prod_mult * 1000.0
				p_i.depth += int(tiles_mined)
			if MM_data[p].c_s_g != c_s_g:
				Helper.save_obj("Systems", MM_data[p].c_s_g, _planet_data)
		curr_MM_p += 1
		if is_instance_valid(HUD):
			HUD.update_money_energy_SP()
