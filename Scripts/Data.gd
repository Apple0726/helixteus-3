extends Node

var path_1 = {	"ME":{"value":0.12, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"PP":{"value":0.3, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"RL":{"value":0.03, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":100, "copper":150, "iron":150}},
				"MS":{"value":25, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35}},
				"RCC":{"value":1.0, "pw":1.1, "is_value_integer":false, "metal_costs":{"lead":50, "copper":50, "iron":50}},
				"SC":{"value":100.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":40, "copper":40, "iron":40}},
}
var path_2 = {	"ME":{"value":15, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"PP":{"value":70, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"SC":{"value":4000, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60}},
}

var costs = {	"ME":{"money":100, "energy":40, "time":12.0},
				"PP":{"money":80, "time":18.0},
				"RL":{"money":2000, "energy":600, "time":150.0},
				"MS":{"money":500, "energy":80, "time":40.0},
				"RCC":{"money":20000, "energy":4000, "time":280.0},
				"SC":{"money":1200, "energy":800, "time":90.0},
				"rover":{"money":5000, "energy":300, "time":80.0},
}

var MUs = {	"MV":{"base_cost":100, "pw":2.3},
			"MSMB":{"base_cost":100, "pw":1.6},
}

var icons = {	"ME":load("res://Graphics/Icons/minerals.png"),
				"PP":load("res://Graphics/Icons/Energy.png"),
				"RL":load("res://Graphics/Icons/SP.png"),
				"MS":load("res://Graphics/Icons/minerals.png"),
				"SC":load("res://Graphics/Icons/stone.png"),
}

func reload():
	path_1.ME.desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.PP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RL.desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RCC.desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_1.SC.desc = tr("CRUSHES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_2.ME.desc = tr("STORES_X") % [" @i %s"]
	path_2.PP.desc = tr("STORES_X") % [" @i %s"]
	path_2.SC.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]

var lakes = {	"water":{"color":Color(0.38, 0.81, 1.0, 1.0)}}

#Science for unlocking game features
var science_unlocks = {	"SA":{"cost":100},
						"RC":{"cost":250},
}

var rover_armor = {	"lead_armor":{"HP":5, "defense":3, "costs":{"lead":40}},
					"copper_armor":{"HP":10, "defense":5, "costs":{"copper":40}},
					"iron_armor":{"HP":15, "defense":7, "costs":{"iron":40}},
}
var rover_wheels = {	"lead_wheels":{"speed":1.0, "costs":{"lead":30}},
						"copper_wheels":{"speed":1.05, "costs":{"copper":30}},
						"iron_wheels":{"speed":1.1, "costs":{"iron":30}},
}
var rover_CC = {	"lead_CC":{"capacity":3000, "costs":{"lead":70}},
					"copper_CC":{"capacity":3500, "costs":{"copper":70}},
					"iron_CC":{"capacity":4000, "costs":{"iron":70}},
}
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":5000, "silicon":5, "time":10}},
						"orange_laser":{"damage":8, "cooldown":0.195, "costs":{"money":35000, "silicon":20, "time":20}},
						"yellow_laser":{"damage":13, "cooldown":0.19, "costs":{"money":400000, "silicon":120, "time":30}},
						"green_laser":{"damage":22, "cooldown":0.185, "costs":{"money":9000000, "silicon":1000, "time":50}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":5000, "silicon":5, "time":10}},
						"orange_mining_laser":{"speed":1.3, "rnge":260, "costs":{"money":25000, "silicon":15, "time":20}},
						"yellow_mining_laser":{"speed":1.6, "rnge":270, "costs":{"money":180000, "silicon":60, "time":30}},
						"green_mining_laser":{"speed":2.0, "rnge":285, "costs":{"money":3600000, "silicon":400, "time":50}},
}
