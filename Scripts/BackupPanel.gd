extends Panel

@onready var game = get_node("/root/Game")
@onready var progress_bar = $ProgressBar

var ready_to_backup = false
var is_backing_up = false
var last_input_timestamp:float = Time.get_unix_time_from_system()
var backup_total_files:int


func start_timer():
	$Timer.start(Settings.backup_interval * 60.0)
	
func _process(delta: float) -> void:
	if not DisplayServer.window_is_focused(0) and ready_to_backup:
		perform_backup()
	if is_backing_up:
		progress_bar.value = Helper.export_save_files_exported / float(backup_total_files) * 100.0

func _input(event):
	var curr_time = Time.get_unix_time_from_system()
	last_input_timestamp = curr_time
	if ready_to_backup and curr_time - last_input_timestamp > 30.0:
		perform_backup()
	if Input.is_action_just_released("backup_save") and not is_backing_up:
		perform_backup(true)

func perform_backup(manual:bool = false):
	var c_sv:String = game.c_sv
	if Settings.max_backups == 0 or c_sv == "":
		return
	is_backing_up = true
	show()
	var save_dir = DirAccess.open("user://")
	var backup_dir_path = "user://%s/Backups" % [c_sv]
	if not save_dir.dir_exists(backup_dir_path):
		save_dir.make_dir(backup_dir_path)
	
	# Remove oldest backup
	var backup_dir = DirAccess.open(backup_dir_path)
	var files = backup_dir.get_files()
	if len(files) >= Settings.max_backups:
		backup_dir.remove(files[0])
	backup_total_files = Helper.get_directory_properties("user://%s" % c_sv, ["Backups"]).files
	await Helper.export_save(c_sv, backup_dir_path + "/{save_name}_backup_{datetime_string}.hx3".format({
		"save_name": c_sv,
		"datetime_string":Time.get_datetime_string_from_system(),
	}))
	$Timer.start(Settings.backup_interval * 60.0)
	ready_to_backup = false
	is_backing_up = false
	hide()


func _on_timer_timeout() -> void:
	if Settings.backup_with_minimal_interruption:
		ready_to_backup = true
	else:
		perform_backup()
