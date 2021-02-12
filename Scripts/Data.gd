extends Node

var path_1 = {	"ME":{"value":0.12, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"PP":{"value":0.3, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"RL":{"value":0.03, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150, "silver":150, "gold":150}},
				"MS":{"value":25, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				"RCC":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":2000, "iron":1800, "aluminium":1800, "silver":1800, "gold":1800}},
				"SC":{"value":50.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":1, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":20.0, "pw":1.15, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"MM":{"value":0.01, "pw":1.08, "is_value_integer":false, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":2.0, "pw":1.02, "is_value_integer":false, "metal_costs":{"lead":500, "copper":500, "iron":600, "aluminium":600, "silver":700, "gold":700}},
				"SP":{"value":1.0, "pw":1.12, "is_value_integer":false, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":0.2, "pw":1.12, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"AMN":{"value":1.0, "pw":1.12, "is_value_integer":false, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.11, "is_value_integer":false, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
}
var path_2 = {	"ME":{"value":15, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"PP":{"value":70, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"SC":{"value":4000, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":600, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":50, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"MM":{"value":4, "pw":1.08, "is_value_integer":true, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.1, "pw":1.01, "is_value_integer":false, "metal_costs":{"lead":1000, "copper":1000, "iron":1200, "aluminium":1200, "silver":1400, "gold":1400}},
				"SP":{"value":300, "pw":1.12, "is_value_integer":true, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":60, "pw":1.12, "is_value_integer":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
}
var path_3 = {	"SC":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":600, "copper":600, "iron":600, "aluminium":600, "silver":600, "gold":600}},
				"GF":{"value":1.0, "pw":1.03, "is_value_integer":false, "metal_costs":{"lead":700, "copper":1000, "iron":1400, "aluminium":2000, "silver":2500, "gold":3500}},
				"SE":{"value":1.0, "pw":1.015, "is_value_integer":false, "metal_costs":{"lead":700, "copper":1400, "iron":2800, "aluminium":5600, "silver":11200, "gold":22400}},
}

var costs = {	"ME":{"money":100, "energy":40, "time":12.0},
				"PP":{"money":80, "time":18.0},
				"RL":{"money":2000, "energy":600, "time":150.0},
				"MS":{"money":500, "energy":80, "time":40.0},
				"RCC":{"money":20000, "energy":4000, "time":280.0},
				"SC":{"money":2200, "energy":800, "time":150.0},
				"GF":{"money":1500, "energy":1000, "time":120.0},
				"SE":{"money":1500, "energy":500, "time":120.0},
				"MM":{"money":13000, "energy":7000, "time":400.0},
				"rover":{"money":5000, "energy":300, "time":80.0},
				"GH":{"money":10000, "energy":1500, "glass":200, "time":75.0},
				"SP":{"money":4000, "time":90.0},
				"AE":{"money":415000, "energy":250000, "time":450.0},
				"AMN":{"money":5800000, "energy":82000, "time":990.0},
				"SPR":{"money":65000000, "energy":613000, "time":3400.0},
}

var MS_costs = {	"M_DS_0":{"money":30000000000, "stone":800000000, "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"M_SE_0":{"money":700000, "stone":50000, "energy":50000, "copper":800, "iron":1000, "aluminium":300, "time":2*3600},#2*3600
					"M_SE_1":{"money":3200000, "stone":200000, "energy":200000, "copper":1000, "iron":1400, "aluminium":400, "time":8*3600},#8, 8, 12
					"M_SE_2":{"money":6800000, "stone":350000, "energy":350000, "copper":2000, "iron":2800, "aluminium":800, "time":8*3600},
					"M_SE_3":{"money":10000000, "stone":500000, "energy":500000, "copper":8000, "iron":10000, "aluminium":3000, "time":12*3600},
					"M_MME_0":{"money":500000000, "stone":40000000, "copper":10000, "iron":8000, "aluminium":30000, "titanium":3000, "time":8},#* 3600
					"M_MME_1":{"money":4500000000, "stone":320000000, "copper":90000, "iron":75000, "aluminium":300000, "titanium":30000, "time":32},
}

var MS_output = {	"M_DS_0":50000000,
					"M_MME_0":20000,
					"M_MME_1":175000,
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
						"ATM":{"cost":90000, "parents":[]},
						"SAP":{"cost":12500000, "parents":["ATM"]},
						
						#Rover sciences
						"RC":{"cost":250, "parents":[]},
						"OL":{"cost":1000, "parents":["RC"]},
						"YL":{"cost":8000, "parents":["OL"]},
						"GL":{"cost":40000, "parents":["YL"]},
						"BL":{"cost":250000, "parents":["GL"]},
						"PL":{"cost":1400000, "parents":["BL"]},
						"UVL":{"cost":8000000, "parents":["PL"]},
						"XRL":{"cost":44000000, "parents":["UVL"]},
						"GRL":{"cost":300000000, "parents":["XRL"]},
						"UGRL":{"cost":2000000000, "parents":["GRL"]},
						
						#Ship sciences
						"SCT":{"cost":1500, "parents":["RC"]},
						"CD":{"cost":4000, "parents":["SCT"]},
						"ID":{"cost":100000, "parents":["CD", "ATM"]},
						"FD":{"cost":1500000, "parents":["ID"]},
						"PD":{"cost":12000000, "parents":["FD"]},
						
						#Megastructure sciences
						"MAE":{"cost":100000, "parents":[]},
						#Dyson sphere
						"DS1":{"cost":120000000, "parents":["MAE"]},
						"DS2":{"cost":250000000, "parents":["DS1"]},
						"DS3":{"cost":500000000, "parents":["DS2"]},
						"DS4":{"cost":750000000, "parents":["DS3"]},
						#Space elevator
						"SE1":{"cost":150000, "parents":["MAE"]},
						"SE2":{"cost":300000, "parents":["SE1"]},
						"SE3":{"cost":500000, "parents":["SE2"]},
						
						#Mega mineral extractor
						"MME1":{"cost":17000000, "parents":["MAE"]},
						"MME2":{"cost":40000000, "parents":["MME1"]},
						"MME3":{"cost":72000000, "parents":["MME2"]},
						
}
var infinite_research_sciences = {	"MEE":{"cost":5000, "pw":6.2, "value":1.2},
									"EPE":{"cost":8000, "pw":6.2, "value":1.2},
									"RLE":{"cost":25000, "pw":6.8, "value":1.2},
									"MSE":{"cost":7000, "pw":6.2, "value":1.2},
									"MMS":{"cost":3000, "pw":6.0, "value":1.2},
}

var rover_armor = {	"lead_armor":{"HP":5, "defense":3, "costs":{"lead":40}},
					"copper_armor":{"HP":10, "defense":5, "costs":{"copper":40}},
					"iron_armor":{"HP":15, "defense":7, "costs":{"iron":40}},
					"aluminium_armor":{"HP":20, "defense":9, "costs":{"aluminium":80}},
					"silver_armor":{"HP":25, "defense":11, "costs":{"silver":80}},
					"gold_armor":{"HP":35, "defense":14, "costs":{"gold":100}},
					"gemstone_armor":{"HP":50, "defense":18, "costs":{"amethyst":30, "quartz":30, "topaz":30, "sapphire":30, "emerald":30, "ruby":30}},
}
var rover_wheels = {	"lead_wheels":{"speed":1.0, "costs":{"lead":30}},
						"copper_wheels":{"speed":1.05, "costs":{"copper":30}},
						"iron_wheels":{"speed":1.1, "costs":{"iron":30}},
						"aluminium_wheels":{"speed":1.15, "costs":{"aluminium":60}},
						"silver_wheels":{"speed":1.2, "costs":{"silver":60}},
						"gold_wheels":{"speed":1.3, "costs":{"gold":75}},
						"gemstone_wheels":{"speed":1.4, "costs":{"amethyst":25, "quartz":25, "topaz":25, "sapphire":25, "emerald":25, "ruby":25}},
}
var rover_CC = {	"lead_CC":{"capacity":2500, "costs":{"lead":70}},
					"copper_CC":{"capacity":3500, "costs":{"copper":70}},
					"iron_CC":{"capacity":4000, "costs":{"iron":70}},
					"aluminium_CC":{"capacity":4500, "costs":{"aluminium":100}},
					"silver_CC":{"capacity":5000, "costs":{"silver":100}},
					"gold_CC":{"capacity":6000, "costs":{"gold":140}},
					"gemstone_CC":{"capacity":7000, "costs":{"amethyst":50, "quartz":50, "topaz":50, "sapphire":50, "emerald":50, "ruby":50}},
}
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":3400, "silicon":5, "time":10}},
						"orange_laser":{"damage":12, "cooldown":0.195, "costs":{"money":20000, "silicon":10, "time":60}},
						"yellow_laser":{"damage":29, "cooldown":0.19, "costs":{"money":150000, "silicon":15, "time":360}},
						"green_laser":{"damage":68, "cooldown":0.185, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_laser":{"damage":150, "cooldown":0.18, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_laser":{"damage":285, "cooldown":0.175, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"UV_laser":{"damage":550, "cooldown":0.17, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_laser":{"damage":1400, "cooldown":0.165, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gammaray_laser":{"damage":3250, "cooldown":0.16, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_laser":{"damage":30000, "cooldown":1, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":3000, "silicon":5, "time":10}},
						"orange_mining_laser":{"speed":1.4, "rnge":260, "costs":{"money":20000, "silicon":10, "time":60}},
						"yellow_mining_laser":{"speed":1.9, "rnge":270, "costs":{"money":150000, "silicon":15, "time":360}},
						"green_mining_laser":{"speed":2.5, "rnge":285, "costs":{"money":900000, "silicon":20, "time":1500}},
						"blue_mining_laser":{"speed":3, "rnge":300, "costs":{"money":2500000, "silicon":50, "quartz":25, "time":4500}},
						"purple_mining_laser":{"speed":3.6, "rnge":315, "costs":{"money":7500000, "silicon":100, "quartz":50, "time":9000}},
						"UV_mining_laser":{"speed":4.3, "rnge":330, "costs":{"money":32500000, "silicon":200, "quartz":100, "time":18000}},
						"xray_mining_laser":{"speed":5.1, "rnge":350, "costs":{"money":125000000, "silicon":500, "quartz":200, "time":30000}},
						"gammaray_mining_laser":{"speed":6, "rnge":380, "costs":{"money":2500000000, "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_mining_laser":{"speed":10, "rnge":230, "costs":{"money":20000000000, "silicon":2500, "quartz":1000, "time":100000}},
}
var bullet_data = [{"damage":7, "accuracy":1.0}, {"damage":10, "accuracy":1.05}]
var laser_data = [{"damage":4, "accuracy":1.5}, {"damage":6, "accuracy":1.6}]
var bomb_data = [{"damage":12, "accuracy":0.7}, {"damage":16, "accuracy":0.72}]
var light_data = [{"damage":3, "accuracy":1.2}, {"damage":5, "accuracy":1.25}]

#the numbers are the elements' abundance relative to hydrogen
var elements = {"NH3":0.05, "CO2":0.01, "H":1.0, "He":0.325, "CH4":0.2, "O":0.014, "H2O":0.05, "Ne":0.001813, "Xe":0.0000022}
