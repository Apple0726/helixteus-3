extends Node

var path_1 = {	"ME":{"value":0.36, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"PP":{"value":0.6, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"RL":{"value":0.06, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150, "silver":150, "gold":150}},
				"MS":{"value":50, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				"RCC":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000}},
				"SC":{"value":50.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":1, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":20.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"MM":{"value":0.01, "pw":1.08, "is_value_integer":false, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.5, "pw":1.02, "is_value_integer":false, "metal_costs":{"lead":500, "copper":500, "iron":600, "aluminium":600, "silver":700, "gold":700}},
				"SP":{"value":1.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":0.2, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"AMN":{"value":1.0, "pw":1.13, "is_value_integer":false, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.13, "is_value_integer":false, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
}
var path_2 = {	"ME":{"value":30, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"PP":{"value":140, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"SC":{"value":4000, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":600, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":50, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"MM":{"value":4, "pw":1.08, "is_value_integer":true, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.1, "pw":1.16, "is_value_integer":false, "metal_costs":{"lead":1000, "copper":1000, "iron":1200, "aluminium":1200, "silver":1400, "gold":1400}},
				"SP":{"value":2100, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":60, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
}
var path_3 = {	"SC":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":600, "copper":600, "iron":600, "aluminium":600, "silver":600, "gold":600}},
				"GF":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":700, "copper":1000, "iron":1400, "aluminium":2000, "silver":2500, "gold":3500}},
				"SE":{"value":1.0, "pw":1.025, "is_value_integer":false, "metal_costs":{"lead":700, "copper":1400, "iron":2800, "aluminium":5600, "silver":11200, "gold":22400}},
}

var costs = {	"ME":{"money":100, "energy":40, "time":6.0},
				"PP":{"money":80, "time":3.0},
				"RL":{"money":2000, "energy":600, "time":125.0},
				"MS":{"money":500, "energy":80, "time":20.0},
				"RCC":{"money":5000, "energy":400, "time":80.0},
				"SC":{"money":2200, "energy":800, "time":150.0},
				"GF":{"money":1500, "energy":1000, "time":120.0},
				"SE":{"money":1500, "energy":500, "time":120.0},
				"MM":{"money":13000, "energy":7000, "time":400.0},
				"rover":{"money":2000, "energy":300, "time":50.0},
				"GH":{"money":10000, "energy":1500, "glass":500, "time":75.0},
				"SP":{"money":4000, "time":90.0},
				"AE":{"money":41500, "energy":15000, "time":180.0},
				"AMN":{"money":580000, "energy":8200, "time":490.0},
				"SPR":{"money":6500000, "energy":61300, "time":1400.0},
}

var MS_costs = {	"M_DS_0":{"money":13000000000, "stone":800000000, "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"M_SE_0":{"money":700000, "stone":50000, "energy":20000, "copper":800, "iron":1000, "aluminium":300, "time":2*3600},#2*3600
					"M_SE_1":{"money":3200000, "stone":200000, "energy":40000, "copper":1000, "iron":1400, "aluminium":400, "time":8*3600},#8, 8, 12
					"M_SE_2":{"money":6800000, "stone":350000, "energy":60000, "copper":2000, "iron":2800, "aluminium":800, "time":8*3600},
					"M_SE_3":{"money":10000000, "stone":500000, "energy":80000, "copper":8000, "iron":10000, "aluminium":3000, "time":12*3600},
					"M_MME_0":{"money":50000000, "stone":4000000, "copper":1000, "iron":800, "aluminium":3000, "titanium":300, "time":8 * 3600},#* 3600
					"M_MME_1":{"money":4500000000, "stone":320000000, "copper":90000, "iron":75000, "aluminium":300000, "titanium":30000, "time":32},
}

var MS_output = {	"M_DS_0":450000000,
					"M_MME_0":6000,
					"M_MME_1":475000,
}

var MUs = {	"MV":{"base_cost":100, "pw":2.3},
			"MSMB":{"base_cost":100, "pw":1.6},
			"IS":{"base_cost":500, "pw":2.1},
			"AIE":{"base_cost":1000, "pw":1.9},
			"STMB":{"base_cost":600, "pw":1.7},
			"SHSR":{"base_cost":2000, "pw":1.8},
}
var minerals_icon = load("res://Graphics/Icons/minerals.png")
var energy_icon = load("res://Graphics/Icons/energy.png")
var time_icon = load("res://Graphics/Icons/Time.png")
var stone_icon = load("res://Graphics/Icons/stone.png")
var SP_icon = load("res://Graphics/Icons/SP.png")
var glass_icon = load("res://Graphics/Materials/glass.png")
var sand_icon = load("res://Graphics/Materials/sand.png")
var coal_icon = load("res://Graphics/Materials/coal.png")
var MM_icon = load("res://Graphics/Icons/MM.png")
var atom_icon = load("res://Graphics/Science/ATM.png")
var particle_icon = load("res://Graphics/Science/SAP.png")

var desc_icons = {	"ME":[minerals_icon, minerals_icon],
					"PP":[energy_icon, energy_icon],
					"RL":[SP_icon],
					"MS":[minerals_icon],
					"SC":[stone_icon, stone_icon, null],
					"GF":[glass_icon, sand_icon, null],
					"SE":[energy_icon, coal_icon, null],
					"SP":[energy_icon, energy_icon],
}

var rsrc_icons = {	"ME":minerals_icon,
					"PP":energy_icon,
					"RL":SP_icon,
					"SC":stone_icon,
					"GF":glass_icon,
					"SE":energy_icon,
					"MM":MM_icon,
					"SP":energy_icon,
					"AE":atom_icon,
					"AMN":atom_icon,
					"SPR":particle_icon,
}

func reload():
	path_1.ME.desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.AE.desc = tr("EXTRACTS_X") % ["%s mol/" + tr("S_SECOND")]
	path_1.PP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RL.desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RCC.desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_1.SC.desc = tr("CRUSHES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1.GF.desc = tr("PRODUCES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1.SE.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.MM.desc = tr("X_M_PER_SECOND") % ["%s", tr("S_SECOND")]
	path_1.GH.desc = tr("X_PLANT_GROWTH")
	path_1.SP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.AMN.desc = "%s: %%s" % [tr("BASE_SPEED")]
	path_1.SPR.desc = "%s: %%s" % [tr("BASE_SPEED")]
	path_2.ME.desc = tr("STORES_X") % [" @i %s"]
	path_2.AE.desc = tr("STORES_X") % ["%s mol"]
	path_2.PP.desc = tr("STORES_X") % [" @i %s"]
	path_2.SC.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.GF.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.SE.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.MM.desc = tr("X_M_AT_ONCE")
	path_2.GH.desc = tr("X_PLANT_PRODUCE")
	path_2.SP.desc = tr("STORES_X") % [" @i %s"]
	path_3.SC.desc = tr("OUTPUT_MULTIPLIER")
	path_3.GF.desc = tr("OUTPUT_MULTIPLIER")
	path_3.SE.desc = tr("OUTPUT_MULTIPLIER")

var lakes = {	"water":{"color":Color(0.38, 0.81, 1.0, 1.0)}}

#Science for unlocking game features
var science_unlocks = {	
						#Agriculture sciences
						"SA":{"cost":100, "parents":[]},
						"EGH":{"cost":3500, "parents":["SA"]},
						
						#Auto mining
						"AM":{"cost":10000, "parents":[]},
						
						#Atom manipulation
						"ATM":{"cost":200000, "parents":[]},
						"SAP":{"cost":12500000, "parents":["ATM"]},
						
						#Rover sciences
						"RC":{"cost":10, "parents":[]},
						"OL":{"cost":1000, "parents":["RC"]},
						"YL":{"cost":12000, "parents":["OL"]},
						"GL":{"cost":70000, "parents":["YL"]},
						"BL":{"cost":350000, "parents":["GL"]},
						"PL":{"cost":2400000, "parents":["BL"]},
						"UVL":{"cost":28000000, "parents":["PL"]},
						"XRL":{"cost":405000000, "parents":["UVL"]},
						"GRL":{"cost":6500000000, "parents":["XRL"]},
						"UGRL":{"cost":100000000000, "parents":["GRL"]},
						
						#Ship sciences
						"SCT":{"cost":1500, "parents":["RC"]},
						"CD":{"cost":24000, "parents":["SCT"]},
						"FTL":{"cost":128000, "parents":["SCT"]},
						"ID":{"cost":450000, "parents":["CD", "ATM"]},
						"FD":{"cost":15000000, "parents":["ID"]},
						"PD":{"cost":120000000, "parents":["FD"]},
						
						#Megastructure sciences
						"MAE":{"cost":100000, "parents":[]},
						#Dyson sphere
						"DS1":{"cost":1200000000, "parents":["MAE"]},
						"DS2":{"cost":2500000000, "parents":["DS1"]},
						"DS3":{"cost":5000000000, "parents":["DS2"]},
						"DS4":{"cost":7500000000, "parents":["DS3"]},
						#Space elevator
						"SE1":{"cost":150000, "parents":["MAE"]},
						"SE2":{"cost":300000, "parents":["SE1"]},
						"SE3":{"cost":500000, "parents":["SE2"]},
						
						#Mega mineral extractor
						"MME1":{"cost":170000000, "parents":["MAE"]},
						"MME2":{"cost":400000000, "parents":["MME1"]},
						"MME3":{"cost":720000000, "parents":["MME2"]},
						
}
var infinite_research_sciences = {	"MEE":{"cost":50, "pw":6.2, "value":1.2},
									"EPE":{"cost":80, "pw":6.2, "value":1.2},
									"RLE":{"cost":250, "pw":6.8, "value":1.2},
									"MSE":{"cost":70, "pw":6.2, "value":1.2},
									"MMS":{"cost":30, "pw":6.0, "value":1.2},
}

var rover_armor = {	"lead_armor":{"HP":5, "defense":3, "costs":{"lead":40}},
					"copper_armor":{"HP":10, "defense":5, "costs":{"copper":50}},
					"iron_armor":{"HP":15, "defense":7, "costs":{"iron":65}},
					"aluminium_armor":{"HP":20, "defense":9, "costs":{"aluminium":90}},
					"silver_armor":{"HP":25, "defense":11, "costs":{"silver":130}},
					"gold_armor":{"HP":35, "defense":14, "costs":{"gold":190}},
					"gemstone_armor":{"HP":50, "defense":18, "costs":{"amethyst":170, "quartz":170, "topaz":170, "sapphire":170, "emerald":170, "ruby":170}},
					"platinum_armor":{"HP":65, "defense":23, "costs":{"platinum":400}},
					"titanium_armor":{"HP":80, "defense":29, "costs":{"titanium":600}},
					"diamond_armor":{"HP":95, "defense":35, "costs":{"diamond":750}},
}
var rover_wheels = {	"lead_wheels":{"speed":1.0, "costs":{"lead":30}},
						"copper_wheels":{"speed":1.05, "costs":{"copper":40}},
						"iron_wheels":{"speed":1.1, "costs":{"iron":50}},
						"aluminium_wheels":{"speed":1.15, "costs":{"aluminium":70}},
						"silver_wheels":{"speed":1.2, "costs":{"silver":100}},
						"gold_wheels":{"speed":1.3, "costs":{"gold":150}},
						"gemstone_wheels":{"speed":1.4, "costs":{"amethyst":125, "quartz":125, "topaz":125, "sapphire":125, "emerald":125, "ruby":125}},
						"platinum_wheels":{"speed":1.5, "costs":{"platinum":350}},
						"titanium_wheels":{"speed":1.6, "costs":{"titanium":500}},
						"diamond_wheels":{"speed":1.75, "costs":{"diamond":650}},
}
var rover_CC = {	"lead_CC":{"capacity":2500, "costs":{"lead":70}},
					"copper_CC":{"capacity":3500, "costs":{"copper":90}},
					"iron_CC":{"capacity":5000, "costs":{"iron":110}},
					"aluminium_CC":{"capacity":7000, "costs":{"aluminium":130}},
					"silver_CC":{"capacity":10000, "costs":{"silver":150}},
					"gold_CC":{"capacity":15000, "costs":{"gold":200}},
					"gemstone_CC":{"capacity":22000, "costs":{"amethyst":180, "quartz":180, "topaz":180, "sapphire":180, "emerald":180, "ruby":180}},
					"platinum_CC":{"capacity":31000, "costs":{"platinum":500}},
					"titanium_CC":{"capacity":42000, "costs":{"titanium":700}},
					"diamond_CC":{"capacity":59000, "costs":{"diamond":1000}},
}
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":3400, "silicon":5, "time":10}},
						"orange_laser":{"damage":12, "cooldown":0.195, "costs":{"money":17000, "silicon":10, "time":60}},
						"yellow_laser":{"damage":29, "cooldown":0.19, "costs":{"money":140000, "silicon":15, "time":360}},
						"green_laser":{"damage":68, "cooldown":0.185, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_laser":{"damage":150, "cooldown":0.18, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_laser":{"damage":285, "cooldown":0.175, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"UV_laser":{"damage":550, "cooldown":0.17, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_laser":{"damage":1400, "cooldown":0.165, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gammaray_laser":{"damage":3250, "cooldown":0.16, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_laser":{"damage":30000, "cooldown":1, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":3000, "silicon":5, "time":10}},
						"orange_mining_laser":{"speed":1.4, "rnge":260, "costs":{"money":19000, "silicon":10, "time":60}},
						"yellow_mining_laser":{"speed":1.9, "rnge":270, "costs":{"money":120000, "silicon":15, "time":360}},
						"green_mining_laser":{"speed":2.5, "rnge":285, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_mining_laser":{"speed":3.3, "rnge":300, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_mining_laser":{"speed":4.3, "rnge":315, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"UV_mining_laser":{"speed":6, "rnge":330, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_mining_laser":{"speed":9.1, "rnge":350, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gammaray_mining_laser":{"speed":12, "rnge":380, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_mining_laser":{"speed":20, "rnge":230, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}
var bullet_data = [{"damage":7, "accuracy":1.0}, {"damage":10, "accuracy":1.05}, {"damage":18, "accuracy":1.1}]
var laser_data = [{"damage":5, "accuracy":1.8}, {"damage":7, "accuracy":2.2}, {"damage":13, "accuracy":2.7}]
var bomb_data = [{"damage":12, "accuracy":0.7}, {"damage":16, "accuracy":0.72}, {"damage":29, "accuracy":0.75}]
var light_data = [{"damage":3, "accuracy":1.3}, {"damage":5, "accuracy":1.35}, {"damage":9, "accuracy":1.45}]

#the numbers are the elements' abundance relative to hydrogen
var elements = {"NH3":0.05, "CO2":0.01, "H":1.0, "He":0.325, "CH4":0.2, "O":0.014, "H2O":0.15, "Ne":0.001813, "Xe":0.0000022}
