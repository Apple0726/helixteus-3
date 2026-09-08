extends "Panel.gd"

@onready var exporting_label = $ExportingLabel

var save_slot_scene = preload("res://Scenes/SaveSlot.tscn")
var save_to_export:String = ""
var export_total_files:int

func _ready():
	set_polygon($GUI.size, $GUI.position)
	$HBoxContainer/ShowInFileManager.visible = OS.get_name() in ["Windows", "Linux"]

func _process(delta: float) -> void:
	if exporting_label.visible:
		exporting_label.text = tr("EXPORTING") + " (%d%%)" % int(Helper.export_save_files_exported * 100.0 / export_total_files)

func refresh():
	for save in $ScrollContainer/HBox.get_children():
		save.queue_free()
	var save_dir = DirAccess.open("user://")
	var saves = save_dir.get_directories()
	for save_name in saves:
		var save_info = FileAccess.open("user://%s/save_info.hx3" % [save_name], FileAccess.READ)
		var save_info_dict
		var try_backup = false
		if save_info == null:
			try_backup = true
		else:
			save_info_dict = save_info.get_var()
			if save_info_dict is not Dictionary:
				try_backup = true
		if try_backup:
			save_info = FileAccess.open("user://%s/save_info.hx3~" % [save_name], FileAccess.READ)
			if save_info == null:
				continue
			else:
				save_info_dict = save_info.get_var()
				if save_info_dict is not Dictionary:
					continue
		save_info.close()
		var save = save_slot_scene.instantiate()
		$ScrollContainer/HBox.add_child(save)
		save.open_backup_panel.connect(open_backup_panel.bind(save_name))
		save.initialize(save_info_dict, save_name, on_load, on_delete, on_export)
	$TotalFileSize.label_text = tr("PERSISTENT_STORAGE") + Helper.get_file_size_string(Helper.get_directory_properties("user://").size) + " "
	$TotalFileSize.refresh()

func open_backup_panel(save_name:String):
	var save_backups_scene = preload("res://Scenes/Panels/SaveBackups.tscn").instantiate()
	add_child(save_backups_scene)
	save_backups_scene.refresh_load_panel.connect(refresh)
	save_backups_scene.load_backups(save_name)

func on_export(save_str:String):
	save_to_export = save_str
	if OS.get_name() == "Web":
		if await Helper.export_save("user://%s.hx3" % save_str, "user://"):
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
	export_total_files = Helper.get_directory_properties("user://%s" % save_to_export, ["Backups"]).files
	$ExportingLabel.text = ""
	$ExportingLabel.show()
	if await Helper.export_save(save_to_export, path):
		game.popup(tr("EXPORT_SUCCESS") % save_to_export, 2.0)
	else:
		game.popup(tr("EXPORT_FAILED").format({"save":save_to_export}), 2.0)
	$ExportingLabel.hide()


func _on_Import_file_selected(path):
	var import_save_name:String = $Import.current_file.replace(".hx3", "")
	Helper.import_save(import_save_name, path)
	$PopupBackground.visible = false
	refresh()

func _on_export_visibility_changed():
	$PopupBackground.visible = $Export.visible


func _on_import_visibility_changed():
	$PopupBackground.visible = $Import.visible


func _on_show_in_file_manager_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
