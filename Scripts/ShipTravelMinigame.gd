extends Control

onready var star_scene = preload("res://Scenes/Decoratives/Star.tscn")
onready var bullet_texture = preload("res://Graphics/Misc/bullet.png")

onready var game = get_node("/root/Game")
onready var ship = $Ship
onready var acc_time = $AccTime
onready var point = $Point
onready var red_flash = $RedFlash
var secs_elapsed:int = 0
var move_ship_inst:bool = false
var help_tween:Tween
var fn_to_call:String = ""
var penalty_time:int = 0 #miliseconds
var lv:int #minigame level
var no_hit_combo:int = 0
var got_hit:bool = false
var lvpatterns:Array = [[1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11, 12], [13, 14, 15, 16, 17, 18]] #contains all level patterns
var pattern:int = 1

func set_level():
	$Timer.wait_time = 1.0 / lv
	$Level.text = "%s %s" % [tr("LEVEL"), lv]
	
func _ready():
	if game:
		lv = game.STM_lv
	else:
		lv = 4
	help_tween = Tween.new()
	add_child(help_tween)
	set_level()
	var tween:Tween = Tween.new()
	tween.interpolate_property($Level, "modulate", null, Color.white, 0.5)
	add_child(tween)
	tween.start()

	for i in 100: #number of stars to render
		var star = star_scene.instance()
		star.scale *= rand_range(0.02, 0.05)
		star.rotation = rand_range(0, 2 * PI)
		add_child(star)
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		star.add_to_group("stars")

	if not game or game.help.STM:
		if lv % 4 == 0:
			fn_to_call = "graph_pattern"
		else:
			fn_to_call = "pattern_%s" % pattern
		$Help.visible = true
		show_help(tr("MOVE_SHIP_WITH_MOUSE"))
	if game and not game.help.STM:
		var n:int = len(lvpatterns[lv - 1]) - 1
		call("pattern_%s" % [lvpatterns[lv - 1][Helper.rand_int(0, n)]])
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func show_help(st:String):
	$Help.text = "%s (%s)" % [st, tr("CLICK_ANYWHERE_TO_CONTINUE")]
	help_tween.interpolate_property($Help, "modulate", null, Color.white, 0.5)
	help_tween.interpolate_property($Help, "rect_position", Vector2(192, 332), Vector2(192, 317), 0.5)
	help_tween.start()
	ship.modulate.a = 1.0
	$Timer.paused = true

