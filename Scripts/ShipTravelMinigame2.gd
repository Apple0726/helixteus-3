extends Node2D

func _ready():
	Helper.set_back_btn($Control/Back)

var mouse_pos:Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position

func _process(delta):
	$Ship.position = mouse_pos

func _on_enemy_spawn_timer_timeout():
	var HX:STMHX = preload("res://Scenes/STM/STMHX.tscn").instantiate()
	HX.scale = Vector2.ONE * randf_range(0.25, 0.4)
	HX.get_node("Sprite2D").material.set_shader_parameter("frequency", remap(HX.scale.x, 0.25, 0.4, 6.2, 5.8))
	add_child(HX)
