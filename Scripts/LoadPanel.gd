extends "Panel.gd"

var save_slot_scene = preload("res://Scenes/SaveSlot.tscn")
var save_to_export:String = ""

func on_version_over_ok():
	game.show_tooltip(tr("SAME_VERSION"))

func on_version_over_compatible():
	game.show_tooltip(tr("VERSION_COMPATIBLE"))

func on_version_over_not_ok():
	game.show_tooltip(tr("VERSION_INCOMPATIBLE"))

func on_mouse_exit():
	game.hide_tooltip()

func refresh():
	for save in $ScrollContainer/VBox.get_children():
		save.queue_free()
	var file = DirAccess.open("user://")
	file.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var next_dir:String = file.get_next()
	while next_dir != "":
		var save_info = FileAccess.open("user://%s/save_info.hx3" % [next_dir], FileAccess.READ)
		if save_info:
			var save_info_dict = save_info.get_var()
			if not save_info_dict is Dictionary:
				next_dir = file.get_next()
				continue
			var save = save_slot_scene.instantiate()
			if save_info.get_length() == save_info.get_position():
				var save_created = save_info_dict.save_created
				var save_modified = save_info_dict.save_modified
				save.get_node("Version").text = save_info_dict.version
				save.get_node("Button").connect("pressed",Callable(self,"on_load").bind(next_dir))
				save.get_node("Delete").connect("pressed",Callable(self,"on_delete").bind(next_dir))
				save.get_node("Export").connect("pressed",Callable(self,"on_export").bind(next_dir))
				save.get_node("Button").text = next_dir
				if save_info_dict.version == game.VERSION:
					save.get_node("Version").connect("mouse_entered",Callable(self,"on_version_over_ok"))
					save.get_node("Version")["theme_override_colors/font_color"] = Color.GREEN
				elif save_info_dict.version in game.COMPATIBLE_SAVES:
					save.get_node("Version").connect("mouse_entered",Callable(self,"on_version_over_compatible"))
					save.get_node("Version")["theme_override_colors/font_color"] = Color.YELLOW
				else:
					save.get_node("Version").connect("mouse_entered",Callable(self,"on_version_over_not_ok"))
					save.get_node("Version")["theme_override_colors/font_color"] = Color.RED
				save.get_node("Version").connect("mouse_exited",Callable(self,"on_mouse_exit"))
				var now = Time.get_unix_time_from_system()
				if now - save_created < 86400 * 2:
					save.get_node("Created").text = "%s %s" % [tr("SAVE_CREATED"), tr("X_HOURS_AGO") % int((now - save_created) / 3600)]
				else:
					save.get_node("Created").text = "%s %s" % [tr("SAVE_CREATED"), tr("X_DAYS_AGO") % int((now - save_created) / 86400)]
				if now - save_modified < 86400 * 2:
					save.get_node("Saved").text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_HOURS_AGO") % int((now - save_modified) / 3600)]
				else:
					save.get_node("Saved").text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_DAYS_AGO") % int((now - save_modified) / 86400)]
				$ScrollContainer/VBox.add_child(save)
			else:
				Helper.remove_recursive("user://%s" % next_dir)
			save_info.close()
		next_dir = file.get_next()

func on_export(save_str:String):
	save_to_export = save_str
	if OS.get_name() == "Web":
		export_game("user://%s.hx3" % save_str)
		var file = FileAccess.open("user://%s.hx3" % save_str, FileAccess.READ)
		var L = file.get_length()
		var buffer = file.get_buffer(L)
		file.close()
		JavaScriptBridge.download_buffer(buffer, save_str + ".hx3")
	else:
		$Export.current_file = save_str
		$Export.title = tr("EXPORT_X") % save_str
		$Export.popup_centered()

func on_load(sv:String):
	if modulate.a == 1:
		game.c_sv = sv
		game.toggle_panel(self)
		game.fade_out_title("load_game")

func on_delete(save_str:String):
	game.show_YN_panel("delete_save", tr("ARE_YOU_SURE"), [save_str])


func on_delete_confirm(save_str:String):
	Helper.remove_recursive("user://%s" % save_str)
	game.popup(tr("SAVE_DELETED"), 2.0)
	refresh()


func _on_ImportSave_pressed():
	$Import.popup_centered()

