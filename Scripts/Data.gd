extends Node

enum ProjType {STANDARD, LASER, BUBBLE, PURPLE}#For caves

var path_1 = {	"ME":{"value":0.36, "pw":1.15, "time_based":true, "metal_costs":{"lead":20, "copper":35, "iron":50, "aluminium":70, "silver":100, "gold":150, "platinum":250}},
				"PP":{"value":0.6, "pw":1.15, "time_based":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				"RL":{"value":0.06, "pw":1.15, "time_based":true, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150, "silver":150, "gold":150, "platinum":150}},
				"B":{"value":12000, "pw":1.17, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				"MS":{"value":100, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				"RCC":{"value":1.0, "pw":1.07, "metal_costs":{"lead":1500, "copper":3500, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
				"SC":{"value":50.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":1, "pw":1.15, "time_based":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":40.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"MM":{"value":0.02, "pw":1.1, "time_based":true, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				"GH":{"value":1.0, "pw":1.11, "metal_costs":{"lead":500, "copper":500, "iron":600, "aluminium":600, "silver":700, "gold":700}},
				"SP":{"value":2.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				"AE":{"value":0.2, "pw":1.15, "time_based":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				"AMN":{"value":1.0, "pw":1.16, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.16, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				"SY":{"value":1.0, "pw":1.16, "metal_costs":{"lead":640000, "copper":640000, "iron":640000, "aluminium":960000, "silver":960000, "gold":1280000}},
				"CBD":{"value":1.111111, "pw":1.03, "cost_mult":1.5, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
				"PC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"NC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"EC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"NSF":{"value":50000.0, "pw":1.15, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
				"ESF":{"value":50000.0, "pw":1.15, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
}
var path_2 = {	"SC":{"value":4000, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				"GF":{"value":600, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"SE":{"value":100, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				"GH":{"value":1.0, "pw":1.07, "metal_costs":{"lead":1000, "copper":1000, "iron":1200, "aluminium":1200, "silver":1400, "gold":1400}},
				"AMN":{"value":1.0, "pw":1.05, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				"SPR":{"value":1.0, "pw":1.05, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				"CBD":{"value":1.1, "step":0.02, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
}
var path_3 = {	"SC":{"value":1.0, "pw":1.01, "cap":70, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				"GF":{"value":1.0, "pw":1.01, "cap":70, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				"SE":{"value":1.0, "pw":1.04, "metal_costs":{"lead":700, "copper":1400, "iron":2800, "aluminium":5600, "silver":11200, "gold":22400}},
				"CBD":{"value":3, "step":2, "cost_mult":12, "cost_pw":2.7, "is_value_integer":true},
}

var costs = {	"ME":{"money":100, "energy":40, "time":6.0},
				"PP":{"money":80, "time":3.0},
				"RL":{"money":2000, "energy":600, "time":130.0},
				"B":{"money":400, "energy":100, "time":20.0},
				"MS":{"money":500, "energy":60, "time":20.0},
				"RCC":{"money":5000, "energy":400, "time":140.0},
				"SC":{"money":900, "energy":150, "time":50.0},
				"GF":{"money":1500, "energy":1000, "time":120.0},
				"SE":{"money":1500, "energy":500, "time":120.0},
				"MM":{"money":13000, "energy":7000, "time":200.0},
				"GH":{"money":10000, "energy":1500, "glass":50, "soil":100, "time":75.0},
				"SP":{"money":4000, "time":90.0},
				"AE":{"money":41500, "energy":15000, "time":180.0},
				"AMN":{"money":580000, "energy":8200, "time":490.0},
				"SPR":{"money":3500000, "energy":61300, "time":1400.0},
				"SY":{"money":e(5, 8), "energy":900000, "time":5000.0},
				"PCC":{"money":2.5e12, "energy":7.8e10, "time":840000},
				"CBD":{"money":7000, "energy":1000, "time":360.0},
				"TP":{"money":e(1.5, 24), "energy":e(1.5, 24)},#Triangulum probe
				"GK":{"money":e(7.5, 23), "energy":e(5.0, 24)},#Galaxy-killer
				"rover":{"money":2000, "energy":400, "time":50.0},
				"PC":{"money":1000000, "energy":50000, "time":600.0},
				"NC":{"money":e(2.0, 7), "energy":e(3.2, 6), "time":4000.0},
				"EC":{"money":e(3.0, 7), "energy":e(4.0, 6), "time":9001.0},
				"NSF":{"money":e(7.5, 6), "energy":e(1.0, 6), "time":4000.0},
				"ESF":{"money":e(1.2, 7), "energy":e(7.0, 6), "time":10000.0},
}

func e(n, e):
	return n * pow(10, e)

var MS_costs = {	"doom_ball":{"money":e(5.4, 12), "stone":e(5.4, 7), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"notachicken_star":{"money":e(4.3, 7), "chickens":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"moon_but_not":{"money":e(8, 24), "moon_lords":e(2.1, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"killer_queen":{"money":e(7.8, 13), "honey":e(7.8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":5 * 86400},
					"M_DS_0":{"money":e(1.3, 10), "stone":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000, "time":2 * 86400},
					"M_DS_1":{"money":e(3.8, 11), "stone":e(2.7, 10), "silicon":e(1.5, 7), "copper":e(1.2, 7), "iron":e(8, 7), "aluminium":e(2.2, 7), "titanium":e(2.1, 6), "time":5 * 86400},
					"M_DS_2":{"money":e(1.5, 13), "stone":e(9.6, 11), "silicon":e(5.3, 8), "copper":e(4.0, 8), "iron":e(3.2, 9), "aluminium":e(8.7, 8), "titanium":e(8.8, 7), "time":8 * 86400},
					"M_DS_3":{"money":e(6.4, 14), "stone":e(3.5, 13), "silicon":e(2.5, 10), "copper":e(1.5, 10), "iron":e(1.4, 11), "aluminium":e(3, 10), "titanium":e(3, 9), "time":12 * 86400},
					"M_DS_4":{"money":e(2.5, 16), "stone":e(1.1, 15), "silicon":e(8.8, 11), "copper":e(5.6, 11), "iron":e(5.5, 12), "aluminium":e(1, 12), "titanium":e(9.6, 10), "time":16 * 86400},
					"M_SE_0":{"money":700000, "stone":50000, "energy":10000, "copper":800, "iron":1000, "aluminium":300, "time":2*3600},
					"M_SE_1":{"money":10000000, "stone":500000, "energy":45000, "copper":6000, "iron":10000, "aluminium":3000, "time":12 * 3600},
					"M_MME_0":{"money":e(2, 7), "stone":e(1, 6), "copper":1500, "iron":12000, "aluminium":5000, "titanium":300, "time":4 * 3600},
					"M_MME_1":{"money":e(6.5, 8), "stone":e(5, 7), "copper":70000, "iron":650000, "aluminium":200000, "titanium":12000, "time":48 * 3600},
					"M_MME_2":{"money":e(2.4, 10), "stone":e(2, 9), "copper":e(2.5, 6), "iron":e(2.5, 7), "aluminium":e(7.5, 6), "titanium":500000, "time":96 * 3600},
					"M_MME_3":{"money":e(9.5, 11), "stone":e(7, 10), "copper":e(8, 7), "iron":e(1, 9), "aluminium":e(3, 8), "titanium":e(1.5, 7), "time":150 * 3600},
					"M_CBS_0":{"money":e(1.0, 11), "stone":e(6, 8), "silicon":1200000, "copper":750000, "iron":1400000, "platinum":90000, "time":2 * 86400},
					"M_CBS_1":{"money":e(1.0, 11)*40, "stone":e(6, 8)*30, "silicon":1200000*40, "copper":750000*40, "iron":1400000*30, "platinum":90000*50, "time":5 * 86400},
					"M_CBS_2":{"money":e(1.0, 11)*40*40, "stone":e(6, 8)*30*30, "silicon":1200000*40*30, "copper":750000*40*30, "iron":1400000*30*30, "platinum":90000*50*50, "time":8 * 86400},
					"M_CBS_3":{"money":e(1.0, 11)*40*40*40, "stone":e(6, 8)*30*30*30, "silicon":1200000*40*30*30, "copper":750000*40*30*30, "iron":1400000*30*30*30, "platinum":90000*50*50*50, "time":12 * 86400},
					"M_MB":{"money":e(5.5, 17), "stone":e(1, 13), "copper":e(3, 11), "aluminium":e(2, 12), "nanocrystal":e(8, 11), "quillite":e(1.5, 11), "time":15 * 86400},
					"M_PK_0":{"money":e(2, 15), "stone":e(4, 14), "iron":e(1, 11), "aluminium":e(1.75, 10), "time":5 * 86400},
					"M_PK_1":{"money":e(9.5, 16), "stone":e(4, 16), "iron":e(8.5, 12), "aluminium":e(8, 12), "time":8 * 86400},
					"M_PK_2":{"money":e(6.5, 19), "stone":e(8.75, 20), "iron":e(2.25, 16), "aluminium":e(1.5, 15), "time":16 * 86400},
}

var MS_output = {	"M_DS_0":e(1, 8),
					"M_DS_1":e(3.8, 9),
					"M_DS_2":e(1.5, 11),
					"M_DS_3":e(5.8, 12),
					"M_DS_4":e(2.2, 14),
					"M_DS_5":e(2.2, 14),
					"M_MME_0":4800,
					"M_MME_1":254000,
					"M_MME_2":e(8.0, 7),
					"M_MME_3":e(3.0, 9),
					"M_MB":e(1.5, 12),
}

var MUs = {	"MV":{"base_cost":100, "pw":1.9},
			"MSMB":{"base_cost":100, "pw":1.6},
			"IS":{"base_cost":500, "pw":1.9},
			"STMB":{"base_cost":600, "pw":1.6},
			"SHSR":{"base_cost":2000, "pw":1.9},
			"CHR":{"base_cost":2000, "pw":1.7},
}
var money_icon = preload("res://Graphics/Icons/money.png")
var minerals_icon = preload("res://Graphics/Icons/minerals.png")
var energy_icon = preload("res://Graphics/Icons/energy.png")
var time_icon = preload("res://Graphics/Icons/Time.png")
var stone_icon = preload("res://Graphics/Icons/stone.png")
var SP_icon = preload("res://Graphics/Icons/SP.png")
var glass_icon = preload("res://Graphics/Materials/glass.png")
var cellulose_icon = preload("res://Graphics/Materials/cellulose.png")
var sand_icon = preload("res://Graphics/Materials/sand.png")
var coal_icon = preload("res://Graphics/Materials/coal.png")
var MM_icon = preload("res://Graphics/Icons/MM.png")
var atom_icon = preload("res://Graphics/Science/ATM.png")
var particle_icon = preload("res://Graphics/Science/SAP.png")
var proton_icon = preload("res://Graphics/Particles/proton.png")
var neutron_icon = preload("res://Graphics/Particles/neutron.png")
var electron_icon = preload("res://Graphics/Particles/electron.png")

var desc_icons = {	"ME":[[minerals_icon]],
					"PP":[[energy_icon]],
					"RL":[[SP_icon]],
					"B":[[energy_icon]],
					"MS":[[minerals_icon]],
					"SC":[[stone_icon], [stone_icon], []],
					"GF":[[glass_icon], [sand_icon], []],
					"SE":[[energy_icon], [coal_icon], []],
					"SP":[[energy_icon]],
					"PC":[[proton_icon]],
					"NC":[[neutron_icon]],
					"NSF":[[neutron_icon]],
					"EC":[[electron_icon]],
					"ESF":[[electron_icon]],
					"CBD":[[], [], []]
}

var rsrc_icons = {	"ME":minerals_icon,
					"PP":energy_icon,
					"RL":SP_icon,
					"SC":stone_icon,
					"GF":glass_icon,
					"SE":energy_icon,
					"MM":stone_icon,
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
var univ_prop_weights:Dictionary = {
	"speed_of_light":25,
	"planck":30,
	"boltzmann":30,
	"gravitational":40,
	"charge":40,
	"dark_energy":40,
	"age":15,
	"difficulty":10,
	"time_speed":50,
	"antimatter":100,
	}

func reload():
	path_1.ME.desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.AE.desc = tr("EXTRACTS_X") % ["%s mol/" + tr("S_SECOND")]
	path_1.PP.desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RL.desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1.RCC.desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1.SY.desc = tr("MULT_FIGHTER_STAT_BY") % ["%s"]
	path_1.MS.desc = tr("STORES_X") % [" @i %s"]
	path_1.B.desc = tr("STORES_X") % [" @i %s"]
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
	path_2.SC.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.GF.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.SE.desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2.GH.desc = tr("X_PLANT_PRODUCE")
	path_3.SC.desc = tr("OUTPUT_MULTIPLIER")
	path_3.GF.desc = tr("OUTPUT_MULTIPLIER")
	path_3.SE.desc = tr("OUTPUT_MULTIPLIER")
	path_1.CBD.desc = tr("CBD_PATH_1")
	path_2.CBD.desc = tr("CBD_PATH_2")
	path_3.CBD.desc = tr("CBD_PATH_3")
	path_2.AMN.desc = tr("DIVIDES_ENERGY_COSTS_BY")
	path_2.SPR.desc = tr("DIVIDES_ENERGY_COSTS_BY")

#Science for unlocking game features
var science_unlocks = {	
						#Agriculture sciences
						"SA":{"cost":500, "parents":[]},
						"PF":{"cost":90000, "parents":["SA"]},
						
						#Auto-sell minerals
						"ASM":{"cost":100, "parents":[]},
						"ASM2":{"cost":20000, "parents":["ASM"]},
						
						#Auto mining
						"AM":{"cost":10000, "parents":[]},
						
						#Improved stone crusher
						"ISC":{"cost":250, "parents":[]},
						
						#Compact items
						"CI":{"cost":4800, "parents":[]},
						"CI2":{"cost":4.8e6, "parents":["CI"]},
						"CI3":{"cost":4.8e9, "parents":["CI2"]},
						
						#Atom manipulation
						"ATM":{"cost":200000, "parents":[]},
						"AMM":{"cost":1e13, "parents":["ATM"]},
						"SAP":{"cost":12500000, "parents":["ATM"]},
						
						#Rover sciences
						"RC":{"cost":5, "parents":[]},
						"OL":{"cost":1000, "parents":["RC"]},
						"YL":{"cost":12000, "parents":["OL"]},
						"GL":{"cost":70000, "parents":["YL"]},
						"BL":{"cost":350000, "parents":["GL"]},
						"PL":{"cost":2400000, "parents":["BL"]},
						"UVL":{"cost":2.8e7, "parents":["PL"]},
						"XRL":{"cost":4.05e8, "parents":["UVL"]},
						"GRL":{"cost":6.5e9, "parents":["XRL"]},
						"UGRL":{"cost":1e12, "parents":["GRL"]},
						
						"RMK2":{"cost":5e6, "parents":["RC"]},
						"RMK3":{"cost":5e10, "parents":["RMK2"]},
						
						#Ship sciences
						"SCT":{"cost":350, "parents":["RC"]},
						"CD":{"cost":2400, "parents":["SCT"]},
						"FTL":{"cost":128000, "parents":["SCT"]},
						"IGD":{"cost":9.5e7, "parents":["FTL"]},
						"FG":{"cost":3.45e9, "parents":["IGD"]},
						"FG2":{"cost":1.4e19, "parents":["FG"]},
						"ID":{"cost":4.5e6, "parents":["CD", "ATM"]},
						"PD":{"cost":1.2e12, "parents":["ID"]},
						
						"UP1":{"cost":5e7, "parents":["SCT"]},
						"UP2":{"cost":5e10, "parents":["UP1"]},
						"UP3":{"cost":5e13, "parents":["UP2"]},
						"UP4":{"cost":5e16, "parents":["UP3"]},
						
						#Megastructure sciences
						"MAE":{"cost":100000, "parents":["SCT"]},
						"TF":{"cost":5.6e8, "parents":["MAE"]},
						#Dyson sphere
						"DS1":{"cost":1.2e11, "parents":["MAE"]},
						"DS2":{"cost":4.8e12, "parents":["DS1"]},
						"DS3":{"cost":2.1e14, "parents":["DS2"]},
						"DS4":{"cost":8.0e15, "parents":["DS3"]},
						#Matrioshka brain
						"MB":{"cost":2.6e16, "parents":["DS4"]},
						#Space elevator
						"SE1":{"cost":700000, "parents":["MAE"]},
						
						#Mega mineral extractor
						"MME1":{"cost":1.7e9, "parents":["MAE"]},
						"MME2":{"cost":6.0e10, "parents":["MME1"]},
						"MME3":{"cost":2.4e12, "parents":["MME2"]},
						
						#CBS
						"CBS1":{"cost":8.5e11, "parents":["MAE"]},
						"CBS2":{"cost":8.5e11*30, "parents":["CBS1"]},
						"CBS3":{"cost":8.5e11*30*30, "parents":["CBS2"]},
						
						#Planetkiller
						"PK1":{"cost":5.25e14, "parents":["MAE"]},
						"PK2":{"cost":3.4e16, "parents":["PK1"]},
						
						#Gigastructures
						"GS":{"cost":1e19, "parents":["MB"]},
						
						#Triangulum probe
						"TPCC":{"cost":1e23, "parents":["GS"]},
}

var infinite_research_sciences = {	"MEE":{"cost":250, "pw":6.8},
									"EPE":{"cost":400, "pw":6.8},
									"RLE":{"cost":1250, "pw":7.2},
									"STE":{"cost":500, "pw":7.0},
									"MMS":{"cost":150, "pw":6.0},
									"PME":{"cost":1e7, "pw":6.8},
}

var rover_armor = {	"stone_armor":{"HP":2, "defense":1, "costs":{"stone":200}},
					"lead_armor":{"HP":5, "defense":2, "costs":{"lead":40}},
					"copper_armor":{"HP":10, "defense":3, "costs":{"copper":50}},
					"iron_armor":{"HP":15, "defense":4, "costs":{"iron":65}},
					"aluminium_armor":{"HP":20, "defense":5, "costs":{"aluminium":90}},
					"silver_armor":{"HP":30, "defense":7, "costs":{"silver":130}},
					"gold_armor":{"HP":50, "defense":10, "costs":{"gold":190}},
					"titanium_armor":{"HP":80, "defense":15, "costs":{"titanium":240}},
					"gemstone_armor":{"HP":85, "defense":22, "costs":{"amethyst":70, "quartz":70, "topaz":70, "sapphire":70, "emerald":70, "ruby":70}},
					"platinum_armor":{"HP":130, "defense":40, "costs":{"platinum":600}},
					"diamond_armor":{"HP":180, "defense":70, "costs":{"diamond":750}},
					"nanocrystal_armor":{"HP":240, "defense":110, "costs":{"nanocrystal":1600}},
					"mythril_armor":{"HP":400, "defense":250, "costs":{"mythril":3800}},
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
var rover_CC = {	"stone_CC":{"capacity":3000, "costs":{"stone":250}},
					"lead_CC":{"capacity":5000, "costs":{"lead":70}},
					"copper_CC":{"capacity":7000, "costs":{"copper":90}},
					"iron_CC":{"capacity":10000, "costs":{"iron":110}},
					"aluminium_CC":{"capacity":14000, "costs":{"aluminium":130}},
					"silver_CC":{"capacity":20000, "costs":{"silver":150}},
					"gold_CC":{"capacity":30000, "costs":{"gold":200}},
					"titanium_CC":{"capacity":62000, "costs":{"titanium":250}},
					"gemstone_CC":{"capacity":75000, "costs":{"amethyst":75, "quartz":75, "topaz":75, "sapphire":75, "emerald":75, "ruby":75}},
					"platinum_CC":{"capacity":90000, "costs":{"platinum":700}},
					"diamond_CC":{"capacity":165000, "costs":{"diamond":1200}},
					"nanocrystal_CC":{"capacity":450000, "costs":{"nanocrystal":2200}},
					"mythril_CC":{"capacity":1250000, "costs":{"mythril":5000}},
}
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":1000, "silicon":10, "time":10}},
						"orange_laser":{"damage":8, "cooldown":0.19, "costs":{"money":17000, "silicon":12, "time":60}},
						"yellow_laser":{"damage":14, "cooldown":0.18, "costs":{"money":190000, "silicon":15, "time":360}},
						"green_laser":{"damage":22, "cooldown":0.17, "costs":{"money":950000, "silicon":20, "time":1500}},
						"blue_laser":{"damage":40, "cooldown":0.16, "costs":{"money":e(5.2, 6), "silicon":50, "quartz":25, "time":4500}},
						"purple_laser":{"damage":75, "cooldown":0.15, "costs":{"money":e(3.7, 7), "silicon":100, "quartz":50, "time":9000}},
						"UV_laser":{"damage":140, "cooldown":0.14, "costs":{"money":e(3.1, 8), "silicon":200, "quartz":100, "time":18000}},
						"xray_laser":{"damage":270, "cooldown":0.13, "costs":{"money":e(9.8, 9), "silicon":500, "quartz":200, "time":30000}},
						"gammaray_laser":{"damage":525, "cooldown":0.12, "costs":{"money":e(2.5, 11), "silicon":1000, "quartz":500, "time":65000}},
						"ultragammaray_laser":{"damage":900, "cooldown":0.1, "costs":{"money":e(1.5, 13), "silicon":2500, "quartz":1000, "time":100000}},
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
var bullet_data = [	{"damage":3.5, "accuracy":1.0},
					{"damage":5, "accuracy":1.05},
					{"damage":9, "accuracy":1.1},
					{"damage":19, "accuracy":1.3},
					{"damage":44, "accuracy":1.7},]
var laser_data = [	{"damage":2.5, "accuracy":2.2},
					{"damage":3.5, "accuracy":2.4},
					{"damage":6.5, "accuracy":2.7},
					{"damage":13, "accuracy":3.3},
					{"damage":29, "accuracy":5.5},]
var bomb_data = [	{"damage":6, "accuracy":0.7},
					{"damage":8, "accuracy":0.72},
					{"damage":15, "accuracy":0.75},
					{"damage":34, "accuracy":0.8},
					{"damage":90, "accuracy":1.0},]
var light_data = [	{"damage":1.5, "accuracy":1.3},
					{"damage":2.5, "accuracy":1.35},
					{"damage":4.0, "accuracy":1.45},
					{"damage":8.0, "accuracy":1.7},
					{"damage":17.5, "accuracy":2.8},]

#the numbers are the elements' abundance relative to hydrogen
var elements = {"NH3":0.05, "CO2":0.01, "H":1.0, "He":0.325, "CH4":0.2, "O":0.014, "H2O":0.15, "Ne":0.001813, "Xe":0.0000022}

var molar_mass = {	"H":1.008,
						"He":4.0026,
						"C":12.011,
						"N":14.001,
						"O":15.999,
						"F":18.998,
						"Ne":20.18,
						"Na":22.99,
						"Mg":24.305,
						"Al":26.982,
						"Si":28.085,
						"P":30.974,
						"S":32.06,
						"K":39.098,
						"Ca":40.078,
						"Ti":47.867,
						"Cr":51.996,
						"Mn":54.938,
						"Fe":55.845,
						"Co":58.933,
						"Ni":58.693,
						"Xe":131.29,
						"Ta":180.95,
						"W":183.84,
						"Os":190.23,
						"Ir":192.22,
						"U":238.03,
						"Np":237,
						"Pu":244,
	}

var cave_modifiers:Dictionary = {#tier 1 modifiers can apply to any cave (outside starting system), tier 2 modifiers cannot be applied to caves in starting galaxy
	"enemy_attack_rate":{"double_treasure_at":1.2, "tier":1, "max":5},
	"enemy_number":{"double_treasure_at":1.3, "tier":1},
	"enemy_HP":{"double_treasure_at":1.5, "tier":1},
	"chest_number":{"double_treasure_at":0.8, "no_treasure_mult":true, "tier":1},
	"darkness":{"double_treasure_at":2.0, "tier":1, "max":3},
	"enemy_size":{"double_treasure_at":0.6, "tier":2, "min":0.3, "one_direction":1},
	"rover_size":{"double_treasure_at":0.9, "tier":2},
	"minimap_disabled":{"treasure_if_true":3.0, "tier":2},
}
var lake_colors = {
	"H2O":	{	"s":Color(0.48, 0.76, 1.0, 0.6),
				"l":Color(0.34, 0.84, 1.0, 1.0),
				"sc":Color(0.68, 0.86, 1.0, 0.4)},
	"CO2":{ 	"s":Color(0.66, 0.66, 0.66, 0.7),
				"l":Color(0.66, 0.66, 0.66, 1.0),
				"sc":Color(0.66, 0.66, 0.66, 0.4)},
	"CH4":{		"s":Color(0.63, 0.39, 0.13, 0.7),
				"l":Color(0.63, 0.39, 0.13, 1.0),
				"sc":Color(0.63, 0.39, 0.13, 0.4)},
	"H":{		"s":Color(0.85, 1, 0.85, 0.6),
				"l":Color(0.7, 1, 0.7, 1.0),
				"sc":Color(0.85, 1, 0.85, 0.3)},
	"He":{		"s":Color(0.87, 0.66, 1.0, 0.7),
				"l":Color(0.78, 0.43, 1.0, 1.0),
				"sc":Color(0.87, 0.66, 1.0, 0.4)},
	"Ne":{		"s":Color(0.2, 1.0, 0.6, 0.8),
				"l":Color(0.1, 1.0, 0.3, 1.0),
				"sc":Color(0.2, 1.0, 0.6, 0.5)},
	"Xe":{		"s":Color(0.5, 0.25, 1.0, 0.7),
				"l":Color(0.5, 0.25, 1.0, 1.0),
				"sc":Color(0.5, 0.25, 1.0, 0.4)},
	"NH3":{		"s":Color(0.5, 0.45, 1.0, 0.6),
				"l":Color(0.7, 0.65, 1.0, 1.0),
				"sc":Color(0.5, 0.45, 1.0, 0.4)},
	"O":{		"s":Color(0.8, 0.8, 1, 0.7),
				"l":Color(0.8, 0.8, 1, 1.0),
				"sc":Color(0.8, 0.8, 1, 0.4)},
}
var lake_bonus_values = {
	"H2O":{"s":1.5, "l":2.5, "sc":3, "operator":"x"},
	"CH4":{"s":0.4, "l":0.15, "sc":0.3, "operator":"÷"},
	"CO2":{"s":120, "l":300, "sc":180, "operator":"x"},
	"H":{"s":1, "l":2, "sc":1, "operator":"+"},
	"He":{"s":250, "l":600, "sc":200, "operator":"x"},
	"Ne":{"s":0.4, "l":1.0, "sc":0.6, "operator":"x"},
	"Xe":{"s":1, "l":2, "sc":1, "operator":"+"},
	"O":{"s":2, "l":4, "sc":3, "operator":"x"},
	"NH3":{"s":0.4, "l":0.15, "sc":0.3, "operator":"÷"},
}

var default_help = {
				"materials":true,
				"close_btn1":true,
				"close_btn2":true,
				"mining":true,
				"STM":true,
				"battle":true,
				"battle2":true,
				"battle3":true,
				"plant_something_here":true,
				"boulder_desc":true,
				"aurora_desc":true,
				"mineral_replicator_desc":true,
				"substation_desc":true,
				"observatory_desc":true,
				"nuclear_fusion_reactor_desc":true,
				"mining_outpost_desc":true,
				"cellulose_synthesizer_desc":true,
				"aurora_generator_desc":true,
				"spaceport_desc":true,
				"crater_desc":true,
				"autosave_light_desc":true,
				"tile_shortcuts":true,
				"inventory_shortcuts":true,
				"hotbar_shortcuts":true,
				"rover_shortcuts":true,
				"mass_buy":true,
				"rover_inventory_shortcuts":true,
				"planet_details":true,
				"mass_build":true,
				"abandoned_ship":true,
				"science_tree":true,
				"sprint_mode":true,
				"cave_controls":true,
				"active_wormhole":true,
				"inactive_wormhole":true,
				"cave_diff_info":true,
				"downgrade":true,
				"artificial_volcano":true,
				"flash_send_probe_btn":true,
				"hide_dimension_stuff":true,
		}

var unique_bldg_icons = {
	"spaceport":[energy_icon, energy_icon],
	"mineral_replicator":[minerals_icon],
	"substation":[energy_icon, energy_icon, energy_icon],
	"aurora_generator":[],
	"nuclear_fusion_reactor":[energy_icon],
	"mining_outpost":[],
	"observatory":[SP_icon],
	"cellulose_synthesizer":[cellulose_icon],
}

var unique_bldg_repair_cost_multipliers = {
	"spaceport":1.2,
	"mineral_replicator":2.4,
	"substation":2.5,
	"aurora_generator":3.0,
	"nuclear_fusion_reactor":8.5,
	"mining_outpost":1.0,
	"observatory":2.8,
	"cellulose_synthesizer":1.5,
}

var MS_num_stages:Dictionary = {"M_DS":4, "M_MME":3, "M_CBS":3, "M_PK":2, "M_SE":1, "M_MPCC":0, "M_MB":0}

var tier_colors = [Color.WHITE, Color(0, 0.9, 0.0), Color(0.2, 0.2, 1.0), Color(1.0, 0.2, 1.0), Color(1.0, 0.5, 0.0), Color(1.0, 1.0, 0.2), Color.RED]
