extends Panel
signal delete_save

@onready var game = get_node("/root/Game")

func _on_close_button_pressed():
	get_node("../PopupBackground").visible = false
	visible = false


func _on_Delete_pressed():
	emit_signal("delete_save")
