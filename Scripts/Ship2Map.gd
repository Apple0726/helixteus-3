extends Node2D

@onready var game = get_node("/root/Game")
var dot_scene = preload("res://Graphics/Misc/Dot.png")

func refresh():
	$AnimationPlayer.play("Map fade")
	$Label3.text = str(game.third_ship_hints.ship_sys_id)
	$Label4.text = str(game.third_ship_hints.ship_part_id)
	game.third_ship_hints.g_g_id = game.c_g_g
	var system_data:Array = game.open_obj("Galaxies", game.third_ship_hints.g_g_id)
	var poses:Array = []
	var max_dist:int = 0
	var first_sys_pos:Vector2
	var second_sys_pos:Vector2
	for system in system_data:
		if system.l_id == game.third_ship_hints.ship_sys_id:
			first_sys_pos = system.pos
			poses.append(system.pos)
		if system.l_id == game.third_ship_hints.ship_part_id:
			second_sys_pos = system.pos
			poses.append(system.pos)
		if system.stars[0].size > 1:
			poses.append(system.pos)
		max_dist = max(max_dist, system.pos.length())
	for pos in poses:
		var dot = Sprite2D.new()
		dot.texture = dot_scene
		dot.modulate = Color.GREEN
		add_child(dot)
		dot.position = Vector2(lerp(472, 808, inverse_lerp(-max_dist, max_dist, pos.x)), lerp(192, 528, inverse_lerp(-max_dist, max_dist, pos.y)))
	move_child($Line2D, get_child_count())
	move_child($Line2D2, get_child_count())
	move_child($Line2D3, get_child_count())
	move_child($Line2D4, get_child_count())
	$Line2D.points[1].y = lerp(192, 528, inverse_lerp(-max_dist, max_dist, first_sys_pos.y))
	$Line2D.points[2].x = lerp(472, 808, inverse_lerp(-max_dist, max_dist, first_sys_pos.x))
	$Line2D.points[2].y = $Line2D.points[1].y
	$Line2D2.points[1].y = lerp(192, 528, inverse_lerp(-max_dist, max_dist, second_sys_pos.y))
	$Line2D2.points[0].x = lerp(472, 808, inverse_lerp(-max_dist, max_dist, second_sys_pos.x))
	$Line2D2.points[0].y = $Line2D2.points[1].y


func _on_Ship2Map_tree_exited():
	queue_free()
