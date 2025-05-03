extends Control

const C = Vector2(640, 360)
@onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var polygon:PackedVector2Array# = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var tween
var panel_var_name:String

func refresh():
	pass

func set_polygon(v:Vector2, offset:Vector2 = Vector2.ZERO):
	polygon = [offset, offset + Vector2.RIGHT * v.x, offset + v, offset + Vector2.DOWN * v.y]

func _on_close_button_pressed():
	game.toggle_panel(panel_var_name)
	game.active_panel = null

func _input(event):
	if event is InputEventMouseMotion and visible:
		game.block_scroll = Geometry2D.is_point_in_polygon(event.position, polygon)
