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
			backup_scene.get_node("Label").text = backup_file_name
			var file_size = backup_file.get_length()
			backup_scene.get_node("Size").text = Helper.get_file_size_string(file_size)
			backup_scene.get_node("Button").pressed.connect(game.show_YN_panel.bind(load_backup, tr("BACKUP_WILL_CREATE_NEW_SAVE"), [backup_file_name, backup_file_path]))
			total_files += 1
			total_file_size += file_size
	$Label.text = tr("BACKUPS_FOR_SAVE").format({"save":save_name}) + " (%s)" % tr("FILE_NUMBER_AND_SIZE").format({
		"file_num": total_files,
		"file_size_bytes":Helper.get_file_size_string(total_file_size)
	})

func load_backup(save_name:String, path:String):
	Helper.import_save(save_name.replace(".hx3", ""), path)
	emit_signal("refresh_load_panel")
	queue_free()

func _on_close_button_pressed() -> void:
	queue_free()
