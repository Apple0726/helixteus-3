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
