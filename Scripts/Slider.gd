extends Control
#Contains code that prevents moving view when dragging with mouse
onready var game = get_node("/root/Game")

func _ready():
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func on_mouse_entered():
	game.view.move_view = false

func on_mouse_exited():
	game.view.move_view = true