func _on_Export_file_selected(path):
	export_game(path)

func export_game(path:String = "user://"):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var error2 = false
	if file:
		var save_dict = {"univs":[]}
		var file2 = FileAccess.open("user://%s/save_info.hx3" % save_to_export, FileAccess.READ)
		if file2:
			save_dict.save_info = file2.get_var()
			file2.close()
			var directory = DirAccess.open("user://%s" % save_to_export)
			if directory:
				directory.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
				var file_name = directory.get_next()
				while file_name != "":
					if directory.current_is_dir():
						var export_univ_res:Dictionary = export_univ(file_name)
						if export_univ_res.error:
							error2 = true
							break
						else:
							save_dict.univs.append(export_univ_res.univ_data.duplicate(true))
					file_name = directory.get_next()
				if not error2:
					file.store_var(save_dict)
					game.popup(tr("EXPORT_SUCCESS") % save_to_export, 2.0)
	file.close()
	
func export_univ(univ_str:String):
	var error = false
	var univ_data:Dictionary = {
		"caves":{},
		"clusters":{},
		"galaxies":{},
		"planets":{},
		"superclusters":{},
		"systems":{},
	}
	var file = FileAccess.open("user://%s/%s/main.hx3" % [save_to_export, univ_str], FileAccess.READ)
	if file:
		univ_data.main = file.get_var()
	else:
		error = true
	file.close()
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Caves")
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Clusters")
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Galaxies")
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Planets")
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Systems")
	return {"error":error, "univ_data":univ_data}

func export_univ_folder(univ_data:Dictionary, univ_str:String, folder:String):
	var error = false
	var directory = DirAccess.open("user://%s/%s/%s" % [save_to_export, univ_str, folder])
	if directory:
		directory.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = directory.get_next()
		while file_name != "":
			if not directory.current_is_dir():
				var file = FileAccess.open("user://%s/%s/%s/%s" % [save_to_export, univ_str, folder, file_name], FileAccess.READ)
				if file:
					univ_data[folder.to_lower()][file_name] = file.get_var()
				else:
					error = true
				file.close()
			file_name = directory.get_next()


func _on_Import_file_selected(path):
	var importing_file = FileAccess.open(path, FileAccess.READ)
	var import_save_name:String = $Import.current_file.replace(".hx3", "")
	if importing_file:
		var save_dict:Dictionary = importing_file.get_var()
		var directory = DirAccess.open("user://")
		var final_save_name:String = import_save_name
		if directory.dir_exists(import_save_name):
			var dupl:int = 2
			while DirAccess.open("user://%s%s" % [import_save_name, dupl]):
				dupl += 1
			final_save_name = "%s%s" % [import_save_name, dupl]
		else:
			final_save_name = import_save_name
		if directory.make_dir(final_save_name) == OK:
			var save_info_file = FileAccess.open("user://%s/save_info.hx3" % final_save_name, FileAccess.WRITE)
			if save_info_file:
				save_info_file.store_var(save_dict.save_info)
				for i in len(save_dict.univs):
					if directory.make_dir("user://%s/Univ%s" % [final_save_name, i]) == OK:
						var univ_file = FileAccess.open("user://%s/Univ%s/main.hx3" % [final_save_name, i], FileAccess.WRITE)
						if univ_file:
							univ_file.store_var(save_dict.univs[i].main)
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Caves")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Clusters")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Galaxies")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Planets")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Systems")
						univ_file.close()
						game.popup(tr("IMPORT_SUCCESS") % final_save_name, 2.0)
			save_info_file.close()
	importing_file.close()
	$PopupBackground.visible = false
	refresh()

func make_obj_dir(save_dict:Dictionary, univ:int, path:String, obj:String):
	var directory = DirAccess.open(path)
	if directory.make_dir("%s/%s" % [path, obj]) == OK:
		for obj_file_name in save_dict.univs[univ][obj.to_lower()].keys():
			var file = FileAccess.open("%s/%s/%s" % [path, obj, obj_file_name], FileAccess.WRITE)
			if file:
				file.store_var(save_dict.univs[univ][obj.to_lower()][obj_file_name])
			file.close()

func _on_export_visibility_changed():
	$PopupBackground.visible = $Export.visible


func _on_import_visibility_changed():
	$PopupBackground.visible = $Import.visible
