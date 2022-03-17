extends Button

signal close_button_pressed
signal close_button_over
signal close_button_out
export var close_button_type = 1
var on_close:String = ""#This function will be called when clicked (used in Game.gd)
onready var game = get_node("/root/Game")

func _on_TextureButton_pressed():
	game.hide_tooltip()
	emit_signal("close_button_pressed")

func _on_TextureButton_mouse_entered():
	emit_signal("close_button_over")
	game.help_str = "close_btn%s" % [close_button_type]
	if not game.help.empty() and game.help.has("close_btn%s" % [close_button_type]):
		game.show_tooltip("%s\n%s" % [tr("CLOSE_BUTTON_DESC%s" % [close_button_type]), tr("HIDE_HELP")])

func _on_TextureButton_mouse_exited():
	emit_signal("close_button_out")
	game.hide_tooltip()
