extends ScrollContainer

onready var game = get_node("/root/Game")

func _ready():
	get_v_scrollbar().connect("mouse_entered", self, "on_scroll_mouse_entered")
	get_v_scrollbar().connect("mouse_exited", self, "on_scroll_mouse_exited")
	get_h_scrollbar().connect("mouse_entered", self, "on_scroll_mouse_entered")
	get_h_scrollbar().connect("mouse_exited", self, "on_scroll_mouse_exited")
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func on_scroll_mouse_entered():
	game.view.move_view = false

func on_scroll_mouse_exited():
	game.view.move_view = true

func on_mouse_entered():
	game.view.scroll_view = false

func on_mouse_exited():
	game.view.scroll_view = true
