extends CharacterBody2D

@onready var game = get_node("/root/Game")
@onready var ship:TextureButton = game.get_node("Ship")
var obj
#var shapes = []
var shapes_data = []
var drawing_shape = false#For annotation
var annotate_icon:Sprite2D
var annotate_icons = []
var line_points = {"start":Vector2.ZERO, "end":Vector2.ZERO}
var limit_to_viewport
const CLUSTER_SCALE_THRESHOLD:float = 1.0

var rect:Sprite2D

#Dragging variables
var dragged = false
var drag_position = Vector2.ZERO
var drag_initial_position = Vector2.ZERO
var drag_delta = Vector2.ZERO

#Whether the view should be moved when dragging
var move_view = true
#Whether the view should be zoomed when scrolling
var scroll_view = true
#Whether the view should be moved with WASD
var move_with_keyboard = true

#Variables for smoothly moving the tiles
var acceleration = 90
var max_speed = 1000
var friction = 150
var move_speed = Vector2.ZERO

#Variables for zooming smoothly
var zoom_factor = 1.1
var zooming = ""
var progress = 0
var mouse_position = Vector2.ZERO

var dep_pos = null
var dest_pos = null
var curr_pos = null

#Scaling of objects based on zoom level
var obj_scaled:bool = false
var changed:bool = false

func _ready():
	set_process(false)
	refresh()
	annotate_icon = Sprite2D.new()
	add_child(annotate_icon)
	rect = Sprite2D.new()
	rect.texture = preload("res://Graphics/Tiles/Highlight.jpg")
	rect.visible = false
	add_child(rect)

func _process(delta):
	if not Input.is_action_pressed("left_click"):
		dragged = false
	if not limit_to_viewport:
		return
	var travel_view = game.ships_travel_data.travel_view
	ship.get_node("Fire").visible = travel_view != "-"
	if travel_view == game.c_v:
		var scale_mult = 1.0
		if game.c_v == "system":
			scale_mult = 70.0 / game.system_data[game.c_s].closest_planet_distance
		dep_pos = game.ships_travel_data.depart_pos * scale_mult
		dest_pos = game.ships_travel_data.dest_pos * scale_mult
		curr_pos = lerp(dep_pos, dest_pos, clamp(Helper.update_ship_travel(), 0, 1))
		if travel_view == "-":
			dep_pos = null
			dest_pos = null
		else:
			ship.position = to_global(curr_pos) - Vector2(32, 22)
		queue_redraw()
	else:
		dep_pos = null
		dest_pos = null
		var sh_c:Dictionary = game.ships_travel_data.c_coords
		var sh_c_g:Dictionary = game.ships_travel_data.c_g_coords
		if game.c_v == "universe":
			ship.position = to_global(game.u_i.cluster_data[sh_c.c].pos) - Vector2(32, 22)
		elif game.c_v == "cluster" and game.c_c == sh_c.c:
			ship.position = to_global(game.galaxy_data[sh_c.g].pos) - Vector2(32, 22)
		elif game.c_v == "galaxy" and game.c_g_g == sh_c_g.g:
			ship.position = to_global(game.system_data[sh_c.s].pos) - Vector2(32, 22)
		elif game.c_v == "system" and game.c_s_g == sh_c_g.s:
			var scale_mult = 70.0 / game.system_data[game.c_s].closest_planet_distance
			ship.position = to_global(Vector2.from_angle(game.planet_data[sh_c.p].angle) * game.planet_data[sh_c.p].distance * scale_mult) - Vector2(32, 22)
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
					icon.queue_free()
					annotate_icons.erase(icon_data)
					shapes_data.erase(icon_data.data)
		if game.annotator.visible:
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
		queue_redraw()
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
	if game.c_v == "universe":
		game.get_node("StarfieldUniverse").material.set_shader_parameter("position", (position - Vector2(640, 360)) / 20000.0 / sqrt(scale.x))
		if not changed and not $AnimationPlayer.is_playing():
			if obj_scaled and scale.x > CLUSTER_SCALE_THRESHOLD:
				fade_out_clusters()
			elif not obj_scaled and scale.x < CLUSTER_SCALE_THRESHOLD:
				fade_out_clusters()

