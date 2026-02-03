extends Node

@onready var game = get_node("/root/Game")

enum {
	OVERCLOCK1,
	OVERCLOCK2,
	OVERCLOCK3,
	OVERCLOCK4,
	OVERCLOCK5,
	OVERCLOCK6,
	MINING_LIQUID,
	PURPLE_MINING_LIQUID,
	DRILL1,
	DRILL2,
	DRILL3,
	PORTABLE_WORMHOLE1,
	PORTABLE_WORMHOLE2,
	PORTABLE_WORMHOLE3,
	HELIX_CORE1,
	HELIX_CORE2,
	HELIX_CORE3,
	HELIX_CORE4,
	STONE_ARMOR,
	LEAD_ARMOR,
	COPPER_ARMOR,
	IRON_ARMOR,
	ALUMINIUM_ARMOR,
	SILVER_ARMOR,
	GOLD_ARMOR,
	TITANIUM_ARMOR,
	PLATINUM_ARMOR,
	DIAMOND_ARMOR,
	NANOCRYSTAL_ARMOR,
	MYTHRIL_ARMOR,
	STONE_WHEELS,
	LEAD_WHEELS,
	COPPER_WHEELS,
	IRON_WHEELS,
	ALUMINIUM_WHEELS,
	SILVER_WHEELS,
	GOLD_WHEELS,
	TITANIUM_WHEELS,
	PLATINUM_WHEELS,
	DIAMOND_WHEELS,
	NANOCRYSTAL_WHEELS,
	MYTHRIL_WHEELS,
	STONE_CC,
	LEAD_CC,
	COPPER_CC,
	IRON_CC,
	ALUMINIUM_CC,
	SILVER_CC,
	GOLD_CC,
	TITANIUM_CC,
	PLATINUM_CC,
	DIAMOND_CC,
	NANOCRYSTAL_CC,
	MYTHRIL_CC,
	RED_LASER,
	ORANGE_LASER,
	YELLOW_LASER,
	GREEN_LASER,
	BLUE_LASER,
	PURPLE_LASER,
	UV_LASER,
	XRAY_LASER,
	GAMMARAY_LASER,
	ULTRAGAMMARAY_LASER,
	RED_MINING_LASER,
	ORANGE_MINING_LASER,
	YELLOW_MINING_LASER,
	GREEN_MINING_LASER,
	BLUE_MINING_LASER,
	PURPLE_MINING_LASER,
	UV_MINING_LASER,
	XRAY_MINING_LASER,
	GAMMARAY_MINING_LASER,
	ULTRAGAMMARAY_MINING_LASER,
}

enum Type {
	OVERCLOCK,
	MINING_LIQUID,
	DRILL,
	PORTABLE_WORMHOLE,
	HELIX_CORE,
	ROVER_WEAPON,
	ROVER_MINING,
	ROVER_ARMOR,
	ROVER_CC,
	ROVER_WHEELS,
}

