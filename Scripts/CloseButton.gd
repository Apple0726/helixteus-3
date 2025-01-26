extends Button

signal close_button_pressed
signal close_button_over
signal close_button_out
@export var close_button_type = 1
var on_close:String = ""#This function will be called when clicked (used in Game.gd)
@onready var game = get_node("/root/Game")

func _on_TextureButton_pressed():
	game.hide_tooltip()
	emit_signal("close_button_pressed")

func _on_TextureButton_mouse_entered():
	emit_signal("close_button_over")

func _on_TextureButton_mouse_exited():
	emit_signal("close_button_out")
	game.hide_tooltip()
