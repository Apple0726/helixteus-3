extends Node

var path_1 = {	"ME":{"value":0.12, "is_value_integer":false, "desc":"@i %s/" + tr("SECOND"), "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"PP":{"value":0.3, "is_value_integer":false, "desc":"@i %s/" + tr("SECOND"), "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"RL":{"value":0.02, "is_value_integer":false, "desc":"@i %s/" + tr("SECOND"), "metal_costs":{"lead":100, "copper":150, "iron":150}},
				"MS":{"value":25, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":35, "copper":25, "iron":35}},
}
var path_2 = {	"ME":{"value":15, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60}},
				"PP":{"value":70, "is_value_integer":true, "desc":tr("STORES_X") % [" @i %s"], "metal_costs":{"lead":50, "copper":50, "iron":60}},
	
}

var costs = {	"ME":{"money":100, "energy":40, "time":8.0},
				"PP":{"money":80, "time":14.0},
				"RL":{"money":2000, "energy":650, "time":150.0},
				"MS":{"money":500, "energy":250, "time":40.0},
}

var icons = {	"ME":load("res://Graphics/Icons/Minerals.png"),
				"PP":load("res://Graphics/Icons/Energy.png"),
				"RL":load("res://Graphics/Icons/SP.png"),
				"MS":load("res://Graphics/Icons/Minerals.png"),
}

func reload():
	path_1.ME.desc = "@i %s/" + tr("SECOND")
	path_1.PP.desc = "@i %s/" + tr("SECOND")
	path_1.RL.desc = "@i %s/" + tr("SECOND")
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_2.ME.desc = tr("STORES_X") % [" @i %s"]
	path_2.PP.desc = tr("STORES_X") % [" @i %s"]

var lakes = {	"water":{"color":Color(0.38, 0.81, 1.0, 1.0)}}

#Science for unlocking game features
var science_unlocks = {"SA":{"cost":100}}
