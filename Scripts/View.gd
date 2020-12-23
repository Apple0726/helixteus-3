extends KinematicBody2D

onready var game = self.get_parent()
var obj_scene
var obj
onready var ship = $Ship

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
		move_child(red_line, get_child_count())
		move_child(green_line, get_child_count())
		var dep_pos = game.ships_depart_pos
		var dest_pos = game.ships_dest_pos
		var progress:float = (OS.get_system_time_msecs() - game.ships_travel_start_date) / float(game.ships_travel_length)
		var pos:Vector2 = lerp(dep_pos, dest_pos, clamp(progress, 0, 1))
		green_line.points[1] = pos
		ship.rect_position = pos - Vector2(50, 25)
		if progress >= 1:
			game.ships_travel_view = "-"
			game.ships_c_p = game.ships_dest_p_id

func refresh():
	var show_lines = game.ships_travel_view == game.c_v
	red_line.visible = show_lines
	green_line.visible = show_lines
	ship.visible = show_lines
	if show_lines:
		var v = game.ships_travel_view
		var dep_pos:Vector2 = game.ships_depart_pos
		var dest_pos:Vector2 = game.ships_dest_pos
		red_line.points[0] = dep_pos
		green_line.points[0] = dep_pos
		red_line.points[1] = dest_pos
		if dest_pos.x < dep_pos.x:
			ship.rect_scale.x = -0.2
		else:
			ship.rect_scale.x = 0.2

func add_obj(obj_str:String, pos:Vector2, sc:float, s_m:float = 1.0):
	scale_mult = s_m
	scale_dec_threshold = 5 * pow(10, -2 - floor(Helper.log10(s_m)))
	scale_inc_threshold = 5 * pow(10, -1 - floor(Helper.log10(s_m)))
	obj_scene = load("res://Scenes/Views/" + obj_str + ".tscn")
	obj = obj_scene.instance()
	add_child(obj)
	position = pos
	scale = Vector2(sc, sc)
	position *= sc
	refresh()

func remove_obj(obj_str:String):
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
	self.remove_child(obj)
	obj_scene = null
	obj = null
	red_line.visible = false
	green_line.visible = false
	ship.visible = false

#Executed every tick
func _physics_process(_delta):
	#Moving tiles code
	var input_vector = Vector2.ZERO
	if OS.get_latin_keyboard_variant() == "QWERTY":
		input_vector.x = Input.get_action_strength("A") - Input.get_action_strength("D")
		input_vector.y = Input.get_action_strength("W") - Input.get_action_strength("S")
	elif OS.get_latin_keyboard_variant() == "AZERTY":
		input_vector.x = Input.get_action_strength("Q") - Input.get_action_strength("D")
		input_vector.y = Input.get_action_strength("Z") - Input.get_action_strength("S")
	input_vector = input_vector.normalized()
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction)
	velocity = move_and_slide(velocity)
	
	#Zooming animation
	if zooming == "in":
		_zoom_at_point(-ease(progress, 0.1) * (zoom_factor - 1) + zoom_factor)
		progress += 0.03
	if zooming == "out":
		_zoom_at_point(ease(progress, 0.1) * (1 - 1 / zoom_factor) + 1 / zoom_factor)
		progress += 0.03
	if progress >= 1:
		zooming = ""
		progress = 0

#Dragging variables
var dragged = false
var drag_position = Vector2.ZERO
var drag_initial_position = Vector2.ZERO
var drag_delta = Vector2.ZERO

#Executed once the receives any kind of input
func _input(event):
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
			if (event.position - drag_initial_position).length() > 2:
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
	if game.c_v != "supercluster" and game.c_v != "universe":
		return
	if scale_inc_threshold < 50 and scale.x > scale_inc_threshold:
		obj.modulate.a = 0.95
		obj.change_alpha = -0.05
		scale_dec_threshold = scale_inc_threshold
		scale_inc_threshold *= 10
		scale_mult *= 0.1
	if scale_dec_threshold > 0.1 and scale.x < scale_dec_threshold:
		obj.modulate.a = 0.95
		obj.change_alpha = -0.05
		scale_inc_threshold = scale_dec_threshold
		scale_dec_threshold /= 10.0
		scale_mult *= 10

func _on_Ship_mouse_entered():
	game.show_tooltip("")
	update_tooltip()

func update_tooltip():
	if game.tooltip.visible:
		show_tooltip("%s: %s\n%s" % [tr("TIME_LEFT"), Helper.time_to_str(game.ships_travel_length - OS.get_system_time_msecs() + game.ships_travel_start_date), tr("PLAY_SHIP_MINIGAME")])
		yield(get_tree().create_timer(0.02), "timeout")
		update_tooltip()

func show_tooltip(txt:String):
	var tooltip = game.tooltip
	tooltip.autowrap = true
	tooltip.text = txt
	tooltip.rect_size.x = 400

func hide_tooltip():
	game.tooltip.visible = false

func _on_Ship_mouse_exited():
	hide_tooltip()

func _on_Ship_pressed():
	game.switch_view("STM")#Ship travel minigame
