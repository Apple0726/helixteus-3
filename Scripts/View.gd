extends KinematicBody2D

onready var game = self.get_parent()
onready var ship:TextureButton = game.get_node("Ship")
var obj
#var shapes = []
var shapes_data = []
var drawing_shape = false#For annotation
var annotate_icon:Sprite
var annotate_icons = []
var line_points = {"start":Vector2.ZERO, "end":Vector2.ZERO}
var limit_to_viewport

var rect:Sprite

#Dragging variables
var dragged = false
var drag_position = Vector2.ZERO
var drag_initial_position = Vector2.ZERO
var drag_delta = Vector2.ZERO

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
	annotate_icon = Sprite.new()
	add_child(annotate_icon)
	rect = Sprite.new()
	rect.texture = load("res://Graphics/Tiles/Highlight.jpg")
	rect.visible = false
	add_child(rect)

func _process(delta):
	if not Input.is_action_pressed("left_click"):
		dragged = false
	if not limit_to_viewport:
		return
	ship.get_node("Fire").visible = game.ships_travel_view != "-"
	if game.ships_travel_view == game.c_v:
		var dep_pos = game.ships_depart_pos
		var dest_pos = game.ships_dest_pos
		var pos:Vector2 = lerp(dep_pos, dest_pos, clamp(Helper.update_ship_travel(), 0, 1))
		if game.ships_travel_view == "-":
			green_line.visible = false
			red_line.visible = false
		else:
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
	if is_instance_valid(game.annotator):
		annotate_icon.position = to_local(mouse_position)
		annotate_icon.modulate = game.annotator.shape_color
		annotate_icon.scale = Vector2.ONE * game.annotator.thickness / 10.0
		if game.annotator.mode == "eraser" and drawing_shape and not game.annotator.mouse_in_panel:
			for icon_data in annotate_icons:
				var icon = icon_data.node
				var size = icon.get_rect().size * icon.scale
				var rect2 = Rect2(-size / 2, size)
				if rect2.has_point(to_local(mouse_position) - icon.position):
					remove_child(icon)
					icon.queue_free()
					annotate_icons.erase(icon_data)
					shapes_data.erase(icon_data.data)
	if is_instance_valid(game.annotator) and game.annotator.visible:
		if Input.is_action_pressed("1"):
			annotate_icon.rotation -= 0.04 * delta * 60
		if Input.is_action_pressed("3"):
			annotate_icon.rotation += 0.04 * delta * 60
		if Input.is_action_just_released("Q"):
			for icon_data in annotate_icons:
				var icon = icon_data.node
				var size = icon.get_rect().size * icon.scale
				var rect2 = Rect2(-size / 2, size)
				if rect2.has_point(to_local(mouse_position) - icon.position):
					game.annotator.shape_color = icon_data.data.color
					game.annotator.get_node("Thickness").value = icon_data.data.scale.x * 10
					game.annotator.on_icon_pressed(load(icon_data.data.texture))
					game.annotator.on_Icons_pressed(true)
					game.annotator.mode == "icon"
					break
	if drawing_shape:
		update()
	if is_instance_valid(obj) and obj.dimensions:
		var margin = obj.dimensions * scale.x
		var right_margin = global_position.x + margin
		var bottom_margin = global_position.y + margin
		if game.c_v == "planet":
			if global_position.x > 1180:
				global_position.x = 1180
			elif right_margin < 100:
				global_position.x = 100 - margin
			if global_position.y > 620:
				global_position.y = 620
			elif bottom_margin < 100:
				global_position.y = 100 - margin
		else:
			var left_margin = global_position.x - margin
			var top_margin = global_position.y - margin
			if left_margin > 1180:
				global_position.x = 1180 + margin
			elif right_margin < 100:
				global_position.x = 100 - margin
			if top_margin > 620:
				global_position.y = 620 + margin
			elif bottom_margin < 100:
				global_position.y = 100 - margin

