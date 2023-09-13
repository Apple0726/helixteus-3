extends "Panel.gd"

var mod_slot_scene = preload("res://Scenes/ModSlot.tscn")

func _ready():
	$HBoxContainer/OpenModsFolder.visible = OS.get_name() in ["Windows", "Linux"]
	for key in Mods.mod_list:
		var mod = Mods.mod_list[key]
		var mod_slot = mod_slot_scene.instantiate()
		mod_slot.get_node("Name").text = mod.mod_info.name
		mod_slot.get_node("Version").text = mod.mod_info.version
		mod_slot.get_node("Author").text = mod.mod_info.author
		mod_slot.get_node("Description").text = mod.mod_info.description
		mod_slot.get_node("Load").button_pressed = !key in Mods.dont_load
		mod_slot.get_node("LoadOrder/Up").connect("pressed",Callable(self,"on_up").bind(key, mod_slot))
		mod_slot.get_node("LoadOrder/Down").connect("pressed",Callable(self,"on_down").bind(key, mod_slot))
		mod_slot.get_node("Load").connect("pressed",Callable(self,"on_load").bind(key, mod_slot))
		$ScrollContainer/VBox.add_child(mod_slot)

func on_up(key, mod_slot):
	var order = Mods.mod_load_order.find(key)
	if !order in [-1, 0]:
		var key2 = Mods.mod_load_order[order - 1]
		Mods.mod_load_order[order] = key2
		Mods.mod_load_order[order - 1] = key
		var config = ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("mods", "load_order", Mods.mod_load_order)
		config.save("user://settings.cfg")
		$ScrollContainer/VBox.move_child(mod_slot, order - 1)

func on_down(key, mod_slot):
	var order = Mods.mod_load_order.find(key)
	if !order in [-1, Mods.mod_load_order.size() - 1]:
		var key2 = Mods.mod_load_order[order + 1]
		Mods.mod_load_order[order] = key2
		Mods.mod_load_order[order + 1] = key
		var config = ConfigFile.new()
		config.load("user://settings.cfg")
		config.set_value("mods", "load_order", Mods.mod_load_order)
		config.save("user://settings.cfg")
		$ScrollContainer/VBox.move_child(mod_slot, order + 1)

func on_load(key, mod_slot):
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	if mod_slot.get_node("Load").button_pressed:
		Mods.dont_load.erase(key)
		config.set_value("mods", "dont_load", Mods.dont_load)
	else:
		if Mods.dont_load == []:
			Mods.dont_load = [key]
			config.set_value("mods", "dont_load", Mods.dont_load)
		else:
			Mods.dont_load.append(key)
			config.set_value("mods", "dont_load", Mods.dont_load)
	config.save("user://settings.cfg")


func _on_wiki_pressed():
	OS.shell_open("https://sites.google.com/view/helixteus3moddingwiki")


func _on_open_mods_folder_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://Mods"))