func fade_out_clusters():
	$AnimationPlayer.play("Fade")
	if Settings.enable_shaders:
		var tween = create_tween()
		tween.set_parallel(true)
		for cluster in obj.btns:
			if is_instance_valid(cluster):
				tween.tween_property(cluster.material, "shader_parameter/alpha", 0.0, 0.4)

func fade_in_clusters():
	$AnimationPlayer.play_backwards("Fade")
	if Settings.enable_shaders:
		var tween = create_tween()
		tween.set_parallel(true)
		for cluster in obj.btns:
			if is_instance_valid(cluster):
				tween.tween_property(cluster.material, "shader_parameter/alpha", 1.0, 0.4)

func _draw():
	if game.c_v == "STM":
		return
	if ship.visible and dest_pos != null and curr_pos != null:
		draw_line(dep_pos, dest_pos, Color.RED)
		draw_line(dep_pos, curr_pos, Color.GREEN)
	if is_instance_valid(game.annotator):
		for shape in shapes_data:
			if shape.shape == "line":
				draw_line(shape.points.start,shape.points.end,shape.color,shape.width)
			elif shape.shape == "rect":
				var rect = Rect2(shape.points.start, Vector2.ZERO)
				rect.end = shape.points.end
				draw_rect(rect,shape.color,false,shape.width)# true) TODOGODOT4 Antialiasing argument is missing
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
				draw_line(line_points.start,line_points.end,game.annotator.shape_color,game.annotator.thickness)
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
				draw_rect(rect,game.annotator.shape_color,false,game.annotator.thickness)# true) TODOGODOT4 Antialiasing argument is missing
			elif game.annotator.mode == "circ":
				line_points.end = line_points.start.distance_to(lmp)
				draw_arc(line_points.start, line_points.end, 0, 2*PI, 100, game.annotator.shape_color, game.annotator.thickness, true)
			elif game.annotator.mode == "eraser":
				for shape in shapes_data:
					if shape.shape == "line":
						if Geometry2D.segment_intersects_segment(shape.points.start, shape.points.end, to_local(drag_initial_position), lmp):
							shapes_data.erase(shape)
					elif shape.shape == "rect":
						var top_right = Vector2(shape.points.end.x, shape.points.start.y)
						var bottom_left = Vector2(shape.points.start.x, shape.points.end.y)
						var bool1 = Geometry2D.segment_intersects_segment(shape.points.start, top_right, to_local(drag_initial_position), lmp)
						var bool2 = Geometry2D.segment_intersects_segment(top_right, shape.points.end, to_local(drag_initial_position), lmp)
						var bool3 = Geometry2D.segment_intersects_segment(bottom_left, shape.points.end, to_local(drag_initial_position), lmp)
						var bool4 = Geometry2D.segment_intersects_segment(shape.points.start, bottom_left, to_local(drag_initial_position), lmp)
						if bool1 or bool2 or bool3 or bool4:
							shapes_data.erase(shape)
					elif shape.shape == "circ":
						if Geometry2D.segment_intersects_circle(to_local(drag_initial_position), lmp, shape.points.start, shape.points.end) != -1:
							shapes_data.erase(shape)

func refresh():
	if game.c_v == "":
		return
	var show_ship = false
	var sh_c:Dictionary = game.ships_travel_data.c_coords
	if game.c_v == "universe":
		show_ship = true
		ship.position = to_global(game.u_i.cluster_data[sh_c.c].pos) - Vector2(32, 22)
	elif game.c_v == "cluster":
		show_ship = game.ships_travel_data.c_coords.c == game.c_c
	elif game.c_v == "galaxy":
		show_ship = game.ships_travel_data.c_g_coords.g == game.c_g_g
	elif game.c_v == "system":
		show_ship = game.ships_travel_data.c_g_coords.s == game.c_s_g
	var travel_view = game.ships_travel_data.travel_view
	var show_lines = show_ship and travel_view == game.c_v and travel_view != ""
	ship.visible = show_ship and len(game.ship_data) >= 1
	game.move_child(ship, game.get_child_count())
	var progress = Helper.update_ship_travel()
	travel_view = game.ships_travel_data.travel_view
	if travel_view == "-":
		ship.mouse_filter = TextureButton.MOUSE_FILTER_IGNORE
	else:
		ship.mouse_filter = TextureButton.MOUSE_FILTER_STOP
	if show_lines:
		var scale_mult = 1.0
		if game.c_v == "system":
			scale_mult = 70.0 / game.system_data[game.c_s].closest_planet_distance
		dep_pos = game.ships_travel_data.depart_pos * scale_mult
		dest_pos = game.ships_travel_data.dest_pos * scale_mult
		curr_pos = dest_pos
		if dest_pos.x < dep_pos.x:
			ship.scale.x = -1
		else:
			ship.scale.x = 1
	for icon_data in annotate_icons:
		var icon = icon_data.node
		icon.queue_free()
	annotate_icons.clear()
	await get_tree().create_timer(0.0).timeout#This yield is needed to display annotations
	if is_instance_valid(game.annotator):
		for i in len(shapes_data):
			var shape = shapes_data[i]
			if shape and shape.shape == "icon":
				var icon = Sprite2D.new()
				icon.texture = load(shape.texture)
				icon.scale = shape.scale
				icon.modulate = shape.color
				icon.rotation = shape.rotation
				icon.position = shape.position
				annotate_icons.append({"node":icon, "data":shapes_data[i]})
				add_child(icon)
	queue_redraw()