func hide_help():
	if game and game.settings.visible:
		return
	set_process(true)
	help_tween.interpolate_property($Help, "modulate", Color.white, Color(1, 1, 1, 0), 0.5)
	help_tween.interpolate_property($Help, "rect_position", null, $Help.rect_position + Vector2(0, 30), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
	help_tween.start()
	$Timer.paused = false
	if fn_to_call != "":
		call(fn_to_call)
		fn_to_call = ""
	ship.modulate.a = 0.5
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_Back_pressed():
	game.STM_lv = lv
	game.ships_travel_start_date -= max(0, secs_elapsed * 1000 - penalty_time)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game.switch_view("a")

var mouse_pos:Vector2 = Vector2.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	if Input.is_action_just_released("left_click") and $Help.modulate == Color.white:
		hide_help()
	Helper.set_back_btn($Back)

func go_up_lv():
	lv += 1
	no_hit_combo = 0
	show_help(tr("STM_LEVEL_%s" % [lv]))
	set_level()

func process_1(bullet, delta):
	bullet.position.x -= 6 * delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_2"}

func process_2(bullet, delta):
	bullet.position.x -= 4 * delta
	bullet.position.y -= bullet_data[bullet.name].i / 3.0 * delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_3"}

func process_3(bullet, delta):
	bullet.position.x -= 8 * delta
	bullet.scale += Vector2(0.01, 0.01)
	var rand = bullet_data[bullet.name].rand
	if rand:
		bullet.position.y += delta
	else:
		bullet.position.y -= delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_4"}

func process_4(bullet, delta):
	if bullet_data[bullet.name].has("b_type"):
		bullet.position.x -= 5 * delta
	else:
		bullet.position.x -= 4 * delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_%s" % [Helper.rand_int(5, 7)]}

func process_5(bullet, delta):
	bullet.position.x += 5 * cos(bullet.rotation) * delta
	bullet.position.y += 5 * sin(bullet.rotation) * delta
	var cond = bullet.position.x < -25 or bullet.position.y < -20 or bullet.position.y > 740
	return {"remove":cond, "fn":"pattern_%s" % [[4, 6, 7][Helper.rand_int(0, 2)]]}

func process_6(bullet, delta):
	bullet.position.x -= pow(1351 - bullet.position.x, 0.45) * delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_%s" % [[4, 5, 7][Helper.rand_int(0, 2)]]}

func process_7(bullet, delta):
	bullet.position.x -= 3 * (2.5 - bullet.scale.x) * delta
	return {"remove":bullet.position.x < -25, "fn":"pattern_%s" % [[4, 5, 6][Helper.rand_int(0, 2)]]}

func process_8(bullet, delta):
	var dir = bullet_data[bullet.name].dir
	var cond:bool#condition for bullet removal
	var spd:float = 10.0 * delta
	if dir == "r":
		bullet.position.x -= spd * 1.5
		cond = bullet.position.x < -25
	elif dir == "l":
		bullet.position.x += spd * 1.5
		cond = bullet.position.x > -1305
	elif dir == "u":
		bullet.position.y += spd
		cond = bullet.position.y > 745
	else:
		bullet.position.y -= spd
		cond = bullet.position.y < -25
	return {"remove":cond, "fn":"pattern_%s" % [[9, 10, 11, 12][Helper.rand_int(0, 3)]]}

func process_9(bullet, delta):
	var b_type = bullet_data[bullet.name].b_type
	var cond:bool#condition for bullet removal
	var cond2:bool = false#condition for bullet removal
	var spd:float = 10.0
	if b_type == "b":
		cond = bullet.position.y > 740
	elif b_type == "b2":
		cond = bullet.position.y < -20
		cond2 = bullet.position.y < 700
	elif b_type == "b3":
		cond = bullet.position.y < -20
		cond2 = bullet.position.y < 650
	else:
		cond = bullet.position.y > 740
		cond2 = bullet.position.y > 30
	if cond2:
		bullet_data[bullet.name].spd *= 1.01
	bullet.position += bullet_data[bullet.name].spd * delta
	return {"remove":cond, "fn":"pattern_%s" % [[8, 10, 11, 12][Helper.rand_int(0, 3)]]}

func process_10(bullet, delta):
	var b_type = bullet_data[bullet.name].b_type
	var cond:bool = false#condition for bullet removal
	var spd:float = 10.0
	bullet.position += bullet_data[bullet.name].speed * delta
	bullet_data[bullet.name].speed += bullet_data[bullet.name].acceleration * delta
	if bullet.position.y > 740 or bullet.position.y < -20:
		cond = true
	return {"remove":cond, "fn":"pattern_%s" % [[8, 9, 11, 12][Helper.rand_int(0, 3)]]}

func process_11(bullet, delta):
	bullet.position += bullet_data[bullet.name].speed * delta
	var cond:bool = not Geometry.is_point_in_polygon(bullet.position, playfield)
	return {"remove":cond, "fn":"pattern_%s" % [[8, 9, 10, 12][Helper.rand_int(0, 3)]]}

func process_12(bullet, delta):
	var cond:bool = false
	if bullet_data[bullet.name].has("b_type"):
		if bullet_data[bullet.name].b_type == "b":
			bullet.position.x = int(bullet_data[bullet.name].t) % 1280
		elif bullet_data[bullet.name].b_type == "c":
			bullet.position.x = 1280 - int(bullet_data[bullet.name].t) % 1280
		bullet.position.y = -100 * sin(bullet.position.x / 1280.0 * PI) + bullet_data[bullet.name].y
		bullet_data[bullet.name].t += 10 * delta
		cond = bullet_data[bullet.name].t > 1280 * 7
	else:
		if not bullet_data[bullet.name].has("dir"):
			bullet_data[bullet.name].dir = atan2(mouse_pos.y - 720, mouse_pos.x - bullet.position.x) + rand_range(-0.1, 0.1)
		bullet.position.x += bullet_data[bullet.name].v * cos(bullet_data[bullet.name].dir) * delta
		bullet.position.y += bullet_data[bullet.name].v * sin(bullet_data[bullet.name].dir) * delta
		cond = bullet.position.y < -20 or bullet.position.x < -20 or bullet.position.x > 1300
	return {"remove":cond, "fn":"pattern_%s" % [[8, 9, 10, 11][Helper.rand_int(0, 3)]]}

func graph_process(bullet, delta):
	var cond:bool = false
	if bullet_data[bullet.name].b_type == "x_axis":
		bullet.position.x += delta * 8
		if bullet.position.x > 1280:
			bullet_data[bullet.name].loops -= 1
			bullet.position.x -= 1280
	elif bullet_data[bullet.name].b_type == "y_axis":
		bullet.position.y -= delta * 8
		if bullet.position.y < 0:
			bullet_data[bullet.name].loops -= 1
			bullet.position.y += 720
	elif bullet_data[bullet.name].b_type == "function":
		var pos:Vector2
		var spd:float
		var start:Vector2 = bullet_data[bullet.name].start
		var target:Vector2 = bullet_data[bullet.name].target
		if bullet_data[bullet.name].delay2 < 0:
			pos = start
			var dist:float = pos.distance_to(bullet_data[bullet.name].target)
			spd = dist - bullet.position.distance_to(pos)
			if spd < 0.1:
				bullet.position -= (target - start).normalized()
			cond = bullet.position.x < 0 or bullet.position.x > 1280 or bullet.position.y < 0 or bullet.position.y > 720
		else:
			pos = target
			bullet_data[bullet.name].delay2 -= delta / 60.0
			spd = bullet.position.distance_to(pos)
		bullet.position = bullet.position.move_toward(pos, spd * delta / 20.0)
	elif bullet_data[bullet.name].b_type == "graph":
		var v:Vector2 = Vector2(delta, delta * call("fn_%sp" % pattern, adjust_playfield_to_pos(Vector2(bullet.position.x, 0)).x))
		bullet.position += adjust_v_to_playfield(v) * 0.012
		if bullet.position.x > 1280:
			bullet_data[bullet.name].loops -= 1
			bullet.position.x -= 1280
			bullet.position.y = get_y_from_x("fn_%s" % pattern, bullet.position.x)
	else:
		bullet.position.y -= 2.0 * delta
		if bullet.position.y < -20:
			cond = true
	if bullet_data[bullet.name].has("loops"):
		cond = bullet_data[bullet.name].loops <= 0
	var patterns:Array = lvpatterns[lv - 1].duplicate()
	patterns.shuffle()
	return {"remove":cond, "fn":"pattern_%s" % [patterns[0]]}

func process_19(bullet, delta):
	pass
#	bullet_data[bullet.name].delay -= delta
#	var grow = delta + 0.01
#	bullet.scale += Vector2.ONE * grow * 0.1
#	if bullet.scale.x > 0.5: #sets max size
#		bullet.scale = Vector2.ONE * 0.5
#	if bullet_data[bullet.name].delay < 0:
#		var cond:bool = false
#		if not bullet_data[bullet.name].has("dir"):
#			bullet_data[bullet.name].dir = atan2(mouse_pos.y - 720, mouse_pos.x - bullet.position.x) + rand_range(-0.1, 0.1)
#		bullet.position.x += bullet_data[bullet.name].v * cos(bullet_data[bullet.name].dir)
#		bullet.position.y += bullet_data[bullet.name].v * sin(bullet_data[bullet.name].dir)
#		cond = bullet.position.y < -20 or bullet.position.x < -20 or bullet.position.x > 1300
#		hit_test(bullet)
#		if cond:
#			bullet.remove_from_group("bullet_13")
#			remove_child(bullet)
#			if get_tree().get_nodes_in_group("bullet_13").empty():
#				inc_combo()
#				call("pattern_%s" % [[13][Helper.rand_int(0, 0)]])

func process_20(bullet, delta):
	var dx:float = 0.4
	bullet.position.x += dx
	var x = bullet.position.x
	bullet.position.y += -dx*9/16.0*PI*(20*sin(PI*x/1280)*pow(sin(PI*x/64),2)-cos(PI*x/1280)*cos(PI*x/64)*sin(PI*x/64)-20*sin(PI*x/1280)*pow(cos(PI*x/64),2))
	#bullet.position.y += -dx * 9 / 16.0 * PI * (20 * sin(PI * x / 1280) * pow(sin(PI * x / 64), 2) - cos(PI * x / 1280) * cos(PI * x / 64) * sin(PI * x / 64) - 20 * sin(PI * x / 1280) * pow(cos(PI * x / 64), 2))
	if bullet.position.x > 1280:
		bullet.position.x -= 1280

func process_21(bullet, delta):
	var dx:float = 1
	bullet.position.x += dx
	bullet.position.y += dx * 45 * PI / 32 * cos(PI*(bullet.position.x)/256)
	if bullet.position.x > 1280:
		bullet.position.x -= 1280

#func process_16(bullet, delta):	
var playfield:PoolVector2Array = [Vector2(-40, -40), Vector2(1320, -40), Vector2(1320, 760), Vector2(-40, 760)]
func _process(delta):
	if red_flash.modulate.a > 0:
		red_flash.modulate.a -= 0.01
	var m_pos = game.mouse_pos if game else mouse_pos
	if not game or move_ship_inst:
		ship.position = m_pos
	else:
		ship.position = ship.position.move_toward(m_pos, ship.position.distance_to(m_pos) / 6.0)
	point.position = m_pos
	acc_time.text = tr("TRAVEL_ACCELERATED_BY") % [Helper.time_to_str(max(0, secs_elapsed * 1000 - penalty_time))]
	for star in get_tree().get_nodes_in_group("stars"):
		star.position.x -= star.scale.x * 20
		if star.position.x < -5:
			star.position.x = 1285

	for bullet in get_tree().get_nodes_in_group("bullet_%s" % pattern):
		bullet_data[bullet.name].delay -= delta
		if bullet_data[bullet.name].delay < 0:
			var data:Dictionary
			if lv % 4 == 0:
				data = call("graph_process", bullet, delta * 60)
			else:
				data = call("process_%s" % pattern, bullet, delta * 60)
			hit_test(bullet)
			if data.remove:
				bullet.remove_from_group("bullet_%s" % pattern)
				remove_child(bullet)
				bullet.queue_free()
				if get_tree().get_nodes_in_group("bullet_%s" % pattern).empty():
					inc_combo()
					bullet_data.clear()
					pattern = int(data.fn.split("_")[1])
					if no_hit_combo == 3 and lv != 1:
						go_up_lv()
						pattern = Helper.rand_int(lvpatterns[lv - 1][0], lvpatterns[lv - 1][-1])
						fn_to_call = "pattern_%s" % [pattern]
					else:
						if lv == 1:
							fn_to_call = "pattern_%s" % pattern
							if pattern == 4:
								go_up_lv()
							else:
								show_help(tr("STM_AFTER_PATTERN_%s" % [pattern - 1]))
						else:
							if lv % 4 == 0:
								call("graph_pattern")
							else:
								call(data.fn)

var bullet_data:Dictionary = {}#Holds individual custom bullet data
func inc_combo():
	if not got_hit:
		no_hit_combo += 1
	got_hit = false
	bullet_data.clear()

func hit_test(bullet):
	if red_flash.modulate.a <= 0 and Geometry.is_point_in_circle(mouse_pos, bullet.position, 13 * bullet.scale.x):
		red_flash.modulate.a = 0.3 
		penalty_time += 6000 #miliseconds removed when hit
		got_hit = true
		no_hit_combo = 0

func pattern_1():
	var delay:float = 0
	for i in 100:
		put_bullet(Vector2(1300, rand_range(0, 720)), rand_range(0.3, 0.5), 1, {"delay":delay})
		delay += 0.5 if (i+1) % 10 == 0 else 0.02

func pattern_2():
	for i in 10:
		for j in 36:
			put_bullet(Vector2(1300, j * 60), rand_range(0.35, 0.45), 2, {"delay":0.6 * i, "i":i})

func pattern_3():
	for i in 10:
		for j in 4:
			var pos:Vector2 = Vector2.ZERO
			pos.x = 1320
			var rand:float = randf()
			if rand < 0.5:
				pos.y = rand_range(0, 360)
			else:
				pos.y = rand_range(360, 720)
			put_bullet(pos, rand_range(1.1, 1.2), 3, {"delay":0.7 * i, "rand":rand < 0.5})

func pattern_4():
	for i in 45:
		var pos:Vector2 = Vector2.ZERO
		pos.x = rand_range(1300, 5000)
		if randf() < 0.5:
			pos.y = rand_range(180, 540)
		else:
			pos.y = rand_range(0, 720)
		put_bullet(pos, rand_range(0.3, 1.5), 4, {"b_type":"b", "delay":0})
	for i in 200:
		for j in 2:
			var pos:Vector2 = Vector2.ZERO
			pos.x = 1300
			pos.y = sin(i / 20.0 * PI) * 360 * (1 if j == 0 else -1) + 360 + rand_range(-20, 20)
			put_bullet(pos, 0.4, 4, {"delay":0.06 * i})

func pattern_5():
	for i in 20:
		var y_pos = rand_range(0, 720)
		for j in 40:
			put_bullet(Vector2(1300, y_pos), 0.35, 5, {"delay":0.5 * i}, j / 40.0 * PI + PI / 2)

func pattern_6():
	for i in 15:
		for j in 8:
			put_bullet(Vector2(1350, rand_range(0, 720)), 2, 6, {"delay":0.5 * i})

func pattern_7():
	for i in 300:
		var pos:Vector2 = Vector2.ZERO
		var sc = rand_range(0.2, 1.3)
		pos.x = 1300 + rand_range(0, (2.5 - sc) * 2800)
		pos.y = rand_range(0, 720)
		put_bullet(pos, sc, 7, {"delay":0})

func pattern_8():
	for i in 15:
		for dir in ["r", "l", "u", "d"]:
			var rand_x = rand_range(0, 1280)
			var rand_y = rand_range(0, 720)
			for j in 8:
				var pos:Vector2 = Vector2.ZERO
				if dir == "r":
					pos.x = 1300 + j * 20
					pos.y = rand_y
				elif dir == "l":
					pos.x = -20 - j * 20
					pos.y = rand_y
				elif dir == "u":
					pos.x = rand_x
					pos.y = -20 - j * 20
				else:
					pos.x = rand_x
					pos.y = 740 + j * 20
				put_bullet(pos, 0.5, 8, {"delay":0.5 * i, "dir":dir})

func pattern_9():
	for i in 800:
		put_bullet(Vector2(rand_range(0, 1280), -15 - rand_range(0, 1300)), 0.4, 9, {"spd":Vector2(0, 2), "b_type":"b", "delay":0})
	for i in 130:
		put_bullet(Vector2(-i * 15, 720 + i * 5), 0.5, 9, {"spd":Vector2(3, -1), "b_type":"b2", "delay":0})
	for i in 100:
		put_bullet(Vector2(700 + i * 12, 740 + i * 12), 0.5, 9, {"spd":Vector2(-3, -3), "b_type":"b3", "delay":4})
	for i in 100:
		put_bullet(Vector2(900 - i * 3, -20 - i * 12), 0.5, 9, {"spd":Vector2(1, 4), "b_type":"b4", "delay":8})

func pattern_10():
	for i in 100:
		put_bullet(Vector2(rand_range(0, 1280), 740), 0.4, 10, {"delay":i * 5 / 60.0, "b_type":"b", "speed":Vector2(0, -10), "acceleration":Vector2(0, 0.1)})
	for i in 100:
		put_bullet(Vector2(rand_range(0, 1280), -20), 0.4, 10, {"delay":i * 5 / 60.0, "b_type":"b2", "speed":Vector2(0, 10), "acceleration":Vector2(0, -0.1)})

func pattern_11():
	for i in 10:
		var pos:Vector2 = Vector2.ZERO
		var side = ["l", "u", "d", "r"][Helper.rand_int(0, 3)]
		if side == "l":
			pos = Vector2(-20, rand_range(0, 720))
		elif side == "u":
			pos = Vector2(rand_range(0, 1280), -20)
		elif side == "d":
			pos = Vector2(rand_range(0, 1280), 740)
		else:
			pos = Vector2(1300, rand_range(0, 720))
		for j in 30:
			var v:Vector2 = Vector2.ZERO
			var r:float = rand_range(2, 4)
			if side == "l":
				v = polar2cartesian(r, rand_range(-PI / 2, PI / 2))
			elif side == "u":
				v = polar2cartesian(r, rand_range(0, PI))
			elif side == "d":
				v = polar2cartesian(r, rand_range(-PI, 0))
			else:
				v = polar2cartesian(r, rand_range(PI / 2, 3 * PI / 2))
			put_bullet(pos, rand_range(0.3, 0.6), 11, {"speed":v, "delay":0.8 * i})

func pattern_12():
	for i in 128:
		put_bullet(Vector2.ZERO, 0.25, 12, {"t":-i * 10, "b_type":"b", "y":200, "delay":0})
	for i in 128:
		put_bullet(Vector2.ZERO, 0.25, 12, {"t":-i * 10, "b_type":"c", "y":190, "delay":0})
	for i in 20:
		var x_pos = rand_range(0, 1280)
		for j in 100:
			put_bullet(Vector2(x_pos, 740), 0.4, 12, {"v":rand_range(3, 8), "delay":0.7 * i})

func graph_pattern():
	var image:Image = load("res://Graphics/STM/%s.png" % pattern)
	image.lock()
	var blacks:PoolVector2Array = []
	for i in range(0, image.get_width(), 2):
		for j in range(0, image.get_height(), 2):
			if image.get_pixel(i, j).a > 0.99:
				blacks.append(Vector2(i, j))
	var n:int = len(blacks)
	for i in n:
		var start_pos:Vector2 = Vector2.ZERO
		var ratio:float = i / float(n)
		if ratio < 0.25:
			start_pos.x = -5
			start_pos.y = 4 * ratio * 720
		elif ratio < 0.5:
			start_pos.x = 4 * (ratio - 0.25) * 1280
			start_pos.y = 725
		elif ratio < 0.75:
			start_pos.x = 1285
			start_pos.y = 720 - 4 * (ratio - 0.5) * 720
		else:
			start_pos.x = 1280 - 4 * (ratio - 0.75) * 1280
			start_pos.y = -5
		put_bullet(start_pos, 0.15, pattern, {"b_type":"function", "start":start_pos, "target":blacks[i] + Vector2(100, 100), "delay":lerp(0, 5, i / float(n)), "delay2":6.0 + lerp(0, 5, (n - i) / float(n)) * 2.0}, 0, Color.white)
	for i in 300:
		put_bullet(Vector2(0, get_y_from_x("fn_%s" % pattern, 0)), 0.3, pattern, {"b_type":"graph", "loops":1, "delay":i / 30.0 + 0.15})
	for i in 128:
		put_bullet(Vector2(-i * 10, 360), 0.2, pattern, {"b_type":"x_axis", "loops":4, "delay":0})
	for i in 72:
		put_bullet(Vector2(640, 720 + i * 10), 0.2, pattern, {"b_type":"y_axis", "loops":7, "delay":0})
	for i in 150:
		put_bullet(Vector2(rand_range(0, 1280), 740), rand_range(0.2, 0.5), pattern, {"b_type":"obstacle", "delay":i / 15.0})

func adjust_pos_to_playfield(pos:Vector2):
	return Vector2((pos.x + 3.0) * 1280.0 / 6, (3.0 - pos.y) * 720.0 / 6)

func adjust_playfield_to_pos(pos:Vector2):
	return Vector2((pos.x - 640) * 6.0 / 1280, (360 - pos.y) * 6.0 / 720)

func get_y_from_x(fn:String, x:float):
	var new_x:float = adjust_playfield_to_pos(Vector2(x, 0)).x
	return adjust_pos_to_playfield(Vector2(0, call(fn, new_x))).y

func fn_13(x:float):
	return x

func fn_13p(x:float):
	return 1.0

func fn_14(x:float):
	return cos(x)

func fn_14p(x:float):
	return -sin(x)

func fn_15(x:float):
	return cos(pow(x, 2))

func fn_15p(x:float):
	return -2.0 * x * sin(pow(x, 2))

func fn_16(x:float):
	return exp(sin(5.0 * x))

func fn_16p(x:float):
	return 5.0 * cos(5.0 * x) * exp(sin(5.0 * x))

func fn_17(x:float):
	return x * sin(4.0 * x)

func fn_17p(x:float):
	return 4.0 * x * cos(4.0 * x) + sin(4.0 * x)

func fn_18(x:float):
	return 2.0 * sin(x) * cos(5.0 * x)

func fn_18p(x:float):
	return 2 * cos(x) * cos(5.0 * x) - 10.0 * sin(x) * sin(5.0 * x)

func adjust_v_to_playfield(v:Vector2):
	return Vector2(v.x * 1280.0 / 6, -v.y * 720.0 / 6)

func pattern_19():
	for i in 120:
		var x_pos = rand_range(1280, 1300)
		var y_pos = rand_range(0, 1300)
		for j in 2:
			put_bullet(Vector2(x_pos, y_pos), 0, 13, {"v":8, "delay":0.06 * i,}) 

func pattern_20():
	for i in 500:
		var x_pos:float = i * 1280 / 500.0
		var y_pos = 720 * sin(PI * x_pos / 1280) * sin(PI * x_pos / 64) * cos(PI * x_pos / 64) + 720 / 2
		put_bullet(Vector2(x_pos, y_pos), 0.3, 14, {"delay":0.7 * i})

func pattern_21():
	for i in 500:
		var x_pos:float = i * 1280 / 500.0
		var y_pos = 360 * sin((5 * PI * x_pos) / 1280) + 720 / 2
		put_bullet(Vector2(x_pos, y_pos), 0.3, 15, {"delay":1 * i})

func put_bullet(pos:Vector2, sc:float, group:int, data:Dictionary = {}, rot:float = 0, color:Color = Color.black):
	var bullet = Sprite.new()
	bullet.texture = bullet_texture
	if color == Color.black:
		bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
	else:
		bullet.modulate = color
	bullet.scale *= sc
	bullet.position = pos
	bullet.rotation = rot
	add_child(bullet)
	if not data.empty():
		bullet_data[bullet.name] = data
	bullet.add_to_group("bullet_%s" % [group])

func _on_Timer_timeout():
	secs_elapsed += 1
