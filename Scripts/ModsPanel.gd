extends "Panel.gd"

var mod_slot_scene = preload("res://Scenes/ModSlot.tscn")

func add_mod_slot(mod_name):
	var mod_slot = mod_slot_scene.instantiate()
	mod_slot.name = mod_name
	mod_slot.get_node("LoadOrder/Up").connect("pressed",Callable(self,"_on_up_pressed").bind(mod_slot))
	mod_slot.get_node("LoadOrder/Down").connect("pressed",Callable(self,"_on_down_pressed").bind(mod_slot))
	mod_slot.get_node("Load").connect("pressed",Callable(self,"_on_load_pressed").bind(mod_slot))
	$ScrollContainer/VBox.add_child(mod_slot)

func _ready():
	$HBoxContainer/OpenModsFolder.visible = OS.get_name() in ["Windows", "Linux"]
	
	# Add all of the enabled mods first in the order they were loaded
	for mod_name in Mods.enabled_mod_list:
		add_mod_slot(mod_name)
	
	# Add all of the disabled mods second
	for mod_name in Mods.installed_mod_list:
		if not mod_name in Mods.enabled_mod_list:
			add_mod_slot(mod_name)

func update_mod_order():
	var mod_slots = $ScrollContainer/VBox.get_children()
	var enabled_mod_list = []
	for mod_slot in mod_slots:
		if mod_slot.get_node("Load").button_pressed:
			enabled_mod_list.append(mod_slot.name)
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("mods", "enabled", enabled_mod_list)
	config.save("user://settings.cfg")

func _on_up_pressed(mod_slot):
	var index = mod_slot.get_index()
	if index > 0:
		$ScrollContainer/VBox.move_child(mod_slot, index - 1)
		update_mod_order()

func _on_down_pressed(mod_slot):
	var index = mod_slot.get_index()
	if index < $ScrollContainer/VBox.get_child_count() - 1:
		$ScrollContainer/VBox.move_child(mod_slot, index + 1)
		update_mod_order()

func _on_load_pressed(_mod_slot):
	update_mod_order()

func _on_wiki_pressed():
	OS.shell_open("https://sites.google.com/view/helixteus3moddingwiki")

func _on_open_mods_folder_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://Mods"))
