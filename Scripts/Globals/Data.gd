extends Node

enum ProjType {STANDARD, LASER, BUBBLE, PURPLE}#For caves

var path_1 = {	Building.MINERAL_EXTRACTOR:			{"value":0.36, "pw":1.15, "time_based":true, "metal_costs":{"lead":20, "copper":35, "iron":50, "aluminium":70, "silver":100, "gold":150, "platinum":250}},
				Building.POWER_PLANT:				{"value":0.6, "pw":1.15, "time_based":true, "metal_costs":{"lead":20, "copper":30, "iron":40, "aluminium":40, "silver":40, "gold":40}},
				Building.RESEARCH_LAB:				{"value":0.06, "pw":1.15, "time_based":true, "metal_costs":{"lead":100, "copper":150, "iron":150, "aluminium":150, "silver":150, "gold":150, "platinum":150}},
				Building.BATTERY:					{"value":12000, "pw":1.17, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				Building.MINERAL_SILO:				{"value":100, "pw":1.15, "is_value_integer":true, "metal_costs":{"lead":35, "copper":25, "iron":35, "aluminium":40, "silver":40, "gold":40}},
				Building.ROVER_CONSTRUCTION_CENTER:	{"value":1.0, "pw":1.07, "metal_costs":{"lead":1500, "copper":3500, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
				Building.STONE_CRUSHER:				{"value":50.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				Building.GLASS_FACTORY:				{"value":1, "pw":1.15, "time_based":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				Building.STEAM_ENGINE:				{"value":40.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				Building.BORING_MACHINE:			{"value":0.02, "pw":1.1, "time_based":true, "metal_costs":{"lead":500, "copper":700, "iron":900, "aluminium":1100, "silver":1300, "gold":1500}},
				Building.GREENHOUSE:				{"value":1.0, "pw":1.11, "metal_costs":{"lead":500, "copper":500, "iron":600, "aluminium":600, "silver":700, "gold":700}},
				Building.SOLAR_PANEL:				{"value":2.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":70, "copper":70, "iron":70, "aluminium":70, "silver":70, "gold":70}},
				Building.ATMOSPHERE_EXTRACTOR:		{"value":0.2, "pw":1.15, "time_based":true, "metal_costs":{"lead":200, "copper":200, "iron":200, "aluminium":200, "silver":200, "gold":200}},
				Building.ATOM_MANIPULATOR:			{"value":1.0, "pw":1.16, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				Building.SUBATOMIC_PARTICLE_REACTOR:{"value":1.0, "pw":1.16, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				Building.SHIPYARD:					{"value":1.0, "pw":1.16, "metal_costs":{"lead":640000, "copper":640000, "iron":640000, "aluminium":960000, "silver":960000, "gold":1280000}},
				Building.CENTRAL_BUSINESS_DISTRICT:	{"value":1.111111, "pw":1.03, "cost_mult":1.5, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
#				"PC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
#				"NC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
#				"EC":{"value":1000.0, "pw":1.15, "time_based":true, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
#				"NSF":{"value":50000.0, "pw":1.15, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
#				"ESF":{"value":50000.0, "pw":1.15, "metal_costs":{"lead":2000, "copper":3000, "iron":5000, "aluminium":8000, "silver":13000, "gold":21000, "platinum":34000}},
}
var path_2 = {	Building.STONE_CRUSHER:				{"value":4000, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":300, "copper":300, "iron":300, "aluminium":300, "silver":300, "gold":300}},
				Building.GLASS_FACTORY:				{"value":600, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				Building.STEAM_ENGINE:				{"value":100, "pw":1.16, "is_value_integer":true, "metal_costs":{"lead":350, "copper":350, "iron":350, "aluminium":350, "silver":350, "gold":350}},
				Building.GREENHOUSE:				{"value":1.0, "pw":1.07, "metal_costs":{"lead":1000, "copper":1000, "iron":1200, "aluminium":1200, "silver":1400, "gold":1400}},
				Building.ATOM_MANIPULATOR:			{"value":1.0, "pw":1.05, "metal_costs":{"lead":50000, "copper":50000, "iron":50000, "aluminium":50000, "silver":50000, "gold":50000}},
				Building.SUBATOMIC_PARTICLE_REACTOR:{"value":1.0, "pw":1.05, "metal_costs":{"lead":270000, "copper":270000, "iron":270000, "aluminium":270000, "silver":270000, "gold":270000}},
				Building.CENTRAL_BUSINESS_DISTRICT:	{"value":1.1, "step":0.02, "metal_costs":{"lead":2000, "copper":4000, "iron":8000, "aluminium":16000, "silver":32000, "gold":64000, "platinum":128000}},
}
var path_3 = {	Building.STONE_CRUSHER:				{"value":1.0, "pw":1.01, "cap":70, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				Building.GLASS_FACTORY:				{"value":1.0, "pw":1.01, "cap":70, "metal_costs":{"lead":600, "copper":1800, "iron":5400, "aluminium":16200, "silver":48600, "gold":145800}},
				Building.STEAM_ENGINE:				{"value":1.0, "pw":1.04, "metal_costs":{"lead":700, "copper":1400, "iron":2800, "aluminium":5600, "silver":11200, "gold":22400}},
				Building.CENTRAL_BUSINESS_DISTRICT:	{"value":3, "step":2, "cost_mult":12, "cost_pw":2.7, "is_value_integer":true},
}

var costs = {	Building.MINERAL_EXTRACTOR:			{"money":100, "energy":40},
				Building.POWER_PLANT:				{"money":80},
				Building.RESEARCH_LAB:				{"money":2000, "energy":600},
				Building.BATTERY:					{"money":400, "energy":100},
				Building.MINERAL_SILO:				{"money":500, "energy":60},
				Building.ROVER_CONSTRUCTION_CENTER:	{"money":5000, "energy":400},
				Building.STONE_CRUSHER:				{"money":900, "energy":150},
				Building.GLASS_FACTORY:				{"money":1500, "energy":1000},
				Building.STEAM_ENGINE:				{"money":1500, "energy":500},
				Building.BORING_MACHINE:			{"money":13000, "energy":7000},
				Building.GREENHOUSE:				{"money":10000, "energy":1500, "glass":50, "soil":100},
				Building.SOLAR_PANEL:				{"money":4000},
				Building.ATMOSPHERE_EXTRACTOR:		{"money":41500, "energy":15000},
				Building.ATOM_MANIPULATOR:			{"money":580000, "energy":8200},
				Building.SUBATOMIC_PARTICLE_REACTOR:{"money":3500000, "energy":61300},
				Building.SHIPYARD:					{"money":e(5, 8), "energy":900000},
				Building.PROBE_CONSTRUCTION_CENTER:	{"money":2.5e12, "energy":7.8e10},
				Building.CENTRAL_BUSINESS_DISTRICT:	{"money":7000, "energy":1000, },
				"rover":{"money":2000, "energy":400},
}

func e(n, e):
	return n * pow(10, e)

var MS_costs = {	"doom_ball":{"money":e(5.4, 12), "stone":e(5.4, 7), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000},
					"notachicken_star":{"money":e(4.3, 7), "chickens":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000},
					"moon_but_not":{"money":e(8, 24), "moon_lords":e(2.1, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000},
					"killer_queen":{"money":e(7.8, 13), "honey":e(7.8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000},
					"DS_0":{"money":e(1.3, 10), "stone":e(8, 8), "silicon":400000, "copper":250000, "iron":1600000, "aluminium":500000, "titanium":50000},
					"DS_1":{"money":e(3.8, 11), "stone":e(2.7, 10), "silicon":e(1.5, 7), "copper":e(1.2, 7), "iron":e(8, 7), "aluminium":e(2.2, 7), "titanium":e(2.1, 6)},
					"DS_2":{"money":e(1.5, 13), "stone":e(9.6, 11), "silicon":e(5.3, 8), "copper":e(4.0, 8), "iron":e(3.2, 9), "aluminium":e(8.7, 8), "titanium":e(8.8, 7)},
					"DS_3":{"money":e(6.4, 14), "stone":e(3.5, 13), "silicon":e(2.5, 10), "copper":e(1.5, 10), "iron":e(1.4, 11), "aluminium":e(3, 10), "titanium":e(3, 9)},
					"DS_4":{"money":e(2.5, 16), "stone":e(1.1, 15), "silicon":e(8.8, 11), "copper":e(5.6, 11), "iron":e(5.5, 12), "aluminium":e(1, 12), "titanium":e(9.6, 10)},
					"SE_0":{"money":700000, "stone":50000, "energy":10000, "copper":800, "iron":1000, "aluminium":300},
					"SE_1":{"money":10000000, "stone":500000, "energy":45000, "copper":6000, "iron":10000, "aluminium":3000},
					"MME_0":{"money":e(2, 7), "stone":e(1, 6), "copper":1500, "iron":12000, "aluminium":5000, "titanium":300},
					"MME_1":{"money":e(6.5, 8), "stone":e(5, 7), "copper":70000, "iron":650000, "aluminium":200000, "titanium":12000},
					"MME_2":{"money":e(2.4, 10), "stone":e(2, 9), "copper":e(2.5, 6), "iron":e(2.5, 7), "aluminium":e(7.5, 6), "titanium":500000},
					"MME_3":{"money":e(9.5, 11), "stone":e(7, 10), "copper":e(8, 7), "iron":e(1, 9), "aluminium":e(3, 8), "titanium":e(1.5, 7)},
					"CBS_0":{"money":e(1.0, 11), "stone":e(6, 8), "silicon":1200000, "copper":750000, "iron":1400000, "platinum":90000},
					"CBS_1":{"money":e(1.0, 11)*40, "stone":e(6, 8)*30, "silicon":1200000*40, "copper":750000*40, "iron":1400000*30, "platinum":90000*50},
					"CBS_2":{"money":e(1.0, 11)*40*40, "stone":e(6, 8)*30*30, "silicon":1200000*40*30, "copper":750000*40*30, "iron":1400000*30*30, "platinum":90000*50*50},
					"CBS_3":{"money":e(1.0, 11)*40*40*40, "stone":e(6, 8)*30*30*30, "silicon":1200000*40*30*30, "copper":750000*40*30*30, "iron":1400000*30*30*30, "platinum":90000*50*50*50},
					"MB":{"money":e(5.5, 17), "stone":e(1, 13), "copper":e(3, 11), "aluminium":e(2, 12), "nanocrystal":e(8, 11), "quillite":e(1.5, 11)},
					"PK_0":{"money":e(2, 15), "stone":e(4, 14), "iron":e(1, 11), "aluminium":e(1.75, 10)},
					"PK_1":{"money":e(9.5, 16), "stone":e(4, 16), "iron":e(8.5, 12), "aluminium":e(8, 12)},
					"PK_2":{"money":e(6.5, 19), "stone":e(8.75, 20), "iron":e(2.25, 16), "aluminium":e(1.5, 15)},
}

var MS_output = {	"DS_0":e(1, 8),
					"DS_1":e(3.8, 9),
					"DS_2":e(1.5, 11),
					"DS_3":e(5.8, 12),
					"DS_4":e(2.2, 14),
					"DS_5":e(2.2, 14),
					"MME_0":4800,
					"MME_1":254000,
					"MME_2":e(8.0, 7),
					"MME_3":e(3.0, 9),
					"MB":e(1.5, 12),
}

var MUs = {	"MV":{"base_cost":100, "pw":1.9},
			"MSMB":{"base_cost":100, "pw":1.6},
			"IS":{"base_cost":500, "pw":1.9},
			"STMB":{"base_cost":600, "pw":1.6},
			"SHSR":{"base_cost":2000, "pw":1.9},
			"CHR":{"base_cost":2000, "pw":1.7},
}

var ambient_music = [
	preload("res://Audio/ambient1.ogg"),
	preload("res://Audio/ambient2.ogg"),
	preload("res://Audio/ambient3.ogg"),
]
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
var subatomic_particles_icon = preload("res://Graphics/Particles/subatomic_particles.png")

var HP_icon = preload("res://Graphics/Icons/HP.png")
var attack_icon = preload("res://Graphics/Icons/attack.png")
var defense_icon = preload("res://Graphics/Icons/defense.png")
var accuracy_icon = preload("res://Graphics/Icons/accuracy.png")
var agility_icon = preload("res://Graphics/Icons/agility.png")

var desc_icons = {	Building.MINERAL_EXTRACTOR:[[minerals_icon]],
					Building.POWER_PLANT:[[energy_icon]],
					Building.RESEARCH_LAB:[[SP_icon]],
					Building.BATTERY:[[energy_icon]],
					Building.MINERAL_SILO:[[minerals_icon]],
					Building.STONE_CRUSHER:[[stone_icon], [stone_icon], []],
					Building.GLASS_FACTORY:[[glass_icon], [sand_icon], []],
					Building.STEAM_ENGINE:[[energy_icon], [coal_icon], []],
					Building.SOLAR_PANEL:[[energy_icon]],
#					"PC":[[proton_icon]],
#					"NC":[[neutron_icon]],
#					"NSF":[[neutron_icon]],
#					"EC":[[electron_icon]],
#					"ESF":[[electron_icon]],
					Building.CENTRAL_BUSINESS_DISTRICT:[[], [], []]
}

var rsrc_icons = {	Building.MINERAL_EXTRACTOR:minerals_icon,
					Building.POWER_PLANT:energy_icon,
					Building.RESEARCH_LAB:SP_icon,
					Building.STONE_CRUSHER:stone_icon,
					Building.GLASS_FACTORY:glass_icon,
					Building.STEAM_ENGINE:energy_icon,
					Building.BORING_MACHINE:stone_icon,
					Building.SOLAR_PANEL:energy_icon,
					Building.ATMOSPHERE_EXTRACTOR:atom_icon,
					Building.ATOM_MANIPULATOR:atom_icon,
					Building.SUBATOMIC_PARTICLE_REACTOR:subatomic_particles_icon,
#					"PC":proton_icon,
#					"NC":neutron_icon,
#					"NSF":neutron_icon,
#					"EC":electron_icon,
#					"ESF":electron_icon,
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
			StarType.BROWN_DWARF:0,
			StarType.WHITE_DWARF:0,
			StarType.MAIN_SEQUENCE:1,
			StarType.GIANT:0,
			StarType.SUPERGIANT:0,
			StarType.HYPERGIANT:0,
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

var standard_large_number_notations = []

func reload():
	standard_large_number_notations = tr("STANDARD_LARGE_NUMBER_NOTATION").split(" < ")
	path_1[Building.MINERAL_EXTRACTOR].desc = tr("EXTRACTS_X") % ["@i %s/" + tr("S_SECOND")]
	path_1[Building.ATMOSPHERE_EXTRACTOR].desc = tr("EXTRACTS_X") % ["%s mol/" + tr("S_SECOND")]
	path_1[Building.POWER_PLANT].desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1[Building.RESEARCH_LAB].desc = tr("PRODUCES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1[Building.ROVER_CONSTRUCTION_CENTER].desc = tr("MULT_ROVER_STAT_BY") % ["%s"]
	path_1[Building.SHIPYARD].desc = tr("MULT_FIGHTER_STAT_BY") % ["%s"]
	path_1[Building.MINERAL_SILO].desc = tr("STORES_X") % [" @i %s"]
	path_1[Building.BATTERY].desc = tr("STORES_X") % [" @i %s"]
	path_1[Building.STONE_CRUSHER].desc = tr("CRUSHES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1[Building.GLASS_FACTORY].desc = tr("PRODUCES_X") % ["@i %s kg/" + tr("S_SECOND")]
	path_1[Building.STEAM_ENGINE].desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1[Building.BORING_MACHINE].desc = tr("X_M_PER_SECOND") % ["%s", tr("S_SECOND")]
	path_1[Building.GREENHOUSE].desc = tr("X_PLANT_GROWTH")
	path_1[Building.SOLAR_PANEL].desc = tr("GENERATES_X") % ["@i %s/" + tr("S_SECOND")]
	path_1[Building.ATOM_MANIPULATOR].desc = "%s: %%s" % [tr("BASE_SPEED")]
	path_1[Building.SUBATOMIC_PARTICLE_REACTOR].desc = "%s: %%s" % [tr("BASE_SPEED")]
#	path_1.PC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
#	path_1.NC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
#	path_1.EC.desc = tr("COLLECTS_X") % ["@i %s/" + tr("S_SECOND")]
#	path_1.NSF.desc = tr("STORES_X") % ["@i %s mol"]
#	path_1.ESF.desc = tr("STORES_X") % ["@i %s mol"]
	path_2[Building.STONE_CRUSHER].desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2[Building.GLASS_FACTORY].desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2[Building.STEAM_ENGINE].desc = tr("CAN_STORE_UP_TO") % [" @i %s kg"]
	path_2[Building.GREENHOUSE].desc = tr("X_PLANT_PRODUCE")
	path_3[Building.STONE_CRUSHER].desc = tr("OUTPUT_MULTIPLIER")
	path_3[Building.GLASS_FACTORY].desc = tr("OUTPUT_MULTIPLIER")
	path_3[Building.STEAM_ENGINE].desc = tr("OUTPUT_MULTIPLIER")
	path_1[Building.CENTRAL_BUSINESS_DISTRICT].desc = tr("CBD_PATH_1")
	path_2[Building.CENTRAL_BUSINESS_DISTRICT].desc = tr("CBD_PATH_2")
	path_3[Building.CENTRAL_BUSINESS_DISTRICT].desc = tr("CBD_PATH_3")
	path_2[Building.ATOM_MANIPULATOR].desc = tr("DIVIDES_ENERGY_COSTS_BY")
	path_2[Building.SUBATOMIC_PARTICLE_REACTOR].desc = tr("DIVIDES_ENERGY_COSTS_BY")

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
						
						#Improved spaceport
						"ISP":{"cost":50000, "parents":[]},
						
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
var rover_weapons = {	"red_laser":{"damage":5, "cooldown":0.2, "costs":{"money":1000, "silicon":10}},
						"orange_laser":{"damage":8, "cooldown":0.19, "costs":{"money":17000, "silicon":12}},
						"yellow_laser":{"damage":14, "cooldown":0.18, "costs":{"money":190000, "silicon":15}},
						"green_laser":{"damage":22, "cooldown":0.17, "costs":{"money":950000, "silicon":20}},
						"blue_laser":{"damage":40, "cooldown":0.16, "costs":{"money":e(5.2, 6), "silicon":50, "quartz":25}},
						"purple_laser":{"damage":75, "cooldown":0.15, "costs":{"money":e(3.7, 7), "silicon":100, "quartz":50}},
						"UV_laser":{"damage":140, "cooldown":0.14, "costs":{"money":e(3.1, 8), "silicon":200, "quartz":100}},
						"xray_laser":{"damage":270, "cooldown":0.13, "costs":{"money":e(9.8, 9), "silicon":500, "quartz":200}},
						"gammaray_laser":{"damage":525, "cooldown":0.12, "costs":{"money":e(2.5, 11), "silicon":1000, "quartz":500}},
						"ultragammaray_laser":{"damage":900, "cooldown":0.1, "costs":{"money":e(1.5, 13), "silicon":2500, "quartz":1000}},
}#														rnge: mining range
var rover_mining = {	"red_mining_laser":{"speed":1, "rnge":250, "costs":{"money":1000, "silicon":10}},
						"orange_mining_laser":{"speed":1.4, "rnge":260, "costs":{"money":17000, "silicon":12}},
						"yellow_mining_laser":{"speed":1.9, "rnge":270, "costs":{"money":190000, "silicon":15}},
						"green_mining_laser":{"speed":2.5, "rnge":285, "costs":{"money":950000, "silicon":20}},
						"blue_mining_laser":{"speed":3.3, "rnge":300, "costs":{"money":e(5.2, 6), "silicon":50, "quartz":25}},
						"purple_mining_laser":{"speed":4.3, "rnge":315, "costs":{"money":e(3.7, 7), "silicon":100, "quartz":50}},
						"UV_mining_laser":{"speed":6, "rnge":330, "costs":{"money":e(3.1, 8), "silicon":200, "quartz":100}},
						"xray_mining_laser":{"speed":9.1, "rnge":350, "costs":{"money":e(4.0, 9), "silicon":500, "quartz":200}},
						"gammaray_mining_laser":{"speed":12, "rnge":380, "costs":{"money":e(9.4, 10), "silicon":1000, "quartz":500}},
						"ultragammaray_mining_laser":{"speed":16, "rnge":500, "costs":{"money":e(1.0, 12), "silicon":2500, "quartz":1000}},
}
var battle_weapon_stats = {
	"bullet": {	"damage":3.5,
				"accuracy":1.0,
				"shots_fired":[2, 3, 6, 15],
				"mass":[1.0, 1.3, 1.8, 3.2],
				"knockback":[0.0, 10.0, 15.0, 24.0],
				"damage_multiplier":[1.0, 1.0, 1.4, 2.1],
				"crit_hit_mult":[1.0, 1.5, 2.3, 3.4],
				"deflects":[2, 2, 3, 4],
				"ignore_defense_buffs":[false, false, true, true],
				"status_effects":{
					Battle.StatusEffect.CORRODING:[0, 2, 3, 0],
					Battle.StatusEffect.RADIOACTIVE:[0, 0, 0, 3],
					Battle.StatusEffect.WET:[0, 2, 4, 0],
					Battle.StatusEffect.FROZEN:[0, 0, 0, 4],
				},
			},
	"laser": {	"damage":2.0,
				"accuracy":1.8,
				"status_effects":{
					Battle.StatusEffect.STUN:[[0.8, 1], [0.8, 1], [0.8, 2], [0.8, 2]],
				},
				"consecutive_fires":[1, 2, 2, 3],
			},
	"bomb": {	"damage":6.0,
				"accuracy":0.65,
				"AoE_radius":[100.0, 130.0, 180.0, 300.0],
				"mass":[4.0, 6.0, 9.0, 15.0],
				"knockback":[50.0, 60.0, 70.0, 100.0],
				"damage_multiplier":[1.0, 1.0, 1.5, 2.0],
				"status_effects":{
					Battle.StatusEffect.BURN:[1, 2, 2, 2],
					Battle.StatusEffect.STUN:[0, 0, 1, 1],
				},
			},
	"light": {	"damage":3.0,
				"accuracy":INF,
				"damage_multiplier":[1.0, 1.0, 1.4, 1.6]},
}

#the numbers are the elements' abundance relative to hydrogen
var elements = {
	"NH3":0.05,
	"CO2":0.01,
	"H":1.0,
	"He":0.325,
	"CH4":0.2,
	"O":0.014,
	"H2O":0.15,
	"Ne":0.001813,
	"Xe":0.0000022,
}

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
	"H2O":	{	"s":Color(0.71, 0.747, 0.78),
				"l":Color(0.34, 0.53, 0.88),
				"sc":Color(0.68, 0.86, 1.0)},
	"CO2":{ 	"s":Color(0.66, 0.66, 0.66),
				"l":Color(0.66, 0.66, 0.66),
				"sc":Color(0.66, 0.66, 0.66)},
	"CH4":{		"s":Color(0.63, 0.39, 0.13),
				"l":Color(0.63, 0.39, 0.13),
				"sc":Color(0.63, 0.39, 0.13)},
	"H":{		"s":Color(0.85, 1, 0.85),
				"l":Color(0.7, 1, 0.7),
				"sc":Color(0.85, 1, 0.85)},
	"He":{		"s":Color(0.943, 0.858, 1.0),
				"l":Color(0.78, 0.43, 1.0),
				"sc":Color(0.87, 0.66, 1.0)},
	"Ne":{		"s":Color(0.2, 1.0, 0.6),
				"l":Color(0.1, 1.0, 0.3),
				"sc":Color(0.2, 1.0, 0.6)},
	"Xe":{		"s":Color(0.5, 0.25, 1.0),
				"l":Color(0.5, 0.25, 1.0),
				"sc":Color(0.5, 0.25, 1.0)},
	"NH3":{		"s":Color(0.5, 0.45, 1.0),
				"l":Color(0.7, 0.65, 1.0),
				"sc":Color(0.5, 0.45, 1.0)},
	"O":{		"s":Color(0.8, 0.8, 1),
				"l":Color(0.8, 0.8, 1),
				"sc":Color(0.8, 0.8, 1)},
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

var lake_SP_bonus = {
	"H2O":1.0,
	"CH4":0.6,
	"CO2":1.8,
	"H":0.5,
	"He":0.8,
	"Ne":5.0,
	"Xe":50.0,
	"O":3.0,
	"NH3":1.4,
}

var default_help = {
				"materials":true,
				"mining":true,
				"STM":true,
				"battle":true,
				"battle2":true,
				"battle3":true,
				"plant_something_here":true,
				"boulder_desc":true,
				"aurora_desc":true,
				"crater_desc":true,
				"inventory_shortcuts":true,
				"hotbar_shortcuts":true,
				"rover_shortcuts":true,
				"mass_buy":true,
				"rover_inventory_shortcuts":true,
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

var ancient_bldg_icons = {
	AncientBuilding.SPACEPORT:[energy_icon, energy_icon],
	AncientBuilding.MINERAL_REPLICATOR:[minerals_icon],
	AncientBuilding.SUBSTATION:[energy_icon, energy_icon, energy_icon],
#	AncientBuilding.AURORA_GENERATOR:[],
	AncientBuilding.NUCLEAR_FUSION_REACTOR:[energy_icon],
	AncientBuilding.MINING_OUTPOST:[],
	AncientBuilding.OBSERVATORY:[SP_icon],
	AncientBuilding.CELLULOSE_SYNTHESIZER:[cellulose_icon],
}

var ancient_bldg_repair_cost_multipliers = {
	AncientBuilding.SPACEPORT:1.2,
	AncientBuilding.MINERAL_REPLICATOR:2.4,
	AncientBuilding.SUBSTATION:2.5,
#	AncientBuilding.AURORA_GENERATOR:3.0,
	AncientBuilding.NUCLEAR_FUSION_REACTOR:8.5,
	AncientBuilding.MINING_OUTPOST:1.0,
	AncientBuilding.OBSERVATORY:2.8,
	AncientBuilding.CELLULOSE_SYNTHESIZER:1.5,
}

var ancient_building_costs = {
	AncientBuilding.SPACEPORT:{"money":1e5, "energy":2e4, "SP":1e4},
	AncientBuilding.MINERAL_REPLICATOR:{"money":1.5e5, "energy":8e4, "SP":3e4},
	AncientBuilding.SUBSTATION:{"money":3e5, "energy":2.5e4, "SP":1e4},
	AncientBuilding.NUCLEAR_FUSION_REACTOR:{"money":1e6, "energy":3.5e5, "SP":9e4},
	AncientBuilding.MINING_OUTPOST:{"money":8e4, "energy":1.2e4, "SP":7e3},
	AncientBuilding.OBSERVATORY:{"money":1.2e5, "energy":1.5e4, "SP":1e4},
	AncientBuilding.CELLULOSE_SYNTHESIZER:{"money":2e5, "energy":6e4, "SP":2.5e4},
}

var MS_num_stages:Dictionary = {"DS":4, "MME":3, "CBS":3, "PK":2, "SE":1, "MB":0}

var ancient_bldg_tier_colors = [
	Color.WHITE,
	Color(0, 0.9, 0.0),
	Color(0.2, 0.2, 1.0),
	Color(1.0, 0.2, 1.0),
	Color(1.0, 0.5, 0.0),
	Color(1.0, 1.0, 0.2),
	Color.RED,
]
