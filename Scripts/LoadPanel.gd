extends "Panel.gd"

var save_slot_scene = preload("res://Scenes/SaveSlot.tscn")

func refresh():
	for save in $ScrollContainer/VBox.get_children():
		$ScrollContainer/VBox.remove_child(save)
		save.queue_free()
	var file = Directory.new()
	file.open("user://")
	file.list_dir_begin(true)
	var next_dir:String = file.get_next()
	while next_dir != "":
		if next_dir.substr(0, 4) == "Save":
			var save_info = File.new()
			save_info.open("user://%s/save_info.hx3" % [next_dir], File.READ)
			var save_created:Dictionary = save_info.get_var()
			var save_modified:Dictionary = save_info.get_var()
			save_info.close()
			var save = save_slot_scene.instance()
			save.get_node("Button").connect("pressed", self, "on_load", [next_dir.substr(4)])
			save.get_node("Delete").connect("pressed", self, "on_delete", [next_dir.substr(4)])
			save.get_node("Button").text = next_dir
			save.get_node("Created").text = "%s %s" % [tr("SAVE_CREATED"), tr("DATE_FORMAT").format({"day":save_created.day, "month":save_created.month, "year":save_created.year})]
			save.get_node("Saved").text = "%s %s" % [tr("SAVE_SAVED"), tr("DATE_FORMAT").format({"day":save_modified.day, "month":save_modified.month, "year":save_modified.year})]
			$ScrollContainer/VBox.add_child(save)
		next_dir = file.get_next()
	
func on_load(sv:String):
	if modulate.a == 1:
		game.c_sv = int(sv)
		game.toggle_panel(self)
		game.fade_out_title("load_game")

func on_delete():
	pass
#	if file.file_exists("user://Save%s/Univ%s/supercluster_data.hx3"):
#		dir.remove("user://Save%s/Univ%s/supercluster_data.hx3")
#	if dir.open("user://Save%s/Univ%s/Planets") == OK:
#		remove_files(dir)
#	if dir.open("user://Save%s/Univ%s/Systems") == OK:
#		remove_files(dir)
#	if dir.open("user://Save%s/Univ%s/Galaxies") == OK:
#		remove_files(dir)
#	if dir.open("user://Save%s/Univ%s/Clusters") == OK:
#		remove_files(dir)
#	if dir.open("user://Save%s/Univ%s/Superclusters") == OK:
#		remove_files(dir)