func _draw():
	if is_instance_valid(game.annotator):
		for shape in shapes_data:
			if shape.shape == "line":
				draw_line(shape.points.start, shape.points.end, shape.color, shape.width, true)
			elif shape.shape == "rect":
				var rect = Rect2(shape.points.start, Vector2.ZERO)
				rect.end = shape.points.end
				draw_rect(rect, shape.color, false, shape.width, true)
			elif shape.shape == "circ":
				draw_arc(shape.points.start, shape.points.end, 0, 2*PI, 100, shape.color, shape.width, true)
		var shift = Input.is_action_pressed("shift")
		if drawing_shape:
			var lmp:Vector2 = to_local(mouse_position)
			var init:Vector2 = to_local(drag_initial_position)
			if game.annotator.mode == "line":
				if shift:
					var angle = atan2(lmp.y - init.y, lmp.x - init.x)
					if abs(angle) < PI / 4 or PI - abs(angle) < PI / 4:
						line_points.end = Vector2(lmp.x, init.y)
					else:
						line_points.end = Vector2(init.x, lmp.y)
				else:
					line_points.end = lmp
				draw_line(line_points.start, line_points.end, game.annotator.shape_color, game.annotator.thickness, true)
			elif game.annotator.mode == "rect":
				var rect = Rect2(line_points.start, Vector2.ZERO)
				rect.end = to_local(mouse_position)
				if shift:
					if rect.size.x > rect.size.y:
						rect.size.y = rect.size.x
					else:
						rect.size.x = rect.size.y
				else:
					rect.end = to_local(mouse_position)
				line_points.end = rect.end
				draw_rect(rect, game.annotator.shape_color, false, game.annotator.thickness, true)
			elif game.annotator.mode == "circ":
				line_points.end = line_points.start.distance_to(lmp)
				draw_arc(line_points.start, line_points.end, 0, 2*PI, 100, game.annotator.shape_color, game.annotator.thickness, true)
			elif game.annotator.mode == "eraser":
				for shape in shapes_data:
					if shape.shape == "line":
						if Geometry.segment_intersects_segment_2d(shape.points.start, shape.points.end, to_local(drag_initial_position), lmp):
							shapes_data.erase(shape)
					elif shape.shape == "rect":
						var top_right = Vector2(shape.points.end.x, shape.points.start.y)
						var bottom_left = Vector2(shape.points.start.x, shape.points.end.y)
						var bool1 = Geometry.segment_intersects_segment_2d(shape.points.start, top_right, to_local(drag_initial_position), lmp)
						var bool2 = Geometry.segment_intersects_segment_2d(top_right, shape.points.end, to_local(drag_initial_position), lmp)
						var bool3 = Geometry.segment_intersects_segment_2d(bottom_left, shape.points.end, to_local(drag_initial_position), lmp)
						var bool4 = Geometry.segment_intersects_segment_2d(shape.points.start, bottom_left, to_local(drag_initial_position), lmp)
						if bool1 or bool2 or bool3 or bool4:
							shapes_data.erase(shape)
					elif shape.shape == "circ":
						if Geometry.segment_intersects_circle(to_local(drag_initial_position), lmp, shape.points.start, shape.points.end) != -1:
							shapes_data.erase(shape)

func refresh():
	if game.c_v == "":
		return
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
	var show_lines = show_ship and game.ships_travel_view == game.c_v and game.ships_travel_view != ""
	red_line.visible = show_lines
	green_line.visible = show_lines
	ship.visible = show_ship and len(game.ship_data) >= 1
	game.move_child(ship, game.get_child_count())
	var progress = Helper.update_ship_travel()
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
	for icon_data in annotate_icons:
		var icon = icon_data.node
		remove_child(icon)
		icon.queue_free()
	annotate_icons.clear()
	yield(get_tree().create_timer(0.0), "timeout")#This yield is needed to display annotations
	if is_instance_valid(game.annotator):
		for i in len(shapes_data):
			var shape = shapes_data[i]
			if shape and shape.shape == "icon":
				var icon = Sprite.new()
				icon.texture = load(shape.texture)
				icon.scale = shape.scale
				icon.modulate = shape.color
				icon.rotation = shape.rotation
				icon.position = shape.position
				annotate_icons.append({"node":icon, "data":shapes_data[i]})
				add_child(icon)

