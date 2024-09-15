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
}

enum Type {
	DRILL,
	HELIX_CORE,
	MINING_LIQUID,
	OVERCLOCK,
	PORTABLE_WORMHOLE,
}

var data:Dictionary = {
	OVERCLOCK1:
		{"icon_name":"overclock1", "type":Type.OVERCLOCK, "costs":{"money":2800}, "mult":1.5, "duration":10 * 60}, # "duration" in seconds
	OVERCLOCK2:
		{"icon_name":"overclock2", "type":Type.OVERCLOCK, "costs":{"money":17000}, "mult":2, "duration":30 * 60},
	OVERCLOCK3:
		{"icon_name":"overclock3", "type":Type.OVERCLOCK, "costs":{"money":90000}, "mult":2.5, "duration":60 * 60},
	OVERCLOCK4:
		{"icon_name":"overclock4", "type":Type.OVERCLOCK, "costs":{"money":340000}, "mult":3, "duration":2 * 60 * 60},
	OVERCLOCK5:
		{"icon_name":"overclock5", "type":Type.OVERCLOCK, "costs":{"money":2.2e6}, "mult":4, "duration":6 * 60 * 60},
	OVERCLOCK6:
		{"icon_name":"overclock6", "type":Type.OVERCLOCK, "costs":{"money":1.8e7}, "mult":5, "duration":24 * 60 * 60},
	MINING_LIQUID:
		{"icon_name":"mining_liquid", "type":Type.MINING_LIQUID, "costs":{"coal":200, "glass":20}, "speed_mult":1.5, "durability":400},
	PURPLE_MINING_LIQUID:
		{"icon_name":"purple_mining_liquid", "type":Type.MINING_LIQUID, "costs":{"H":4000, "O":2000, "glass":500}, "speed_mult":4.0, "durability":800},
	DRILL1:
		{"icon_name":"drill1", "type":Type.DRILL, "costs":{"iron":100, "aluminium":20}, "limit":8}, # "limit": cave floor limit
	DRILL2:
		{"icon_name":"drill2", "type":Type.DRILL, "costs":{"aluminium":600, "titanium":150}, "limit":16},
	DRILL3:
		{"icon_name":"drill3", "type":Type.DRILL, "costs":{"platinum":4000, "diamond":3000}, "limit":24},
	PORTABLE_WORMHOLE1:
		{"icon_name":"portable_wormhole1", "type":Type.PORTABLE_WORMHOLE, "costs":{"glass":80, "aluminium":80}, "limit":8},
	PORTABLE_WORMHOLE2:
		{"icon_name":"portable_wormhole2", "type":Type.PORTABLE_WORMHOLE, "costs":{"quartz":300, "diamond":20}, "limit":16},
	PORTABLE_WORMHOLE3:
		{"icon_name":"portable_wormhole3", "type":Type.PORTABLE_WORMHOLE, "costs":{"platinum":5000, "quillite":1000}, "limit":24},
	HELIX_CORE1:
		{"icon_name": "hx_core", "type":Type.HELIX_CORE, "XP": 6},
	HELIX_CORE2:
		{"icon_name": "hx_core2", "type":Type.HELIX_CORE, "XP": 800},
	HELIX_CORE3:
		{"icon_name": "hx_core3", "type":Type.HELIX_CORE, "XP": 120000},
	HELIX_CORE4:
		{"icon_name": "hx_core4", "type":Type.HELIX_CORE, "XP": 1.6e7},
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
