extends Control

const C = Vector2(640, 360)
@onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var polygon:PackedVector2Array# = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var tween

func _ready():
	set_process_input(false)
	set_process(false)
	connect("visibility_changed",Callable(self,"set_input"))

func refresh():
	pass

func set_input():
	set_process_input(visible)
	if not visible:
		game.block_scroll = false

func set_polygon(v:Vector2, offset:Vector2 = Vector2.ZERO):
	var w = v.x
	var h = v.y
	polygon = [C - Vector2(w, h) / 2 + offset, C + Vector2(w, -h) / 2 + offset, C + Vector2(w, h) / 2 + offset, C + Vector2(-w, h) / 2 + offset]

func _on_close_button_pressed():
	game.toggle_panel(self)

func _input(event):
	if event is InputEventMouseMotion and visible:
		game.block_scroll = Geometry2D.is_point_in_polygon(event.position, polygon)