func add_obj(obj_str:String, pos:Vector2, sc:float, s_m:float = 1.0):
	#scale_dec_threshold = 5 * pow(20, -2 - floor(Helper.log10(s_m)))
	#scale_inc_threshold = 5 * pow(20, -1 - floor(Helper.log10(s_m)))
	obj = load("res://Scenes/Views/" + obj_str + ".tscn").instantiate()
	add_child(obj)
	position = pos
	scale = Vector2(sc, sc)
	obj_scaled = scale.x < 1.5
	refresh()
	limit_to_viewport = game.c_v in ["universe", "cluster", "galaxy", "system", "planet"]

func remove_obj(obj_str:String, save_zooms:bool = true):
	if save_zooms:
		save_zooms(obj_str)
	obj.set_process(false)
	obj.queue_free()
	annotate_icon.texture = null
	queue_redraw()

func save_zooms(obj_str:String):
	match obj_str:
		"planet":
			game.planet_data[game.c_p]["view"]["pos"] = self.position# / self.scale.x
			game.planet_data[game.c_p]["view"]["zoom"] = self.scale.x
		"system":
			game.system_data[game.c_s].view.pos = self.position# / self.scale.x
			game.system_data[game.c_s].view.zoom = self.scale.x
		"galaxy":
			game.galaxy_data[game.c_g].view.pos = self.position# / self.scale.x
			game.galaxy_data[game.c_g].view.zoom = self.scale.x
		"cluster":
			if game.u_i.cluster_data[game.c_c].has("view"):
				game.u_i.cluster_data[game.c_c]["view"]["pos"] = self.position# / self.scale.x
				game.u_i.cluster_data[game.c_c]["view"]["zoom"] = self.scale.x
		"universe":
			game.universe_data[game.c_u]["view"]["pos"] = self.position# / self.scale.x
			game.universe_data[game.c_u]["view"]["zoom"] = self.scale.x
			#game.universe_data[game.c_u]["view"]["sc_mult"] = scale_mult
		"science_tree":
			game.science_tree_view.pos = position# / scale.x
			game.science_tree_view.zoom = scale.x

var first_zoom:bool = false
#Executed every tick
func _physics_process(_delta):
	if not is_instance_valid(obj):
		return
	if move_with_keyboard:
		#Moving tiles code
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("A") - Input.get_action_strength("D")
		input_vector.y = Input.get_action_strength("W") - Input.get_action_strength("S")
		input_vector = input_vector.normalized()
		if input_vector != Vector2.ZERO:
			move_speed = move_speed.move_toward(input_vector * max_speed, acceleration)
		else:
			move_speed = move_speed.move_toward(Vector2.ZERO, friction)
		set_velocity(move_speed)
		move_and_slide()
		move_speed = move_speed

	#Zooming animation
	if zooming == "in":
		if first_zoom:
			_zoom_at_point(-ease(progress, 0.1) * (zoom_factor - 1) + zoom_factor, Vector2(640, 320))
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
			obj.timer.wait_time = 1.0
			if not get_tree().get_nodes_in_group("tile_bonus_nodes").is_empty():
				for tile_bonus_node in get_tree().get_nodes_in_group("tile_bonus_nodes"):
					var tween = create_tween()
					tween.set_parallel(true)
					tween.tween_property(tile_bonus_node, "color:a", 0.6, 0.1)
					tween.tween_property(tile_bonus_node.get_node("TileBonus"), "modulate:a", 0.0, 0.1)
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
			obj.timer.wait_time = 0.1
			if not get_tree().get_nodes_in_group("tile_bonus_nodes").is_empty():
				for tile_bonus_node in get_tree().get_nodes_in_group("tile_bonus_nodes"):
					var tween = create_tween()
					tween.set_parallel(true)
					tween.tween_property(tile_bonus_node, "color:a", 0.0, 0.1)
					tween.tween_property(tile_bonus_node.get_node("TileBonus"), "modulate:a", 1.0, 0.1)

