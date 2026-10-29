extends Node

var installed_mod_list = []
var enabled_mod_list = []
var mod_instances = {}

func _ready():
	# Load settings
	var settings = ConfigFile.new()
	var settings_mod_list = []
	var err = settings.load("user://settings.cfg")
	if err == OK:
		settings_mod_list = settings.get_value("mods", "enabled", [])
	
	# Detect mods
	var mod_folder = DirAccess.open("user://Mods")
	if mod_folder:
		mod_folder.list_dir_begin()
		var next = mod_folder.get_next()
		while next != "":
			installed_mod_list.append(next)
			next = mod_folder.get_next()
		mod_folder.list_dir_end()
		
		# Load mods in the order defined in the settings
		for mod_name in settings_mod_list:
			if installed_mod_list.has(mod_name):
				enabled_mod_list.append(mod_name)
				if FileAccess.file_exists("user://Mods/%s/resources.zip" % mod_name):
					if ProjectSettings.load_resource_pack("user://Mods/%s/resources.zip" % mod_name, true):
						if FileAccess.file_exists("res://%s/Main.gd" % mod_name):
							var main = load("res://%s/Main.gd" % mod_name)
							main = main.new()
							mod_instances[mod_name] = main
		
		settings.load("user://settings.cfg")
		settings.set_value("mods", "enabled", enabled_mod_list)
		settings.save("user://settings.cfg")
		
		# Initialize mods in order
		for mod in mod_instances.values():
			if mod.has_method("_mod_init"):
				mod.call("_mod_init")
	else:
		mod_folder = DirAccess.open("user://")
		mod_folder.make_dir("user://Mods")
