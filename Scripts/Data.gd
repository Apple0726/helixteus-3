extends Node

var path_1 = {	"ME":{"value":0.12, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":40, "copper":50, "iron":60, "aluminium":60}},
				"PP":{"value":0.3, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":40, "copper":50, "iron":60, "aluminium":60}},
				"RL":{"value":0.03, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150}},
				"MS":{"value":25, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":150}},
				"RCC":{"value":1.0, "pw":1.09, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":2000, "iron":1800, "aluminium":1800}},
				"SC":{"value":50.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300}},
				"GF":{"value":0.1, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350}},
}
var path_2 = {	"ME":{"value":15, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60, "aluminium":60}},
				"PP":{"value":70, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60, "aluminium":600}},
				"SC":{"value":4000, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300}},
				"GF":{"value":10, "pw":1.17, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350}},
}

var costs = {	"ME":{"money":100, "energy":40, "time":12.0},
				"PP":{"money":80, "time":18.0},
				"RL":{"money":2000, "energy":600, "time":150.0},
				"MS":{"money":500, "energy":80, "time":40.0},
				"RCC":{"money":20000, "energy":4000, "time":280.0},
				"SC":{"money":1200, "energy":800, "time":90.0},
				"GF":{"money":3000, "energy":2000, "time":120.0},
				"rover":{"money":5000, "energy":300, "time":80.0},
}

var MUs = {	"MV":{"base_cost":100, "pw":2.3},
			"MSMB":{"base_cost":100, "pw":1.6},
			"IS":{"base_cost":500, "pw":2.1},
			"AIE":{"base_cost":1000, "pw":1.9},
}

var icons = {	"ME":load("res://Graphics/Icons/minerals.png"),
				"PP":load("res://Graphics/Icons/Energy.png"),
				"RL":load("res://Graphics/Icons/SP.png"),
				"MS":load("res://Graphics/Icons/minerals.png"),
				"SC":load("res://Graphics/Icons/stone.png"),
				"GF":load("res://Graphics/Materials/glass.png"),
}

func reload():
	path_1.ME.desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.PP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RL.desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RCC.desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_1.SC.desc = tr("CRUSHES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1.GF.desc = tr("PRODUCES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_2.ME.desc = tr("STORES_X") % [" @i %s"]
	path_2.PP.desc = tr("STORES_X") % [" @i %s"]
	path_2.SC.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.GF.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]

var lakes = {	"water":{"color":Color(0.38, 0.81, 1.0, 1.0)}}

#Science for unlocking game features
var science_unlocks = {	"SA":{"cost":100, "parent":""},
						"RC":{"cost":250, "parent":""},
						"SCT":{"cost":3000, "parent":"RC"},
						"OL":{"cost":1500, "parent":"RC"},
						"YL":{"cost":8000, "parent":"OL"},
						"GL":{"cost":40000, "parent":"YL"},
						"BL":{"cost":200000, "parent":"GL"},
						"PL":{"cost":800000, "parent":"BL"},
						"UVL":{"cost":2000000, "parent":"PL"},
						"XRL":{"cost":10000000, "parent":"UVL"},
						"GRL":{"cost":30000000, "parent":"XRL"},
						"UGRL":{"cost":200000000, "parent":"GRL"},
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
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":3000, "silicon":5, "time":10}},
						"orange_laser":{"damage":10, "cooldown":0.195, "costs":{"money":20000, "silicon":10, "time":60}},
						"yellow_laser":{"damage":22, "cooldown":0.19, "costs":{"money":150000, "silicon":15, "time":360}},
						"green_laser":{"damage":48, "cooldown":0.185, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_laser":{"damage":100, "cooldown":0.18, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_laser":{"damage":185, "cooldown":0.175, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"ultra_violet_laser":{"damage":250, "cooldown":0.17, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_laser":{"damage":600, "cooldown":0.165, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gamma_ray_laser":{"damage":1250, "cooldown":0.16, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragamma_ray_laser":{"damage":10000, "cooldown":1, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":3000, "silicon":5, "time":10}},
						"orange_mining_laser":{"speed":1.4, "rnge":260, "costs":{"money":20000, "silicon":10, "time":60}},
						"yellow_mining_laser":{"speed":1.9, "rnge":270, "costs":{"money":150000, "silicon":15, "time":360}},
						"green_mining_laser":{"speed":2.5, "rnge":285, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_mining_laser":{"speed":3, "rnge":300, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_mining_laser":{"speed":3.6, "rnge":315, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"ultra_violet_mining_laser":{"speed":4.3, "rnge":330, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_mining_laser":{"speed":5.1, "rnge":350, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gamma_ray_mining_laser":{"speed":6, "rnge":380, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragamma_ray_mining_laser":{"speed":10, "rnge":230, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}
var bullet_data = [{"damage":7, "accuracy":1.0}, {"damage":10, "accuracy":1.05}]
var laser_data = [{"damage":4, "accuracy":1.5}, {"damage":6, "accuracy":1.6}]
var bomb_data = [{"damage":12, "accuracy":0.7}, {"damage":16, "accuracy":0.72}]
var light_data = [{"damage":3, "accuracy":1.2}, {"damage":5, "accuracy":1.25}]