var dragging:bool = false
var touch_events = {}
var target_return_enabled = true
var target_return_rate = 0.02
var min_zoom = 0.5
var max_zoom = 2
var zoom_sensitivity = 10
var zoom_speed = 0.05

var last_drag_distance = 0

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_events[event.index] = event
		else:
			touch_events.erase(event.index)
	if event is InputEventScreenDrag:
		touch_events[event.index] = event
		if touch_events.size() == 1:
			position += event.relative
		elif touch_events.size() == 2:
			var drag_distance = touch_events[0].position.distance_to(touch_events[1].position)
			var touch_center = (touch_events[0].position + touch_events[1].position) / 2.0
			if abs(drag_distance - last_drag_distance) > zoom_sensitivity:
				if drag_distance > last_drag_distance:
					zooming = "in"
					progress = 0
				else:
					zooming = "out"
					progress = 0
				last_drag_distance = drag_distance

#Executed once the receives any kind of input
func _input(event):
	if not event is InputEventMouseMotion:
		if first_zoom and modulate.a == 1:
			first_zoom = false
			zooming = ""
	if scroll_view and not game.block_scroll:
		if event.is_action_released("scroll_down"):
			zoom_factor = 1.1
			zooming = "out"
			progress = 0
			#check_change_scale()
		elif event.is_action_released("scroll_up"):
			zoom_factor = 1.1
			zooming = "in"
			progress = 0
			#check_change_scale()
	if (event is InputEventMouse or event is InputEventScreenTouch):
		if Input.is_action_just_pressed("left_click") and not game.block_scroll:
			drag_initial_position = event.position
			drag_position = event.position
			dragging = true
			if is_instance_valid(game.annotator) and game.annotator.visible and not game.annotator.mouse_in_panel and game.annotator.mode != "":
				line_points.start = to_local(drag_initial_position)
				drawing_shape = true
		if move_view and dragging and Input.is_action_pressed("left_click") and (not is_instance_valid(game.annotator) or not game.annotator.visible):
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
		queue_redraw()
	if Input.is_action_just_released("right_click") and drawing_shape:
		drawing_shape = false
		queue_redraw()
	if Input.is_action_just_pressed("2"):
		annotate_icon.rotation = 0

#Zooming code
func _zoom_at_point(zoom_change, center:Vector2 = mouse_position):
	if limit_to_viewport and is_instance_valid(obj) and obj.dimensions and scale.x < 250 / obj.dimensions and zoom_change < 1: #max zoom out
		return
	if game.c_v == "planet":
		if is_instance_valid(obj) and obj.dimensions and scale.x >= 10000 / obj.dimensions and zoom_change > 1: #max zoom in
			return
	elif game.c_v == "universe":
		if scale.x >= 25.0 and zoom_change > 1: #max zoom in
			return
	scale = scale * zoom_change
	var delta_x = (center.x - global_position.x) * (zoom_change - 1)
	var delta_y = (center.y - global_position.y) * (zoom_change - 1)
	global_position.x -= delta_x
	global_position.y -= delta_y

func _on_AnimationPlayer_animation_finished(anim_name):
	if not changed:
		if scale.x < CLUSTER_SCALE_THRESHOLD:
			obj_scaled = true
			obj.change_scale(1.0)
		else:
			obj_scaled = false
			obj.change_scale(0.1)
		changed = true
		fade_in_clusters()
	else:
		changed = false
