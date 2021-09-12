extends "Panel.gd"

var save_slot_scene = preload("res://Scenes/SaveSlot.tscn")
var save_to_delete:String = ""
var save_to_export:String = ""

func refresh():
	for save in $ScrollContainer/VBox.get_children():
		$ScrollContainer/VBox.remove_child(save)
		save.queue_free()
	var file = Directory.new()
	file.open("user://")
	file.list_dir_begin(true)
	var next_dir:String = file.get_next()
	while next_dir != "":
		var save_info = File.new()
		if save_info.open("user://%s/save_info.hx3" % [next_dir], File.READ) == OK:
			var save_info_dict:Dictionary = save_info.get_var()
			var save = save_slot_scene.instance()
			if save_info.get_len() == save_info.get_position():
				var save_created = save_info_dict.save_created
				var save_modified = save_info_dict.save_modified
				save.get_node("Version").text = save_info_dict.version
				save.get_node("Button").connect("pressed", self, "on_load", [next_dir])
				save.get_node("Delete").connect("pressed", self, "on_delete", [next_dir])
				save.get_node("Export").connect("pressed", self, "on_export", [next_dir])
				save.get_node("Button").text = next_dir
				save.get_node("Version")["custom_colors/font_color"] = Color.green
				var now = OS.get_system_time_msecs()
				if now - save_created < 86400000 * 2:
					save.get_node("Created").text = "%s %s" % [tr("SAVE_CREATED"), tr("X_HOURS_AGO") % ((now - save_created) / 3600000)]
				else:
					save.get_node("Created").text = "%s %s" % [tr("SAVE_CREATED"), tr("X_DAYS_AGO") % ((now - save_created) / 86400000)]
				if now - save_modified < 86400000 * 2:
					save.get_node("Saved").text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_HOURS_AGO") % ((now - save_modified) / 3600000)]
				else:
					save.get_node("Saved").text = "%s %s" % [tr("SAVE_MODIFIED"), tr("X_DAYS_AGO") % ((now - save_modified) / 86400000)]
				$ScrollContainer/VBox.add_child(save)
			else:
				remove_recursive("user://%s" % next_dir)
		save_info.close()
		next_dir = file.get_next()

func on_export(save_str:String):
	save_to_export = save_str
	$PopupBackground.visible = true
	$Export.current_file = save_str
	$Export.window_title = tr("EXPORT_X") % save_str
	$Export.popup_centered()

func on_load(sv:String):
	if modulate.a == 1:
		game.c_sv = sv
		game.toggle_panel(self)
		game.fade_out_title("load_game")

func on_delete(save_str:String):
	$PopupBackground.visible = true
	$ConfirmSaveDeletion.visible = true
	$ConfirmSaveDeletion/Label2.text = tr("CONFIRM_DELETION_INFO") % save_str
	save_to_delete = save_str


func _on_delete_save():
	if $ConfirmSaveDeletion/LineEdit.text == save_to_delete:
		$PopupBackground.visible = false
		remove_recursive("user://%s" % save_to_delete)
		$ConfirmSaveDeletion.visible = false
		game.popup(tr("SAVE_DELETED"), 2.0)
		refresh()

func remove_recursive(path):
	var directory = Directory.new()
	
	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)


func _on_ImportSave_pressed():
	$PopupBackground.visible = true
	$Import.popup_centered()


func _on_Import_popup_hide():
	$PopupBackground.visible = false


