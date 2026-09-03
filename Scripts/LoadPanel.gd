extends "Panel.gd"

var save_slot_scene = preload("res://Scenes/SaveSlot.tscn")
var save_to_export:String = ""

func _ready():
	$HBoxContainer/ShowInFileManager.visible = OS.get_name() in ["Windows", "Linux"]

func refresh():
	for save in $ScrollContainer/HBox.get_children():
		save.queue_free()
	var file = DirAccess.open("user://")
	file.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var next_dir:String = file.get_next()
	while next_dir != "":
		var save_info = FileAccess.open("user://%s/save_info.hx3" % [next_dir], FileAccess.READ)
		var save_info_dict
		var try_backup = false
		if save_info == null:
			try_backup = true
		else:
			save_info_dict = save_info.get_var()
			if save_info_dict is not Dictionary:
				try_backup = true
		if try_backup:
			save_info = FileAccess.open("user://%s/save_info.hx3~" % [next_dir], FileAccess.READ)
			if save_info == null:
				next_dir = file.get_next()
				continue
			else:
				save_info_dict = save_info.get_var()
				if save_info_dict is not Dictionary:
					next_dir = file.get_next()
					continue
		save_info.close()
		var save = save_slot_scene.instantiate()
		$ScrollContainer/HBox.add_child(save)
		save.open_backup_panel.connect(open_backup_panel.bind(next_dir))
		save.initialize(save_info_dict, next_dir, on_load, on_delete, on_export)
		next_dir = file.get_next()

func open_backup_panel(save_name:String):
	var save_backups_scene = preload("res://Scenes/Panels/SaveBackups.tscn").instantiate()
	add_child(save_backups_scene)
	save_backups_scene.load_backups(save_name)

func on_export(save_str:String):
	save_to_export = save_str
	if OS.get_name() == "Web":
		if Helper.export_game("user://%s.hx3" % save_str, "user://"):
			game.popup(tr("EXPORT_SUCCESS") % save_to_export, 2.0)
			var file = FileAccess.open("user://%s.hx3" % save_str, FileAccess.READ)
			var L = file.get_length()
			var buffer = file.get_buffer(L)
			file.close()
			JavaScriptBridge.download_buffer(buffer, save_str + ".hx3")
		else:
			game.popup(tr("EXPORT_FAILED").format({"save":save_to_export}), 2.0)
	else:
		$Export.current_file = save_str
		$Export.title = tr("EXPORT_X") % save_str
		$Export.popup_centered()

func on_load(sv:String):
	if modulate.a == 1:
		game.c_sv = sv
		game.toggle_panel(panel_var_name)
		game.fade_out_title("load_game")

func on_delete(save_str:String):
	game.show_YN_panel(game.delete_save, tr("ARE_YOU_SURE"), [save_str])


func on_delete_confirm(save_str:String):
	Helper.remove_recursive("user://%s" % save_str)
	game.popup(tr("SAVE_DELETED"), 2.0)
	refresh()


func _on_ImportSave_pressed():
	$Import.popup_centered()

func _on_Export_file_selected(path):
	if Helper.export_game(save_to_export, path):
		game.popup(tr("EXPORT_SUCCESS") % save_to_export, 2.0)
	else:
		game.popup(tr("EXPORT_FAILED").format({"save":save_to_export}), 2.0)


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


func _on_show_in_file_manager_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
