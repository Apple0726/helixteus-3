extends Control

const C = Vector2(640, 360)
onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var polygon:PoolVector2Array# = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]

func _ready():
	tween = Tween.new()
	add_child(tween)
	set_process_input(false)
	connect("visibility_changed", self, "set_input")

func refresh():
	pass

func set_input():
	set_process_input(visible)
	if not visible:
		game.block_scroll = false

func set_polygon(v:Vector2):
	var w = v.x
	var h = v.y
	polygon = [C - Vector2(w, h) / 2, C + Vector2(w, -h) / 2, C + Vector2(w, h) / 2, C + Vector2(-w, h) / 2]

func _on_close_button_pressed():
	game.toggle_panel(self)

func _input(event):
	if event is InputEventMouseMotion:
		game.block_scroll = Geometry.is_point_in_polygon(event.position, polygon)