func _on_Export_file_selected(path):
	var file = File.new()
	var error = file.open(path, File.WRITE)
	var error2 = false
	if error == OK:
		var save_dict = {"univs":[]}
		var file2 = File.new()
		if file2.open("user://%s/save_info.hx3" % save_to_export, File.READ) == OK:
			save_dict.save_info = file2.get_var()
			file2.close()
			var directory = Directory.new()
			if directory.open("user://%s" % save_to_export) == OK:
				directory.list_dir_begin(true)
				var file_name = directory.get_next()
				while file_name != "":
					if directory.current_is_dir():
						var export_univ_res:Dictionary = export_univ(file_name)
						if export_univ_res.error:
							error2 = true
							break
						else:
							save_dict.univs.append(export_univ_res.univ_data)
					file_name = directory.get_next()
				if not error2:
					file.store_var(save_dict)
					game.popup(tr("EXPORT_SUCCESS") % save_to_export, 2.0)
					$PopupBackground.visible = false
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
	var file = File.new()
	if file.open("user://%s/%s/main.hx3" % [save_to_export, univ_str], File.READ) == OK:
		univ_data.main = file.get_var()
	else:
		error = true
	file.close()
	file = File.new()
	if file.open("user://%s/%s/supercluster_data.hx3" % [save_to_export, univ_str], File.READ) == OK:
		univ_data.supercluster_data = file.get_var()
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
		error = export_univ_folder(univ_data, univ_str, "Superclusters")
	if not error:
		error = export_univ_folder(univ_data, univ_str, "Systems")
	return {"error":error, "univ_data":univ_data}

func export_univ_folder(univ_data:Dictionary, univ_str:String, folder:String):
	var error = false
	var directory = Directory.new()
	if directory.open("user://%s/%s/%s" % [save_to_export, univ_str, folder]) == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if not directory.current_is_dir():
				var file = File.new()
				if file.open("user://%s/%s/%s/%s" % [save_to_export, univ_str, folder, file_name], File.READ) == OK:
					univ_data[folder.to_lower()][file_name] = file.get_var()
				else:
					error = true
				file.close()
			file_name = directory.get_next()


func _on_Import_file_selected(path):
	var importing_file = File.new()
	var import_save_name:String = $Import.current_file.replace(".hx3", "")
	if importing_file.open(path, File.READ) == OK:
		var save_dict:Dictionary = importing_file.get_var()
		var directory = Directory.new()
		var final_save_name:String = import_save_name
		if directory.dir_exists("user://%s" % import_save_name):
			var dupl:int = 2
			while directory.dir_exists("user://%s%s" % [import_save_name, dupl]):
				dupl += 1
			final_save_name = "%s%s" % [import_save_name, dupl]
		if directory.make_dir("user://%s" % final_save_name) == OK:
			var save_info_file = File.new()
			if save_info_file.open("user://%s/save_info.hx3" % final_save_name, File.WRITE) == OK:
				save_info_file.store_var(save_dict.save_info)
				for i in len(save_dict.univs):
					if directory.make_dir("user://%s/Univ%s" % [final_save_name, i]) == OK:
						var univ_file = File.new()
						if univ_file.open("user://%s/Univ%s/main.hx3" % [final_save_name, i], File.WRITE) == OK:
							univ_file.store_var(save_dict.univs[i].main)
						if univ_file.open("user://%s/Univ%s/supercluster_data.hx3" % [final_save_name, i], File.WRITE) == OK:
							univ_file.store_var(save_dict.univs[i].supercluster_data)
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Caves")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Clusters")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Galaxies")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Planets")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Superclusters")
						make_obj_dir(save_dict, i, "user://%s/Univ%s" % [final_save_name, i], "Systems")
						univ_file.close()
						game.popup(tr("IMPORT_SUCCESS") % final_save_name, 2.0)
			save_info_file.close()
	importing_file.close()
	refresh()

func make_obj_dir(save_dict:Dictionary, univ:int, path:String, obj:String):
	var directory = Directory.new()
	if directory.make_dir("%s/%s" % [path, obj]) == OK:
		for obj_file_name in save_dict.univs[univ][obj.to_lower()].keys():
			var file = File.new()
			if file.open("%s/%s/%s" % [path, obj, obj_file_name], File.WRITE) == OK:
				file.store_var(save_dict.univs[univ][obj.to_lower()][obj_file_name])
			file.close()


func _on_Export_popup_hide():
	$PopupBackground.visible = false