var data:Dictionary = {
	OVERCLOCK1:
		{"item_name":"overclock1", "type":Type.OVERCLOCK, "costs":{"money":2800}, "mult":1.5, "duration":10 * 60}, # "duration" in seconds
	OVERCLOCK2:
		{"item_name":"overclock2", "type":Type.OVERCLOCK, "costs":{"money":17000}, "mult":2, "duration":30 * 60},
	OVERCLOCK3:
		{"item_name":"overclock3", "type":Type.OVERCLOCK, "costs":{"money":90000}, "mult":2.5, "duration":60 * 60},
	OVERCLOCK4:
		{"item_name":"overclock4", "type":Type.OVERCLOCK, "costs":{"money":340000}, "mult":3, "duration":2 * 60 * 60},
	OVERCLOCK5:
		{"item_name":"overclock5", "type":Type.OVERCLOCK, "costs":{"money":2.2e6}, "mult":4, "duration":6 * 60 * 60},
	OVERCLOCK6:
		{"item_name":"overclock6", "type":Type.OVERCLOCK, "costs":{"money":1.8e7}, "mult":5, "duration":24 * 60 * 60},
	MINING_LIQUID:
		{"item_name":"mining_liquid", "type":Type.MINING_LIQUID, "costs":{"coal":200, "glass":20}, "speed_mult":1.5, "durability":400},
	PURPLE_MINING_LIQUID:
		{"item_name":"purple_mining_liquid", "type":Type.MINING_LIQUID, "costs":{"H":4000, "O":2000, "glass":500}, "speed_mult":4.0, "durability":800},
	DRILL1:
		{"item_name":"drill1", "type":Type.DRILL, "costs":{"iron":100, "aluminium":20}, "limit":8}, # "limit": cave floor limit
	DRILL2:
		{"item_name":"drill2", "type":Type.DRILL, "costs":{"aluminium":600, "titanium":150}, "limit":16},
	DRILL3:
		{"item_name":"drill3", "type":Type.DRILL, "costs":{"platinum":4000, "diamond":3000}, "limit":24},
	PORTABLE_WORMHOLE1:
		{"item_name":"portable_wormhole1", "type":Type.PORTABLE_WORMHOLE, "costs":{"glass":80, "aluminium":80}, "limit":8},
	PORTABLE_WORMHOLE2:
		{"item_name":"portable_wormhole2", "type":Type.PORTABLE_WORMHOLE, "costs":{"diamond":20}, "limit":16},
	PORTABLE_WORMHOLE3:
		{"item_name":"portable_wormhole3", "type":Type.PORTABLE_WORMHOLE, "costs":{"platinum":5000, "quillite":1000}, "limit":24},
	HELIX_CORE1:
		{"item_name": "hx_core", "type":Type.HELIX_CORE, "XP": 6},
	HELIX_CORE2:
		{"item_name": "hx_core2", "type":Type.HELIX_CORE, "XP": 400},
	HELIX_CORE3:
		{"item_name": "hx_core3", "type":Type.HELIX_CORE, "XP": 30000},
	HELIX_CORE4:
		{"item_name": "hx_core4", "type":Type.HELIX_CORE, "XP": 2e6},
	STONE_ARMOR:
		{"item_name":"stone_armor", "type":Type.ROVER_ARMOR, "metal":"stone", "HP":2, "defense":1, "costs":{"stone":200.0}},
	LEAD_ARMOR:
		{"item_name":"lead_armor", "type":Type.ROVER_ARMOR, "metal":"lead", "HP":5, "defense":2, "costs":{"lead":40.0}},
	COPPER_ARMOR:
		{"item_name":"copper_armor", "type":Type.ROVER_ARMOR, "metal":"copper", "HP":10, "defense":3, "costs":{"copper":50.0}},
	IRON_ARMOR:
		{"item_name":"iron_armor", "type":Type.ROVER_ARMOR, "metal":"iron", "HP":15, "defense":4, "costs":{"iron":65.0}},
	ALUMINIUM_ARMOR:
		{"item_name":"aluminium_armor", "type":Type.ROVER_ARMOR, "metal":"aluminium", "HP":20, "defense":5, "costs":{"aluminium":90.0}},
	SILVER_ARMOR:
		{"item_name":"silver_armor", "type":Type.ROVER_ARMOR, "metal":"silver", "HP":30, "defense":7, "costs":{"silver":130.0}},
	GOLD_ARMOR:
		{"item_name":"gold_armor", "type":Type.ROVER_ARMOR, "metal":"gold", "HP":50, "defense":10, "costs":{"gold":190.0}},
	TITANIUM_ARMOR:
		{"item_name":"titanium_armor", "type":Type.ROVER_ARMOR, "metal":"titanium", "HP":80, "defense":15, "costs":{"titanium":240.0}},
	PLATINUM_ARMOR:
		{"item_name":"platinum_armor", "type":Type.ROVER_ARMOR, "metal":"platinum", "HP":130, "defense":40, "costs":{"platinum":600.0}},
	DIAMOND_ARMOR:
		{"item_name":"diamond_armor", "type":Type.ROVER_ARMOR, "metal":"diamond", "HP":180, "defense":70, "costs":{"diamond":750.0}},
	NANOCRYSTAL_ARMOR:
		{"item_name":"nanocrystal_armor", "type":Type.ROVER_ARMOR, "metal":"nanocrystal", "HP":240, "defense":110, "costs":{"nanocrystal":1600.0}},
	MYTHRIL_ARMOR:
		{"item_name":"mythril_armor", "type":Type.ROVER_ARMOR, "metal":"mythril", "HP":400, "defense":250, "costs":{"mythril":3800.0}},
	STONE_WHEELS:
		{"item_name":"stone_wheels", "type":Type.ROVER_WHEELS, "speed":1.0, "metal":"stone", "costs":{"stone":100.0}},
	LEAD_WHEELS:
		{"item_name":"lead_wheels", "type":Type.ROVER_WHEELS, "speed":1.05, "metal":"lead", "costs":{"lead":30.0}},
	COPPER_WHEELS:
		{"item_name":"copper_wheels", "type":Type.ROVER_WHEELS, "speed":1.1, "metal":"copper", "costs":{"copper":40.0}},
	IRON_WHEELS:
		{"item_name":"iron_wheels", "type":Type.ROVER_WHEELS, "speed":1.15, "metal":"iron", "costs":{"iron":50.0}},
	ALUMINIUM_WHEELS:
		{"item_name":"aluminium_wheels", "type":Type.ROVER_WHEELS, "speed":1.2, "metal":"aluminium", "costs":{"aluminium":70.0}},
	SILVER_WHEELS:
		{"item_name":"silver_wheels", "type":Type.ROVER_WHEELS, "speed":1.25, "metal":"silver", "costs":{"silver":100.0}},
	GOLD_WHEELS:
		{"item_name":"gold_wheels", "type":Type.ROVER_WHEELS, "speed":1.3, "metal":"gold", "costs":{"gold":150.0}},
	TITANIUM_WHEELS:
		{"item_name":"titanium_wheels", "type":Type.ROVER_WHEELS, "speed":1.6, "metal":"titanium", "costs":{"titanium":200.0}},
	PLATINUM_WHEELS:
		{"item_name":"platinum_wheels", "type":Type.ROVER_WHEELS, "speed":1.75, "metal":"platinum", "costs":{"platinum":500.0}},
	DIAMOND_WHEELS:
		{"item_name":"diamond_wheels", "type":Type.ROVER_WHEELS, "speed":1.95, "metal":"diamond", "costs":{"diamond":650.0}},
	NANOCRYSTAL_WHEELS:
		{"item_name":"nanocrystal_wheels", "type":Type.ROVER_WHEELS, "speed":2.2, "metal":"nanocrystal", "costs":{"nanocrystal":1100.0}},
	MYTHRIL_WHEELS:
		{"item_name":"mythril_wheels", "type":Type.ROVER_WHEELS, "speed":2.5, "metal":"mythril", "costs":{"mythril":1600.0}},
	STONE_CC:
		{"item_name":"stone_CC", "type":Type.ROVER_CC, "capacity":3000.0, "metal":"stone", "costs":{"stone":250.0}},
	LEAD_CC:
		{"item_name":"lead_CC", "type":Type.ROVER_CC, "capacity":5000.0, "metal":"lead", "costs":{"lead":70.0}},
	COPPER_CC:
		{"item_name":"copper_CC", "type":Type.ROVER_CC, "capacity":7000.0, "metal":"copper", "costs":{"copper":90.0}},
	IRON_CC:
		{"item_name":"iron_CC", "type":Type.ROVER_CC, "capacity":10000.0, "metal":"iron", "costs":{"iron":110.0}},
	ALUMINIUM_CC:
		{"item_name":"aluminium_CC", "type":Type.ROVER_CC, "capacity":14000.0, "metal":"aluminium", "costs":{"aluminium":130.0}},
	SILVER_CC:
		{"item_name":"silver_CC", "type":Type.ROVER_CC, "capacity":20000.0, "metal":"silver", "costs":{"silver":150.0}},
	GOLD_CC:
		{"item_name":"gold_CC", "type":Type.ROVER_CC, "capacity":30000.0, "metal":"gold", "costs":{"gold":200.0}},
	TITANIUM_CC:
		{"item_name":"titanium_CC", "type":Type.ROVER_CC, "capacity":62000.0, "metal":"titanium", "costs":{"titanium":250.0}},
	PLATINUM_CC:
		{"item_name":"platinum_CC", "type":Type.ROVER_CC, "capacity":90000.0, "metal":"platinum", "costs":{"platinum":700.0}},
	DIAMOND_CC:
		{"item_name":"diamond_CC", "type":Type.ROVER_CC, "capacity":165000.0, "metal":"diamond", "costs":{"diamond":1200.0}},
	NANOCRYSTAL_CC:
		{"item_name":"nanocrystal_CC", "type":Type.ROVER_CC, "capacity":450000.0, "metal":"nanocrystal", "costs":{"nanocrystal":2200.0}},
	MYTHRIL_CC:
		{"item_name":"mythril_CC", "type":Type.ROVER_CC, "capacity":1250000.0, "metal":"mythril", "costs":{"mythril":5000.0}},
	RED_LASER:
		{"item_name":"red_laser", "type":Type.ROVER_WEAPON, "damage":5, "cooldown":0.2, "costs":{"money":1000, "silicon":10}},
	ORANGE_LASER:
		{"item_name":"orange_laser", "type":Type.ROVER_WEAPON, "damage":8, "cooldown":0.19, "costs":{"money":17000, "silicon":12}},
	YELLOW_LASER:
		{"item_name":"yellow_laser", "type":Type.ROVER_WEAPON, "damage":14, "cooldown":0.18, "costs":{"money":190000, "silicon":15}},
	GREEN_LASER:
		{"item_name":"green_laser", "type":Type.ROVER_WEAPON, "damage":22, "cooldown":0.17, "costs":{"money":950000, "silicon":20}},
	BLUE_LASER:
		{"item_name":"blue_laser", "type":Type.ROVER_WEAPON, "damage":40, "cooldown":0.16, "costs":{"money":5.2e6, "silicon":50, "gold":25}},
	PURPLE_LASER:
		{"item_name":"purple_laser", "type":Type.ROVER_WEAPON, "damage":75, "cooldown":0.15, "costs":{"money":3.7e7, "silicon":100, "platinum":50}},
	UV_LASER:
		{"item_name":"UV_laser", "type":Type.ROVER_WEAPON, "damage":140, "cooldown":0.14, "costs":{"money":3.1e8, "silicon":200, "platinum":100}},
	XRAY_LASER:
		{"item_name":"xray_laser", "type":Type.ROVER_WEAPON, "damage":270, "cooldown":0.13, "costs":{"money":9.8e9, "silicon":500, "platinum":200}},
	GAMMARAY_LASER:
		{"item_name":"gammaray_laser", "type":Type.ROVER_WEAPON, "damage":525, "cooldown":0.12, "costs":{"money":2.5e11, "silicon":1000, "platinum":500}},
	ULTRAGAMMARAY_LASER:
		{"item_name":"ultragammaray_laser", "type":Type.ROVER_WEAPON, "damage":900, "cooldown":0.1, "costs":{"money":1.5e13, "silicon":2500, "platinum":1000}},
	RED_MINING_LASER:
		{"item_name":"red_mining_laser", "type":Type.ROVER_MINING, "speed":1, "range":250, "costs":{"money":1000, "silicon":10}},
	ORANGE_MINING_LASER:
		{"item_name":"orange_mining_laser", "type":Type.ROVER_MINING, "speed":1.4, "range":260, "costs":{"money":17000, "silicon":12}},
	YELLOW_MINING_LASER:
		{"item_name":"yellow_mining_laser", "type":Type.ROVER_MINING, "speed":1.9, "range":270, "costs":{"money":190000, "silicon":15}},
	GREEN_MINING_LASER:
		{"item_name":"green_mining_laser", "type":Type.ROVER_MINING, "speed":2.5, "range":285, "costs":{"money":950000, "silicon":20}},
	BLUE_MINING_LASER:
		{"item_name":"blue_mining_laser", "type":Type.ROVER_MINING, "speed":3.3, "range":300, "costs":{"money":5.2e6, "silicon":50, "gold":25}},
	PURPLE_MINING_LASER:
		{"item_name":"purple_mining_laser", "type":Type.ROVER_MINING, "speed":4.3, "range":315, "costs":{"money":3.7e7, "silicon":100, "platinum":50}},
	UV_MINING_LASER:
		{"item_name":"UV_mining_laser", "type":Type.ROVER_MINING, "speed":6, "range":330, "costs":{"money":3.1e8, "silicon":200, "platinum":100}},
	XRAY_MINING_LASER:
		{"item_name":"xray_mining_laser", "type":Type.ROVER_MINING, "speed":9.1, "range":350, "costs":{"money":4.0e9, "silicon":500, "platinum":200}},
	GAMMARAY_MINING_LASER:
		{"item_name":"gammaray_mining_laser", "type":Type.ROVER_MINING, "speed":12, "range":380, "costs":{"money":9.4e10, "silicon":1000, "platinum":500}},
	ULTRAGAMMARAY_MINING_LASER:
		{"item_name":"ultragammaray_mining_laser", "type":Type.ROVER_MINING, "speed":16, "range":500, "costs":{"money":1.0e12, "silicon":2500, "platinum":1000}},
}

