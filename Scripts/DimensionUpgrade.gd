extends PanelContainer
onready var game = get_node("/root/Game")

func _on_Label_mouse_entered():
	game.show_tooltip(tr($VBoxContainer/Label.text + "_DESC"))

func _on_Label_mouse_exited():
	game.hide_tooltip()
