extends Control


func load_backups(save_name:String):
	$Label.text = tr("BACKUPS_FOR_SAVE").format({"save":save_name})