func icon_directory(type:int):
	if type == Type.OVERCLOCK:
		return "Overclocks"
	elif type == Type.MINING_LIQUID:
		return "Mining liquids"
	elif type == Type.HELIX_CORE:
		return "Helix cores"
	elif type == Type.DRILL:
		return "Drills"
	elif type == Type.PORTABLE_WORMHOLE:
		return "Portable wormholes"

func name(item_id:int):
	if item_id == OVERCLOCK1:
		return tr("OVERCLOCK")
	elif item_id == OVERCLOCK2:
		return tr("OVERCLOCK") + " II"
	elif item_id == OVERCLOCK3:
		return tr("OVERCLOCK") + " III"
	elif item_id == OVERCLOCK4:
		return tr("OVERCLOCK") + " IV"
	elif item_id == OVERCLOCK5:
		return tr("OVERCLOCK") + " V"
	elif item_id == OVERCLOCK6:
		return tr("OVERCLOCK") + " VI"
	elif item_id == MINING_LIQUID:
		return tr("MINING_LIQUID")
	elif item_id == PURPLE_MINING_LIQUID:
		return tr("PURPLE_MINING_LIQUID")
	elif item_id == DRILL1:
		return tr("DRILL")
	elif item_id == DRILL2:
		return tr("DRILL") + " II"
	elif item_id == DRILL3:
		return tr("DRILL") + " III"
	elif item_id == PORTABLE_WORMHOLE1:
		return tr("PORTABLE_WORMHOLE")
	elif item_id == PORTABLE_WORMHOLE2:
		return tr("PORTABLE_WORMHOLE") + " II"
	elif item_id == PORTABLE_WORMHOLE3:
		return tr("PORTABLE_WORMHOLE") + " III"
	elif item_id == HELIX_CORE1:
		return tr("HX_CORE")
	elif item_id == HELIX_CORE2:
		return tr("HX_CORE") + " II"
	elif item_id == HELIX_CORE3:
		return tr("HX_CORE") + " III"
	elif item_id == HELIX_CORE4:
		return tr("HX_CORE") + " IV"
	elif item_id == RED_LASER:
		return tr("RED_LASER")
	elif item_id == ORANGE_LASER:
		return tr("ORANGE_LASER")
	elif item_id == YELLOW_LASER:
		return tr("YELLOW_LASER")
	elif item_id == GREEN_LASER:
		return tr("GREEN_LASER")
	elif item_id == BLUE_LASER:
		return tr("BLUE_LASER")
	elif item_id == PURPLE_LASER:
		return tr("PURPLE_LASER")
	elif item_id == UV_LASER:
		return tr("UV_LASER")
	elif item_id == XRAY_LASER:
		return tr("XRAY_LASER")
	elif item_id == GAMMARAY_LASER:
		return tr("GAMMARAY_LASER")
	elif item_id == ULTRAGAMMARAY_LASER:
		return tr("ULTRAGAMMARAY_LASER")
	elif item_id == RED_MINING_LASER:
		return tr("RED_MINING_LASER")
	elif item_id == ORANGE_MINING_LASER:
		return tr("ORANGE_MINING_LASER")
	elif item_id == YELLOW_MINING_LASER:
		return tr("YELLOW_MINING_LASER")
	elif item_id == GREEN_MINING_LASER:
		return tr("GREEN_MINING_LASER")
	elif item_id == BLUE_MINING_LASER:
		return tr("BLUE_MINING_LASER")
	elif item_id == PURPLE_MINING_LASER:
		return tr("PURPLE_MINING_LASER")
	elif item_id == UV_MINING_LASER:
		return tr("UV_MINING_LASER")
	elif item_id == XRAY_MINING_LASER:
		return tr("XRAY_MINING_LASER")
	elif item_id == GAMMARAY_MINING_LASER:
		return tr("GAMMARAY_MINING_LASER")
	elif item_id == ULTRAGAMMARAY_MINING_LASER:
		return tr("ULTRAGAMMARAY_MINING_LASER")

func description(item_id:int):
	if data[item_id].type == Type.OVERCLOCK:
		return tr("OVERCLOCKS_DESC2") % [data[item_id].mult, Helper.time_to_str(data[item_id].duration / game.u_i.get("time_speed", 1.0))]
	elif data[item_id].type == Type.HELIX_CORE:
		return tr("HX_CORE_DESC") % Helper.format_num(data[item_id].XP)
	elif data[item_id].type == Type.MINING_LIQUID:
		return "%s: %s\n%s: %s" % [tr("SPEED_MULTIPLIER"), data[item_id].speed_mult, tr("DURABILITY"), data[item_id].durability]
	elif data[item_id].type == Type.DRILL:
		return tr("DRILL_DESC") % data[item_id].limit
	elif data[item_id].type == Type.PORTABLE_WORMHOLE:
		return tr("PORTABLE_WORMHOLE_DESC") % data[item_id].limit
