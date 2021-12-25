extends Node

enum ProjType {STANDARD, LASER, BUBBLE}

var path_1 = {	"ME":{"value":0.36, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":20, "copper":35, "iron":50, "aluminium":70, "silver":100, "gold":150, "platinum":250}},
				"PP":{"value":0.6, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"RL":{"value":0.06, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150, "silver":150, "gold":150, "platinum":150}},
				"MS":{"value":100, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				"RCC":{"value":1.0, "pw":1.06, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
				"SC":{"value":50.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":1, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":40.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"MM":{"value":0.01, "pw":1.1, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.5, "pw":1.04, "is_value_integer":false, "metal_costs":{"lead":500, "copper":500, "iron":600, "aluminium":600, "silver":700, "gold":700}},
				"SP":{"value":2.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":0.2, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"AMN":{"value":1.0, "pw":1.16, "is_value_integer":false, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.16, "is_value_integer":false, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				"SY":{"value":1.0, "pw":1.16, "is_value_integer":false, "metal_costs":{"lead":640000, "copper":640000, "iron":640000, "aluminium":960000, "silver":960000, "gold":1280000}},
				"CBD":{"value":1.111111, "pw":1.04, "cost_mult":1.5, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
				"PC":{"value":1000.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"NC":{"value":1000.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"EC":{"value":1000.0, "pw":1.15, "time_based":true, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"NSF":{"value":50000.0, "pw":1.15, "time_based":false, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"ESF":{"value":50000.0, "pw":1.15, "time_based":false, "is_value_integer":false, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
}
var path_2 = {	"ME":{"value":30, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"PP":{"value":140, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"SC":{"value":4000, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":600, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":100, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"MM":{"value":4, "pw":1.1, "is_value_integer":true, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.1, "pw":1.1, "is_value_integer":false, "metal_costs":{"lead":1000, "copper":1000, "iron":1200, "aluminium":1200, "silver":1400, "gold":1400}},
				"SP":{"value":4200, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AMN":{"value":1.0, "pw":1.14, "is_value_integer":false, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.14, "is_value_integer":false, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				"AE":{"value":120, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"CBD":{"value":10, "step":2, "cap":46, "is_value_integer":true},
}
var path_3 = {	"SC":{"value":1.0, "pw":1.01, "cap":70, "is_value_integer":false, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				"GF":{"value":1.0, "pw":1.01, "cap":70, "is_value_integer":false, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				"SE":{"value":1.0, "pw":1.04, "is_value_integer":false, "metal_costs":{"lead":700, "copper":1400, "iron":2800, "aluminium":5600, "silver":11200, "gold":22400}},
				"CBD":{"value":3, "step":2, "cost_mult":12, "cost_pw":2.7, "is_value_integer":true},
}

var costs = {	"ME":{"money":100, "energy":40, "time":6.0},
				"PP":{"money":80, "time":3.0},
				"RL":{"money":2000, "energy":600, "time":130.0},
				"MS":{"money":500, "energy":80, "time":20.0},
				"RCC":{"money":5000, "energy":400, "time":140.0},
				"SC":{"money":900, "energy":150, "time":50.0},
				"GF":{"money":1500, "energy":1000, "time":120.0},
				"SE":{"money":1500, "energy":500, "time":120.0},
				"MM":{"money":13000, "energy":7000, "time":200.0},
				"GH":{"money":10000, "energy":1500, "glass":500, "time":75.0},
				"SP":{"money":4000, "time":90.0},
				"AE":{"money":41500, "energy":15000, "time":180.0},
				"AMN":{"money":580000, "energy":8200, "time":490.0},
				"SPR":{"money":3500000, "energy":61300, "time":1400.0},
				"SY":{"money":e(5, 8), "energy":900000, "time":5000.0},
				"PCC":{"money":e(2.25, 11), "energy":e(7.8, 9), "time":840000},
				"CBD":{"money":7000, "energy":1000, "time":360.0},
				"TP":{"money":e(2.5, 23), "energy":e(2.5, 23)},#Triangulum probe
				"rover":{"money":2000, "energy":400, "time":50.0},
				"PC":{"money":1000000, "energy":50000, "time":600.0},
				"NC":{"money":e(2.0, 7), "energy":e(3.2, 6), "time":4000.0},
				"EC":{"money":e(3.0, 7), "energy":e(4.0, 6), "time":9001.0},
				"NSF":{"money":e(1.2, 7), "energy":e(1.0, 6), "time":4000.0},
				"ESF":{"money":e(3.5, 7), "energy":e(7.0, 6), "time":10000.0},
}

func e(n, e):
	return n * pow(10, e)

var MS_costs = {	"doom_ball":{"money":e(5.4, 12), "stone":e(5.4, 7), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"notachicken_star":{"money":e(4.3, 7), "chickens":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"moon_but_not":{"money":e(8, 24), "moon_lords":e(2.1, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"killer_queen":{"money":e(7.8, 13), "honey":e(7.8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"M_DS_0":{"money":e(1.3, 10), "stone":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"M_DS_1":{"money":e(3.8, 11), "stone":e(2.7, 10), "silicon":e(1.5, 7), "copper":e(1.2, 7), "iron":e(8, 7), "aluminium":e(2.2, 7), "titanium":e(2.1, 6), "time":30 * 86400},
					"M_DS_2":{"money":e(1.5, 13), "stone":e(9.6, 11), "silicon":e(5.3, 8), "copper":e(4.0, 8), "iron":e(3.2, 9), "aluminium":e(8.7, 8), "titanium":e(8.8, 7), "time":60 * 86400},
					"M_DS_3":{"money":e(6.4, 14), "stone":e(3.5, 13), "silicon":e(2.5, 10), "copper":e(1.5, 10), "iron":e(1.4, 11), "aluminium":e(3, 10), "titanium":e(3, 9), "time":90 * 86400},
					"M_DS_4":{"money":e(2.5, 16), "stone":e(1.1, 15), "silicon":e(8.8, 11), "copper":e(5.6, 11), "iron":e(5.5, 12), "aluminium":e(1, 12), "titanium":e(9.6, 10), "time":120 * 86400},
					"M_SE_0":{"money":700000, "stone":50000, "energy":10000, "copper":800, "iron":1000, "aluminium":300, "time":2*3600},
					"M_SE_1":{"money":10000000, "stone":500000, "energy":45000, "copper":6000, "iron":10000, "aluminium":3000, "time":12 * 3600},
					"M_MME_0":{"money":e(2, 7), "stone":e(1, 6), "copper":1500, "iron":12000, "aluminium":5000, "titanium":300, "time":4 * 3600},
					"M_MME_1":{"money":e(6.5, 8), "stone":e(5, 7), "copper":70000, "iron":650000, "aluminium":200000, "titanium":12000, "time":48 * 3600},
					"M_MME_2":{"money":e(2.4, 10), "stone":e(2, 9), "copper":e(2.5, 6), "iron":e(2.5, 7), "aluminium":e(7.5, 6), "titanium":500000, "time":96 * 3600},
					"M_MME_3":{"money":e(9.5, 11), "stone":e(7, 10), "copper":e(8, 7), "iron":e(1, 9), "aluminium":e(3, 8), "titanium":e(1.5, 7), "time":150 * 3600},
					"M_MB":{"money":e(5.5, 17), "stone":e(1, 13), "copper":e(3, 11), "iron":e(1, 11), "aluminium":e(2, 12), "nanocrystal":e(8, 11), "time":120 * 86400},
					"M_PK_0":{"money":e(2, 15), "stone":e(4, 14), "iron":e(1, 11), "aluminium":e(1.75, 10), "time":24 * 86400},
					"M_PK_1":{"money":e(9.5, 16), "stone":e(4, 16), "iron":e(8.5, 12), "aluminium":e(8, 12), "time":48 * 86400},
					"M_PK_2":{"money":e(6.5, 19), "stone":e(8.75, 20), "iron":e(2.25, 16), "aluminium":e(1.5, 15), "time":96 * 86400},
					"M_MPCC_0":{"money":e(4.4, 17), "stone":e(7.1, 14), "energy":e(9, 16), "quartz":e(4.8, 13), "nanocrystal":e(3.1, 13), "time":10 * 86400},
}

var MS_output = {	"M_DS_0":e(1, 8),
					"M_DS_1":e(3.8, 9),
					"M_DS_2":e(1.5, 11),
					"M_DS_3":e(5.8, 12),
					"M_DS_4":e(2.2, 14),
					"M_MME_0":2400,
					"M_MME_1":127000,
					"M_MME_2":e(4.0, 7),
					"M_MME_3":e(1.5, 9),
					"M_MB":e(5.0, 12),
}

var MUs = {	"MV":{"base_cost":100, "pw":1.9},
			"MSMB":{"base_cost":100, "pw":1.6},
			"IS":{"base_cost":500, "pw":1.9},
			"AIE":{"base_cost":1000, "pw":2.3},
			"STMB":{"base_cost":600, "pw":1.6},
			"SHSR":{"base_cost":2000, "pw":1.9},
			"CHR":{"base_cost":2000, "pw":1.7},
}
var minerals_icon = preload("res://Graphics/Icons/minerals.png")
var energy_icon = preload("res://Graphics/Icons/energy.png")
var time_icon = preload("res://Graphics/Icons/Time.png")
var stone_icon = preload("res://Graphics/Icons/stone.png")
var SP_icon = preload("res://Graphics/Icons/SP.png")
var glass_icon = preload("res://Graphics/Materials/glass.png")
var sand_icon = preload("res://Graphics/Materials/sand.png")
var coal_icon = preload("res://Graphics/Materials/coal.png")
var MM_icon = preload("res://Graphics/Icons/MM.png")
var atom_icon = preload("res://Graphics/Science/ATM.png")
var particle_icon = preload("res://Graphics/Science/SAP.png")
var proton_icon = preload("res://Graphics/Particles/proton.png")
var neutron_icon = preload("res://Graphics/Particles/neutron.png")
var electron_icon = preload("res://Graphics/Particles/electron.png")

var desc_icons = {	"ME":[[minerals_icon], [minerals_icon]],
					"PP":[[energy_icon], [energy_icon]],
					"RL":[[SP_icon]],
					"MS":[[minerals_icon]],
					"SC":[[stone_icon], [stone_icon], []],
					"GF":[[glass_icon], [sand_icon], []],
					"SE":[[energy_icon], [coal_icon], []],
					"SP":[[energy_icon], [energy_icon]],
					"PC":[[proton_icon]],
					"NC":[[neutron_icon]],
					"NSF":[[neutron_icon]],
					"EC":[[electron_icon]],
					"ESF":[[electron_icon]],
					"CBD":[[], [energy_icon, minerals_icon], []]
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
					"PC":proton_icon,
					"NC":neutron_icon,
					"NSF":neutron_icon,
					"EC":electron_icon,
					"ESF":electron_icon,
}

var default_stats:Dictionary = {
		"bldgs_built":0,
		"MS_constructed":0,
		"total_money_earned":0,
		"wormholes_activated":0,
		"planets_conquered":1,
		"systems_conquered":0,
		"galaxies_conquered":0,
		"clusters_conquered":0,
		"enemies_rekt_in_battle":0,
		"enemies_rekt_in_caves":0,
		"chests_looted":0,
		"tiles_mined_mining":0,
		"tiles_mined_caves":0,
		"biggest_planet":0,
		"biggest_star":1,
		"hottest_star":5500,
		"highest_au_int":0,
		"star_classes":{
			"Y":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"T":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"L":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"M":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"K":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"G":[0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
			"F":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"A":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"B":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"O":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"Q":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"R":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
			"Z":[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		},
		"star_types":{
			"brown_dwarf":0,
			"white_dwarf":0,
			"main_sequence":1,
			"giant":0,
			"supergiant":0,
			"hypergiant":0,
		},
		"clicks":0,
		"right_clicks":0,
		"scrolls":0,
		"mouse_travel_distance":0,
		"keyboard_presses":0,
}

func reload():
	path_1.ME.desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.AE.desc = tr("EXTRACTS_X") % ["%s mol/" + tr("S_SECOND")]
	path_1.PP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RL.desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RCC.desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1.SY.desc = tr("MULT_FIGHTER_STAT_BY") % ["%s"]
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_1.SC.desc = tr("CRUSHES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1.GF.desc = tr("PRODUCES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1.SE.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.MM.desc = tr("X_M_PER_SECOND") % ["%s", tr("S_SECOND")]
	path_1.GH.desc = tr("X_PLANT_GROWTH")
	path_1.SP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.AMN.desc = "%s: %%s" % [tr("BASE_SPEED")]
	path_1.SPR.desc = "%s: %%s" % [tr("BASE_SPEED")]
	path_1.PC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.NC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.EC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.NSF.desc = tr("STORES_X") % ["@i %s mol"]
	path_1.ESF.desc = tr("STORES_X") % ["@i %s mol"]
	path_2.ME.desc = tr("X_CAPACITY") % [" @i %s"]
	path_2.AE.desc = tr("STORES_X") % ["%s mol"]
	path_2.PP.desc = tr("X_CAPACITY") % [" @i %s"]
	path_2.SC.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.GF.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.SE.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.MM.desc = tr("X_M_AT_ONCE")
	path_2.GH.desc = tr("X_PLANT_PRODUCE")
	path_2.SP.desc = tr("X_CAPACITY") % [" @i %s"]
	path_3.SC.desc = tr("OUTPUT_MULTIPLIER")
	path_3.GF.desc = tr("OUTPUT_MULTIPLIER")
	path_3.SE.desc = tr("OUTPUT_MULTIPLIER")
	path_1.CBD.desc = tr("CBD_PATH_1")
	path_2.CBD.desc = tr("CBD_PATH_2")
	path_3.CBD.desc = tr("CBD_PATH_3")
	path_2.AMN.desc = tr("DIVIDES_ENERGY_COSTS_BY")
	path_2.SPR.desc = tr("DIVIDES_ENERGY_COSTS_BY")

var lakes = {	"water":{"color":Color(0.38, 0.81, 1.0, 1.0)}}

#Science for unlocking game features
var science_unlocks = {	
						#Agriculture sciences
						"SA":{"cost":100, "parents":[]},
						"EGH":{"cost":3500, "parents":["SA"]},
						"GHA":{"cost":e(3.7, 7), "parents":["EGH"]},
						
						#Auto mining
						"AM":{"cost":10000, "parents":[]},
						
						#Improved stone crusher
						"ISC":{"cost":250, "parents":[]},
						
						#Compact items
						"CI":{"cost":4800, "parents":[]},
						"CI2":{"cost":e(4.8, 6), "parents":["CI"]},
						"CI3":{"cost":e(4.8, 9), "parents":["CI2"]},
						
						#Atom manipulation
						"ATM":{"cost":200000, "parents":[]},
						"AMM":{"cost":e(1.0, 13), "parents":["ATM"]},
						"SAP":{"cost":12500000, "parents":["ATM"]},
						
						#Rover sciences
						"RC":{"cost":5, "parents":[]},
						"OL":{"cost":1000, "parents":["RC"]},
						"YL":{"cost":12000, "parents":["OL"]},
						"GL":{"cost":70000, "parents":["YL"]},
						"BL":{"cost":350000, "parents":["GL"]},
						"PL":{"cost":2400000, "parents":["BL"]},
						"UVL":{"cost":e(2.8, 7), "parents":["PL"]},
						"XRL":{"cost":e(4.05, 8), "parents":["UVL"]},
						"GRL":{"cost":e(6.5, 9), "parents":["XRL"]},
						"UGRL":{"cost":e(1, 12), "parents":["GRL"]},
						
						"RMK2":{"cost":e(5, 6), "parents":["RC"]},
						"RMK3":{"cost":e(5, 10), "parents":["RMK2"]},
						
						#Ship sciences
						"SCT":{"cost":350, "parents":["RC"]},
						"CD":{"cost":2400, "parents":["SCT"]},
						"FTL":{"cost":128000, "parents":["SCT"]},
						"IGD":{"cost":e(9.5, 7), "parents":["FTL"]},
						"FG":{"cost":e(3.45, 9), "parents":["IGD"]},
						"ID":{"cost":450000, "parents":["CD", "ATM"]},
						"FD":{"cost":e(1.5, 8), "parents":["ID"]},
						"PD":{"cost":e(1.2, 12), "parents":["FD"]},
						
						"UP1":{"cost":e(5, 7), "parents":["SCT"]},
						"UP2":{"cost":e(5, 10), "parents":["UP1"]},
						"UP3":{"cost":e(5, 13), "parents":["UP2"]},
						"UP4":{"cost":e(5, 16), "parents":["UP3"]},
						
						#Megastructure sciences
						"MAE":{"cost":100000, "parents":["SCT"]},
						"TF":{"cost":e(5.6, 8), "parents":["MAE"]},
						#Dyson sphere
						"DS1":{"cost":e(1.2, 11), "parents":["MAE"]},
						"DS2":{"cost":e(4.8, 12), "parents":["DS1"]},
						"DS3":{"cost":e(2.1, 14), "parents":["DS2"]},
						"DS4":{"cost":e(8.0, 15), "parents":["DS3"]},
						#Matrioshka brain
						"MB":{"cost":e(2.6, 16), "parents":["DS4"]},
						#Space elevator
						"SE1":{"cost":700000, "parents":["MAE"]},
						
						#Mega mineral extractor
						"MME1":{"cost":e(1.7, 9), "parents":["MAE"]},
						"MME2":{"cost":e(6.0, 10), "parents":["MME1"]},
						"MME3":{"cost":e(2.4, 12), "parents":["MME2"]},
						
						#Planetkiller
						"PK1":{"cost":e(5.25, 14), "parents":["MAE"]},
						"PK2":{"cost":e(3.4, 16), "parents":["PK1"]},
						
						#Mega probe construction center
						"MPCC":{"cost":e(2.9, 15), "parents":["MAE"]},
						
						#Gigastructures
						"GS":{"cost":e(1, 19), "parents":["MB"]},
						
						#Triangulum probe
						"TPCC":{"cost":e(1, 23), "parents":["GS"]},
}

var infinite_research_sciences = {	"MEE":{"cost":250, "pw":6.2},
									"EPE":{"cost":400, "pw":6.2},
									"RLE":{"cost":1250, "pw":6.8},
									"MSE":{"cost":350, "pw":6.2},
									"MMS":{"cost":150, "pw":6.0},
									"PME":{"cost":10000000, "pw":6.8},
}

var rover_armor = {	"stone_armor":{"HP":2, "defense":1, "costs":{"stone":200}},
					"lead_armor":{"HP":5, "defense":2, "costs":{"lead":40}},
					"copper_armor":{"HP":10, "defense":3, "costs":{"copper":50}},
					"iron_armor":{"HP":15, "defense":4, "costs":{"iron":65}},
					"aluminium_armor":{"HP":20, "defense":5, "costs":{"aluminium":90}},
					"silver_armor":{"HP":30, "defense":6, "costs":{"silver":130}},
					"gold_armor":{"HP":50, "defense":7, "costs":{"gold":190}},
					"titanium_armor":{"HP":80, "defense":9, "costs":{"titanium":240}},
					"gemstone_armor":{"HP":85, "defense":10, "costs":{"amethyst":70, "quartz":70, "topaz":70, "sapphire":70, "emerald":70, "ruby":70}},
					"platinum_armor":{"HP":130, "defense":12, "costs":{"platinum":600}},
					"diamond_armor":{"HP":180, "defense":15, "costs":{"diamond":750}},
					"nanocrystal_armor":{"HP":240, "defense":18, "costs":{"nanocrystal":1600}},
					"mythril_armor":{"HP":400, "defense":22, "costs":{"mythril":3800}},
}
var rover_wheels = {	"stone_wheels":{"speed":1.0, "costs":{"stone":100}},
						"lead_wheels":{"speed":1.05, "costs":{"lead":30}},
						"copper_wheels":{"speed":1.1, "costs":{"copper":40}},
						"iron_wheels":{"speed":1.15, "costs":{"iron":50}},
						"aluminium_wheels":{"speed":1.2, "costs":{"aluminium":70}},
						"silver_wheels":{"speed":1.25, "costs":{"silver":100}},
						"gold_wheels":{"speed":1.3, "costs":{"gold":150}},
						"titanium_wheels":{"speed":1.6, "costs":{"titanium":200}},
						"gemstone_wheels":{"speed":1.7, "costs":{"amethyst":60, "quartz":60, "topaz":60, "sapphire":60, "emerald":60, "ruby":60}},
						"platinum_wheels":{"speed":1.75, "costs":{"platinum":500}},
						"diamond_wheels":{"speed":1.95, "costs":{"diamond":650}},
						"nanocrystal_wheels":{"speed":2.2, "costs":{"nanocrystal":1100}},
						"mythril_wheels":{"speed":2.5, "costs":{"mythril":1600}},
}
var rover_CC = {	"stone_CC":{"capacity":1500, "costs":{"stone":250}},
					"lead_CC":{"capacity":2500, "costs":{"lead":70}},
					"copper_CC":{"capacity":3500, "costs":{"copper":90}},
					"iron_CC":{"capacity":5000, "costs":{"iron":110}},
					"aluminium_CC":{"capacity":7000, "costs":{"aluminium":130}},
					"silver_CC":{"capacity":10000, "costs":{"silver":150}},
					"gold_CC":{"capacity":15000, "costs":{"gold":200}},
					"titanium_CC":{"capacity":31000, "costs":{"titanium":250}},
					"gemstone_CC":{"capacity":35000, "costs":{"amethyst":75, "quartz":75, "topaz":75, "sapphire":75, "emerald":75, "ruby":75}},
					"platinum_CC":{"capacity":42000, "costs":{"platinum":700}},
					"diamond_CC":{"capacity":59000, "costs":{"diamond":1000}},
					"nanocrystal_CC":{"capacity":90000, "costs":{"nanocrystal":1700}},
					"mythril_CC":{"capacity":175000, "costs":{"mythril":3500}},
}
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":1000, "silicon":10, "time":10}},
						"orange_laser":{"damage":8, "cooldown":0.195, "costs":{"money":17000, "silicon":12, "time":60}},
						"yellow_laser":{"damage":14, "cooldown":0.19, "costs":{"money":190000, "silicon":15, "time":360}},
						"green_laser":{"damage":22, "cooldown":0.185, "costs":{"money":950000, "silicon":20, "time":1500}},
						"blue_laser":{"damage":40, "cooldown":0.18, "costs":{"money":e(5.2, 6), "silicon":50, "quartz":25, "time":4500}},
						"purple_laser":{"damage":75, "cooldown":0.175, "costs":{"money":e(3.7, 7), "silicon":100, "quartz":50, "time":9000}},
						"UV_laser":{"damage":140, "cooldown":0.165, "costs":{"money":e(3.1, 8), "silicon":200, "quartz":100, "time":18000}},
						"xray_laser":{"damage":270, "cooldown":0.155, "costs":{"money":e(9.8, 9), "silicon":500, "quartz":200, "time":30000}},
						"gammaray_laser":{"damage":525, "cooldown":0.14, "costs":{"money":e(2.5, 11), "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_laser":{"damage":1200, "cooldown":0.1, "costs":{"money":e(1.5, 13), "silicon":2500, "quartz":1000, "time":100000}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":1000, "silicon":10, "time":10}},
						"orange_mining_laser":{"speed":1.4, "rnge":260, "costs":{"money":17000, "silicon":12, "time":60}},
						"yellow_mining_laser":{"speed":1.9, "rnge":270, "costs":{"money":190000, "silicon":15, "time":360}},
						"green_mining_laser":{"speed":2.5, "rnge":285, "costs":{"money":950000, "silicon":20, "time":1500}},
						"blue_mining_laser":{"speed":3.3, "rnge":300, "costs":{"money":e(5.2, 6), "silicon":50, "quartz":25, "time":4500}},
						"purple_mining_laser":{"speed":4.3, "rnge":315, "costs":{"money":e(3.7, 7), "silicon":100, "quartz":50, "time":9000}},
						"UV_mining_laser":{"speed":6, "rnge":330, "costs":{"money":e(3.1, 8), "silicon":200, "quartz":100, "time":18000}},
						"xray_mining_laser":{"speed":9.1, "rnge":350, "costs":{"money":e(4.0, 9), "silicon":500, "quartz":200, "time":30000}},
						"gammaray_mining_laser":{"speed":12, "rnge":380, "costs":{"money":e(9.4, 10), "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_mining_laser":{"speed":16, "rnge":500, "costs":{"money":e(1.0, 12), "silicon":2500, "quartz":1000, "time":100000}},
}
var bullet_data = [{"damage":3.5, "accuracy":1.0}, {"damage":5, "accuracy":1.05}, {"damage":9, "accuracy":1.1}, {"damage":19, "accuracy":1.3}]
var laser_data = [{"damage":2.5, "accuracy":2.2}, {"damage":3.5, "accuracy":2.4}, {"damage":6.5, "accuracy":2.7}, {"damage":13, "accuracy":3.3}]
var bomb_data = [{"damage":6, "accuracy":0.7}, {"damage":8, "accuracy":0.72}, {"damage":15, "accuracy":0.75}, {"damage":34, "accuracy":0.8}]
var light_data = [{"damage":1.5, "accuracy":1.3}, {"damage":2.5, "accuracy":1.35}, {"damage":4.0, "accuracy":1.45}, {"damage":8.0, "accuracy":1.7}]

#the numbers are the elements' abundance relative to hydrogen
var elements = {"NH3":0.05, "CO2":0.01, "H":1.0, "He":0.325, "CH4":0.2, "O":0.014, "H2O":0.15, "Ne":0.001813, "Xe":0.0000022}

var univ_prop_weights:Dictionary = {
	"speed_of_light":10,
	"planck":20,
	"boltzmann":10,
	"gravitational":30,
	"charge":20,
	"dark_energy":25,
	"difficulty":10,
	"time_speed":50,
	"antimatter":0,
	"universe_value":50,
	}
