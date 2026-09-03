extends Control

@onready var game = get_node("/root/Game")

func load_backups(save_name:String):
	var backup_dir = DirAccess.open("user://%s/Backups" % save_name)
	if not backup_dir:
		return
	backup_dir.list_dir_begin()
	var backup_file_name:String = backup_dir.get_next()
	var total_files = 0
	var total_file_size = 0
	var files = []
	while backup_file_name != "":
		files.append(backup_file_name)
		backup_file_name = backup_dir.get_next()
	files.sort()
	files.reverse()
	for file_name in files:
		var backup_file = FileAccess.open("user://%s/Backups/%s" % [save_name, file_name], FileAccess.READ)
		if backup_file:
			var backup_scene = preload("res://Scenes/SaveBackup.tscn").instantiate()
			$ScrollContainer/VBoxContainer.add_child(backup_scene)
			backup_scene.get_node("Label").text = file_name
			var file_size = backup_file.get_length()
			backup_scene.get_node("Size").text = Helper.get_file_size_string(file_size)
			backup_scene.get_node("Button").pressed.connect(game.show_YN_panel.bind(load_backup, tr("BACKUP_WILL_CREATE_NEW_SAVE"), [file_name]))
			total_files += 1
			total_file_size += file_size
	$Label.text = tr("BACKUPS_FOR_SAVE").format({"save":save_name}) + " (%s)" % tr("FILE_NUMBER_AND_SIZE").format({
		"file_num": total_files,
		"file_size_bytes":Helper.get_file_size_string(total_file_size)
	})

func load_backup(save_name:String):
	print(save_name)

func _on_close_button_pressed() -> void:
	queue_free()
