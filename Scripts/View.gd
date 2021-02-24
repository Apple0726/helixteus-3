extends KinematicBody2D

onready var game = self.get_parent()
onready var ship:TextureButton = game.get_node("Ship")
var obj_scene
var obj

#Whether the view should be moved when dragging
var move_view = true
#Whether the view should be zoomed when scrolling
var scroll_view = true

#Variables for smoothly moving the tiles
var acceleration = 90
var max_speed = 1000
var friction = 150
var velocity = Vector2.ZERO

#Variables for zooming smoothly
var zoom_factor = 1.1
var zooming = ""
var progress = 0
var mouse_position = Vector2.ZERO

var red_line:Line2D
var green_line:Line2D

func _ready():
	set_process(false)
	red_line = Line2D.new()
	add_child(red_line)
	red_line.add_point(Vector2.ZERO)
	red_line.add_point(Vector2.ZERO)
	red_line.width = 1
	red_line.default_color = Color.red
	red_line.antialiased = true
	green_line = Line2D.new()
	green_line.visible = false
	add_child(green_line)
	green_line.add_point(Vector2.ZERO)
	green_line.add_point(Vector2.ZERO)
	green_line.width = 1
	green_line.default_color = Color.green
	green_line.antialiased = true
	refresh()

func _process(_delta):
	if not Input.is_action_pressed("left_click"):
		dragged = false
	if game.ships_travel_view == game.c_v:
		var dep_pos = game.ships_depart_pos
		var dest_pos = game.ships_dest_pos
		var pos:Vector2 = lerp(dep_pos, dest_pos, clamp(Helper.update_ship_travel(), 0, 1))
		green_line.points[1] = pos
		ship.rect_position = to_global(pos) - Vector2(32, 22)
	else:
		var sh_c:Dictionary = game.ships_c_coords
		var sh_c_g:Dictionary = game.ships_c_g_coords
		if game.c_v == "universe":
			ship.rect_position = to_global(game.supercluster_data[sh_c.sc].pos) - Vector2(32, 22)
		if game.c_v == "supercluster":
			ship.rect_position = to_global(game.cluster_data[sh_c.c].pos) - Vector2(32, 22)
		elif game.c_v == "cluster" and game.c_c_g == sh_c_g.c:
			ship.rect_position = to_global(game.galaxy_data[sh_c.g].pos) - Vector2(32, 22)
		elif game.c_v == "galaxy" and game.c_g_g == sh_c_g.g:
			ship.rect_position = to_global(game.system_data[sh_c.s].pos) - Vector2(32, 22)
		elif game.c_v == "system" and game.c_s_g == sh_c_g.s:
			ship.rect_position = to_global(polar2cartesian(game.planet_data[sh_c.p].distance, game.planet_data[sh_c.p].angle)) - Vector2(32, 22)

func refresh():
	var show_ship = false
	var sh_c:Dictionary = game.ships_c_coords
	if game.c_v == "universe":
		show_ship = true
		ship.rect_position = to_global(game.supercluster_data[sh_c.sc].pos) - Vector2(32, 22)
	if game.c_v == "supercluster":
		show_ship = game.ships_c_coords.sc == game.c_sc
	elif game.c_v == "cluster":
		show_ship = game.ships_c_g_coords.c == game.c_c_g
	elif game.c_v == "galaxy":
		show_ship = game.ships_c_g_coords.g == game.c_g_g
	elif game.c_v == "system":
		show_ship = game.ships_c_g_coords.s == game.c_s_g
	var show_lines = show_ship and game.ships_travel_view == game.c_v
	red_line.visible = show_lines
	green_line.visible = show_lines
	ship.visible = show_ship and len(game.ship_data) >= 1
	game.move_child(ship, game.get_child_count())
	if game.ships_travel_view == "-":
		ship.mouse_filter = TextureButton.MOUSE_FILTER_IGNORE
	else:
		ship.mouse_filter = TextureButton.MOUSE_FILTER_STOP
	if show_lines:
		move_child(red_line, get_child_count())
		move_child(green_line, get_child_count())
		var v = game.ships_travel_view
		var dep_pos:Vector2 = game.ships_depart_pos
		var dest_pos:Vector2 = game.ships_dest_pos
		red_line.points[0] = dep_pos
		green_line.points[0] = dep_pos
		red_line.points[1] = dest_pos
		if dest_pos.x < dep_pos.x:
			ship.rect_scale.x = -1
		else:
			ship.rect_scale.x = 1

func add_obj(obj_str:String, pos:Vector2, sc:float, s_m:float = 1.0):
	scale_mult = s_m
	scale_dec_threshold = 5 * pow(20, -2 - floor(Helper.log10(s_m)))
	scale_inc_threshold = 5 * pow(20, -1 - floor(Helper.log10(s_m)))
	obj_scene = load("res://Scenes/Views/" + obj_str + ".tscn")
	obj = obj_scene.instance()
	add_child(obj)
	position = pos
	scale = Vector2(sc, sc)
	position *= sc
	refresh()

func remove_obj(obj_str:String, save_zooms:bool = true):
	if save_zooms:
		save_zooms(obj_str)
	self.remove_child(obj)
	obj_scene = null
	obj = null
	red_line.visible = false
	green_line.visible = false

