extends Control
signal double_click

onready var game = get_node("/root/Game")
var is_over = false

func _input(event):
	if game.c_v == "dimension":
		if event is InputEventMouseButton and Input.is_action_just_pressed("left_click"):
			if event.doubleclick and is_over:
				emit_signal("double_click")

func on_univ_over():
	is_over = true
	game.show_tooltip(tr("UNIVERSE_INFO"))

func on_univ_out():
	is_over = false
	game.hide_tooltip()