func add_obj(obj_str:String, pos:Vector2, sc:float, s_m:float = 1.0):
	scale_mult = s_m
	scale_dec_threshold = 5 * pow(20, -2 - floor(Helper.log10(s_m)))
	scale_inc_threshold = 5 * pow(20, -1 - floor(Helper.log10(s_m)))
	obj = load("res://Scenes/Views/" + obj_str + ".tscn").instance()
	add_child(obj)
	position = pos
	scale = Vector2(sc, sc)
	position *= sc
	refresh()
	limit_to_viewport = game.c_v in ["universe", "supercluster", "cluster", "galaxy", "system", "planet"]

func remove_obj(obj_str:String, save_zooms:bool = true):
	if save_zooms:
		save_zooms(obj_str)
	game.auto_c_p_g = -1
	self.remove_child(obj)
	obj.queue_free()
	red_line.visible = false
	green_line.visible = false
	annotate_icon.texture = null

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
	if not is_instance_valid(obj):
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
				if is_instance_valid(rsrc):
					rsrc.visible = false
			for hbox in obj.hboxes:
				if not hbox or not is_instance_valid(hbox):
					continue
				hbox.visible = false
			obj.icons_hidden = true
			game.auto_c_p_g = -1
			obj.set_process(false)
		elif scale.x >= 0.25 and obj.icons_hidden:
			for time_bar in obj.time_bars:
				time_bar.node.visible = true
			for rsrc in obj.rsrcs:
				if is_instance_valid(rsrc):
					rsrc.visible = true
			for hbox in obj.hboxes:
				if not hbox or not is_instance_valid(hbox):
					continue
				hbox.visible = true
			obj.icons_hidden = false
			obj.set_process(true)

var dragging:bool = false

#Executed once the receives any kind of input
func _input(event):
	if not event is InputEventMouseMotion:
		if first_zoom and modulate.a == 1:
			first_zoom = false
			zooming = ""
	if scroll_view and not game.block_scroll:
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
		if Input.is_action_just_pressed("left_click") and not game.block_scroll:
			drag_initial_position = event.position
			drag_position = event.position
			dragging = true
			if is_instance_valid(game.annotator) and game.annotator.visible and not game.annotator.mouse_in_panel and game.annotator.mode != "":
				line_points.start = to_local(drag_initial_position)
				drawing_shape = true
		if dragging and Input.is_action_pressed("left_click") and (not is_instance_valid(game.annotator) or not game.annotator.visible):
			drag_delta = event.position - drag_position
			if (event.position - drag_initial_position).length() > 3:
				dragged = true
# warning-ignore:return_value_discarded
			move_and_collide(drag_delta)
			drag_position = event.position
		mouse_position = event.position
		if Input.is_action_just_released("left_click"):
			dragging = false
	if Input.is_action_just_released("left_click") and drawing_shape:
		if game.annotator.mode != "eraser":
			var size
			if game.annotator.mode == "circ":
				size = line_points.end
			elif game.annotator.mode != "icon":
				size = line_points.start.distance_to(line_points.end)
			if game.annotator.mode == "icon" and not game.annotator.mouse_in_panel:
				shapes_data.append({"shape":"icon", "texture":annotate_icon.texture.resource_path, "rotation":annotate_icon.rotation, "scale":annotate_icon.scale, "color":game.annotator.shape_color, "position":annotate_icon.position})
				refresh()
			elif size >= game.annotator.thickness / 3.0:#Prevent players from drawing very thick figures compared to their size, which means they'll have a hard time erasing them
				shapes_data.append({"shape":game.annotator.mode, "width":game.annotator.thickness, "color":game.annotator.shape_color, "points":line_points.duplicate(true)})
		drawing_shape = false
		update()
	if Input.is_action_just_released("right_click") and drawing_shape:
		drawing_shape = false
		update()
	if Input.is_action_just_pressed("2"):
		annotate_icon.rotation = 0

#Zooming code
func _zoom_at_point(zoom_change, center:Vector2 = mouse_position):
	if limit_to_viewport and is_instance_valid(obj) and obj.dimensions and scale.x < 250 / obj.dimensions and zoom_change < 1:
		return
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