func save_zooms(obj_str:String):
	match obj_str:
		"planet":
			game.planet_data[game.c_p]["view"]["pos"] = self.position / self.scale.x
			game.planet_data[game.c_p]["view"]["zoom"] = self.scale.x
		"system":
			game.system_data[game.c_s]["view"]["pos"] = self.position / self.scale.x
			game.system_data[game.c_s]["view"]["zoom"] = self.scale.x
		"galaxy":
			game.galaxy_data[game.c_g]["view"]["pos"] = self.position / self.scale.x
			game.galaxy_data[game.c_g]["view"]["zoom"] = self.scale.x
		"cluster":
			game.cluster_data[game.c_c]["view"]["pos"] = self.position / self.scale.x
			game.cluster_data[game.c_c]["view"]["zoom"] = self.scale.x
		"supercluster":
			game.supercluster_data[game.c_sc]["view"]["pos"] = self.position / self.scale.x
			game.supercluster_data[game.c_sc]["view"]["zoom"] = self.scale.x
			game.supercluster_data[game.c_sc]["view"]["sc_mult"] = scale_mult
		"universe":
			game.universe_data[game.c_u]["view"]["pos"] = self.position / self.scale.x
			game.universe_data[game.c_u]["view"]["zoom"] = self.scale.x
			game.universe_data[game.c_u]["view"]["sc_mult"] = scale_mult
		"science_tree":
			game.science_tree_view.pos = position / scale.x
			game.science_tree_view.zoom = scale.x

var first_zoom:bool = false
#Executed every tick
func _physics_process(_delta):
	if not obj:
		return
	#Moving tiles code
	var input_vector = Vector2.ZERO
	if OS.get_latin_keyboard_variant() == "AZERTY":
		input_vector.x = Input.get_action_strength("Q") - Input.get_action_strength("D")
		input_vector.y = Input.get_action_strength("Z") - Input.get_action_strength("S")
	else:
		input_vector.x = Input.get_action_strength("A") - Input.get_action_strength("D")
		input_vector.y = Input.get_action_strength("W") - Input.get_action_strength("S")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
	velocity = move_and_slide(velocity)
	
	#Zooming animation
	if zooming == "in":
		if first_zoom:
			_zoom_at_point(-ease(progress, 0.1) * (zoom_factor - 1) + zoom_factor, Vector2(640, 200))
			progress += 0.002
			modulate.a = min(1, modulate.a + 0.01)
		else:
			_zoom_at_point(-ease(progress, 0.1) * (zoom_factor - 1) + zoom_factor)
			progress += 0.03
	if zooming == "out":
		_zoom_at_point(ease(progress, 0.1) * (1 - 1 / zoom_factor) + 1 / zoom_factor)
		progress += 0.03
	if progress >= 1.0:
		first_zoom = false
		zooming = ""
		progress = 0
	if game.c_v == "planet":
		if scale.x < 0.25 and not obj.icons_hidden:
			for time_bar in obj.time_bars:
				time_bar.node.visible = false
			for rsrc in obj.rsrcs:
				rsrc.node.visible = false
			for hbox in obj.hboxes:
				if not hbox:
					continue
				hbox.visible = false
			obj.icons_hidden = true
			obj.set_process(false)
		elif scale.x >= 0.25 and obj.icons_hidden:
			for time_bar in obj.time_bars:
				time_bar.node.visible = true
			for rsrc in obj.rsrcs:
				rsrc.node.visible = true
			for hbox in obj.hboxes:
				if not hbox:
					continue
				hbox.visible = true
			obj.icons_hidden = false
			obj.set_process(true)

#Dragging variables
var dragged = false
var drag_position = Vector2.ZERO
var drag_initial_position = Vector2.ZERO
var drag_delta = Vector2.ZERO

#Executed once the receives any kind of input
func _input(event):
	if not event is InputEventMouseMotion:
		if first_zoom and modulate.a == 1:
			first_zoom = false
			zooming = ""
	if scroll_view:
		if event.is_action_released("scroll_down"):
			if event is InputEventMouse:
				zoom_factor = 1.1
			else:
				zoom_factor = 1.2
			zooming = "out"
			progress = 0
			check_change_scale()
		elif event.is_action_released("scroll_up"):
			if event is InputEventMouse:
				zoom_factor = 1.1
			else:
				zoom_factor = 1.2
			zooming = "in"
			progress = 0
			check_change_scale()
	if event is InputEventMouse and move_view:
		if Input.is_action_just_pressed("left_click"):
			drag_initial_position = event.position
			drag_position = event.position
		if Input.is_action_pressed("left_click"):
			drag_delta = event.position - drag_position
			if (event.position - drag_initial_position).length() > 3:
				dragged = true
# warning-ignore:return_value_discarded
			move_and_collide(drag_delta)
			drag_position = event.position
		mouse_position = event.position

#Zooming code
func _zoom_at_point(zoom_change, center:Vector2 = mouse_position):
	scale = scale * zoom_change
	var delta_x = (center.x - global_position.x) * (zoom_change - 1)
	var delta_y = (center.y - global_position.y) * (zoom_change - 1)
	global_position.x -= delta_x
	global_position.y -= delta_y

#Scaling of objects based on zoom level
var scale_inc_threshold
var scale_dec_threshold
var scale_mult
func check_change_scale():
	if game.c_v in ["supercluster", "universe"]:
		if scale_inc_threshold < 3 and scale.x > scale_inc_threshold:
			obj.modulate.a = 0.95
			obj.change_alpha = -0.05
			scale_dec_threshold = scale_inc_threshold
			scale_inc_threshold *= 20
			scale_mult *= 0.1
		if scale_dec_threshold > 0.1 and scale.x < scale_dec_threshold:
			obj.modulate.a = 0.95
			obj.change_alpha = -0.05
			scale_inc_threshold = scale_dec_threshold
			scale_dec_threshold /= 20.0
			scale_mult *= 10
