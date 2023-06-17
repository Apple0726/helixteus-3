extends Node

var mod_list = {}
var mod_load_order = []
var dont_load = []
var added_buildings = {}
var added_tech_scenes = []
var added_tech_data = {}
var added_mats = {}
var added_mets = {}
var added_picks = {}
var added_speedups = {}
var added_overclocks = {}

func _ready():
	# Load config
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		mod_load_order = config.get_value("mods", "load_order", [])
		dont_load = config.get_value("mods", "dont_load", [])
	
	# Detect mods
	var mods = DirAccess.open("user://Mods")
	if mods:
		var installed_mods = {}
		mods.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next = mods.get_next()
		while next != "":
			var mod_name = next.rstrip(".zip")
			mod_name = mod_name.rstrip(".pck")
			installed_mods[mod_name] = next
			next = mods.get_next()
		mods.list_dir_end()
		
		# Load mods in order as defined in the config
		var new_mod_load_order = mod_load_order
		for mod_name in mod_load_order:
			if installed_mods.has(mod_name):
				var mod = installed_mods[mod_name]
				if ProjectSettings.load_resource_pack("user://Mods/%s" % mod, true):
					var main = load("res://%s/Main.gd" % mod_name)
					main = main.new()
					if !mod_name in dont_load:
						main.phase_1()
					mod_list[mod_name] = main
					installed_mods.erase(mod_name)
			else:
				new_mod_load_order.erase(mod_name)
		mod_load_order = new_mod_load_order
		
		# Load remaining mods
		for mod_name in installed_mods:
			var mod = installed_mods[mod_name]
			if ProjectSettings.load_resource_pack("user://Mods/%s" % mod, true):
				var main = load("res://%s/Main.gd" % mod_name)
				main = main.new()
				if !mod_name in dont_load:
						main.phase_1()
				mod_list[mod_name] = main
				mod_load_order.append(mod_name)
	else:
		mods.make_dir("user://Mods")
	
	config.set_value("mods", "load_order", mod_load_order)
	config.save("user://settings.cfg")
	
	update()

func add_building(building, data):
	# building is the internal name for the building, usually in all caps
	# data is the building data, refer to vanilla buildings for an example
	added_buildings[building] = data
	
	var trans = Translation.new()
	trans.add_message(building + "_NAME", data.name)
	trans.add_message(building + "_DESC", data.desc)
	TranslationServer.add_translation(trans)

func add_tech_scene(scene):
	# scene should match how the tech tree is structured
	added_tech_scenes.append(scene)

func add_tech_data(data):
	# data is the tech data, refer to vanilla techs for an example
	for key in data:
		added_tech_data[key] = data[key]
		
		var trans = Translation.new()
		trans.add_message(key + "_NAME", data[key].name)
		trans.add_message(key + "_DESC", data[key].desc)
		TranslationServer.add_translation(trans)

func add_mat(mat, data):
	added_mats[mat] = data

func add_met(met, data):
	added_mets[met] = data

func add_pick(pick, data):
	added_picks[pick] = data

func add_speedup(speedup, data):
	added_speedups[speedup] = data

func add_overclock(overclock, data):
	added_overclocks[overclock] = data

func update():
	for key in added_buildings:
		Data.costs[key] = added_buildings[key].costs
		if added_buildings[key].has("path_1"):
			Data.path_1[key] = added_buildings[key].path_1
		if added_buildings[key].has("path_2"):
			Data.path_2[key] = added_buildings[key].path_2
		if added_buildings[key].has("path_3"):
			Data.path_3[key] = added_buildings[key].path_3
		
		if added_buildings[key].has("rsrc_icon"):
			Data.rsrc_icons[key] = added_buildings[key].rsrc_icon
	
	for key in added_tech_data:
		Data.science_unlocks[key] = added_tech_data[key]
