extends Control

signal refresh_load_panel

@onready var game = get_node("/root/Game")

func load_backups(save_name:String):
	var backup_dir = DirAccess.open("user://%s/Backups" % save_name)
	if not backup_dir:
		return
	backup_dir.list_dir_begin()
	var total_files = 0
	var total_file_size = 0
	var files = backup_dir.get_files()
	files.reverse()
	for backup_file_name in files:
		var backup_file_path = "user://%s/Backups/%s" % [save_name, backup_file_name]
		var backup_file = FileAccess.open(backup_file_path, FileAccess.READ)
		if backup_file:
			var backup_scene = preload("res://Scenes/SaveBackup.tscn").instantiate()
			$ScrollContainer/VBoxContainer.add_child(backup_scene)
			if len(backup_file_name) > 40:
				backup_scene.get_node("Label").text = backup_file_name.substr(0, 20) + "(...)" + backup_file_name.substr(len(backup_file_name) - 20)
			else:
				backup_scene.get_node("Label").text = backup_file_name
			var file_size = backup_file.get_length()
			backup_scene.get_node("Size").text = Helper.get_file_size_string(file_size)
			backup_scene.get_node("Button").pressed.connect(game.show_YN_panel.bind(load_backup.bind(backup_file_name, backup_file_path), tr("BACKUP_WILL_CREATE_NEW_SAVE")))
			total_files += 1
			total_file_size += file_size
	var save_name_display = save_name
	if len(save_name_display) > 20:
		save_name_display = save_name_display.substr(0, 10) + "(...)" + save_name_display.substr(len(save_name_display) - 10)
	$Label.text = tr("BACKUPS_FOR_SAVE").format({"save":save_name_display}) + " (%s)" % tr("FILE_NUMBER_AND_SIZE").format({
		"file_num": total_files,
		"file_size_bytes":Helper.get_file_size_string(total_file_size)
	})

func load_backup(save_name:String, path:String):
	Helper.import_save(save_name.replace(".hx3", ""), path)
	emit_signal("refresh_load_panel")
	queue_free()

func _on_close_button_pressed() -> void:
	queue_free()


func _on_hidden() -> void:
	queue_free()
