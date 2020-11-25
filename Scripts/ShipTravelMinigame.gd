extends Control

onready var star_scene = preload("res://Scenes/Decoratives/Star.tscn")
onready var bullet_texture = preload("res://Graphics/Misc/bullet.png")

onready var game# = get_node("/root/Game")
onready var ship = $Ship
onready var acc_time = $AccTime
onready var point = $Point
onready var red_flash = $RedFlash
var secs_elapsed:int = 0
var move_ship_inst:bool = false
var stop_yield:bool = false
var help_tween:Tween
var fn_to_call:String = ""
var penalty_time:int = 0
var lv:int = 1
var no_hit_combo:int = 1
var got_hit:bool = false

func set_level():
	$Timer.wait_time = 1.0 / lv
	$Level.text = "%s %s" % [tr("LEVEL"), lv]
	
func _ready():
	help_tween = Tween.new()
	add_child(help_tween)
	$Back.text = "<- " + tr("BACK") + " (Z)"
	set_level()
	var tween:Tween = Tween.new()
	tween.interpolate_property($Level, "modulate", null, Color.white, 0.5)
	add_child(tween)
	tween.start()
	for i in 100:
		var star = star_scene.instance()
		star.scale *= rand_range(0.02, 0.05)
		star.rotation = rand_range(0, 2 * PI)
		add_child(star)
		star.position.x = rand_range(0, 1280)
		star.position.y = rand_range(0, 720)
		star.add_to_group("stars")
	if not game or game.help.STM:
		fn_to_call = "pattern_5"
		$Help.visible = true
		show_help(tr("MOVE_SHIP_WITH_MOUSE"))
		$Timer.paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func show_help(st:String):
	$Help.text = "%s (%s)" % [st, tr("CLICK_ANYWHERE_TO_CONTINUE")]
	help_tween.interpolate_property($Help, "modulate", null, Color.white, 0.5)
	help_tween.interpolate_property($Help, "rect_position", null, $Help.rect_position - Vector2(0, 15), 0.5)
	help_tween.start()
	ship.modulate.a = 1.0

func hide_help():
	help_tween.interpolate_property($Help, "modulate", Color.white, Color(1, 1, 1, 0), 0.5)
	help_tween.interpolate_property($Help, "rect_position", null, $Help.rect_position + Vector2(0, 30), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
	help_tween.start()
	$Timer.paused = true

func _on_Back_pressed():
	game.switch_view("a")

var mouse_pos:Vector2 = Vector2.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	if Input.is_action_just_released("left_click") and $Help.modulate == Color.white:
		hide_help()
		call(fn_to_call)
		$Timer.paused = false
		ship.modulate.a = 0.5
	Helper.set_back_btn($Back)

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
	for bullet in get_tree().get_nodes_in_group("bullet_1"):
		bullet.position.x -= 6
		hit_test(bullet)
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_1")
			if get_tree().get_nodes_in_group("bullet_1").empty():
				inc_combo()
				show_help(tr("STM_AFTER_PATTERN_1"))
				ship.modulate.a = 1.0
				fn_to_call = "pattern_2"
				$Timer.paused = true
				got_hit = false
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_2"):
		bullet.position.x -= 4
		hit_test(bullet)
		bullet.position.y -= int(bullet.name.split("_")[0]) / 3.0
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_2")
			if get_tree().get_nodes_in_group("bullet_2").empty():
				inc_combo()
				show_help(tr("STM_AFTER_PATTERN_2"))
				ship.modulate.a = 1.0
				fn_to_call = "pattern_3"
				$Timer.paused = true
				got_hit = false
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_3"):
		bullet.position.x -= 8
		bullet.scale += Vector2(0.01, 0.01)
		hit_test(bullet)
		var rand = int(bullet.name.split("_")[1])
		if rand == 0:
			bullet.position.y += 1
		else:
			bullet.position.y -= 1
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_3")
			if get_tree().get_nodes_in_group("bullet_3").empty():
				inc_combo()
				no_hit_combo = 0
				got_hit = false
				lv += 1
				set_level()
				show_help(tr("STM_LEVEL_2"))
				ship.modulate.a = 1.0
				fn_to_call = "pattern_%s" % [Helper.rand_int(4, 7)]
				$Timer.paused = true
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_4"):
		if bullet.name[0] == "b":
			bullet.position.x -= 5
		else:
			bullet.position.x -= 4
		hit_test(bullet)
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_4")
			if get_tree().get_nodes_in_group("bullet_4").empty():
				inc_combo()
				if no_hit_combo == 3:
					show_help(tr("STM_LEVEL_3"))
					fn_to_call = "pattern_%s" % [Helper.rand_int(8, 12)]
				else:
					call("pattern_%s" % [Helper.rand_int(5, 7)])
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_5"):
		bullet.position.x += 5 * cos(bullet.rotation)
		bullet.position.y += 5 * sin(bullet.rotation)
		hit_test(bullet)
		if bullet.position.x < -25 or bullet.position.y < -20 or bullet.position.y > 740:
			bullet.remove_from_group("bullet_5")
			if get_tree().get_nodes_in_group("bullet_5").empty():
				inc_combo()
				if no_hit_combo == 3:
					show_help(tr("STM_LEVEL_3"))
					fn_to_call = "pattern_%s" % [Helper.rand_int(8, 12)]
				else:
					call("pattern_%s" % [[4, 6, 7][Helper.rand_int(0, 2)]])
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_6"):
		bullet.position.x -= pow(1351 - bullet.position.x, 0.45)
		hit_test(bullet)
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_6")
			if get_tree().get_nodes_in_group("bullet_6").empty():
				inc_combo()
				if no_hit_combo == 3:
					show_help(tr("STM_LEVEL_3"))
					fn_to_call = "pattern_%s" % [Helper.rand_int(8, 12)]
				else:
					call("pattern_%s" % [[4, 5, 7][Helper.rand_int(0, 2)]])
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_7"):
		bullet.position.x -= 5 * (2.5 - bullet.scale.x)
		hit_test(bullet)
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_7")
			if get_tree().get_nodes_in_group("bullet_7").empty():
				inc_combo()
				if no_hit_combo == 3:
					show_help(tr("STM_LEVEL_3"))
					fn_to_call = "pattern_%s" % [Helper.rand_int(8, 12)]
				else:
					call("pattern_%s" % [[4, 5, 6][Helper.rand_int(0, 2)]])
			remove_child(bullet)

func inc_combo():
	if not got_hit:
		no_hit_combo += 1
	got_hit = false

func hit_test(bullet):
	if red_flash.modulate.a <= 0 and Geometry.is_point_in_circle(mouse_pos, bullet.position, 13 * bullet.scale.x):
		red_flash.modulate.a = 0.3
		penalty_time += 3000
		got_hit = true
		no_hit_combo = 0

func _on_STM_tree_exited():
	stop_yield = true

func pattern_1():
	for i in 100:
		if stop_yield:
			break
		var bullet = Sprite.new()
		bullet.texture = bullet_texture
		bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
		bullet.scale *= rand_range(0.3, 0.5)
		add_child(bullet)
		bullet.position.x = 1300
		bullet.position.y = rand_range(10, 710)
		bullet.add_to_group("bullet_1")
		yield(get_tree().create_timer(0.5 if (i+1) % 10 == 0 else 0.02), "timeout")

func pattern_2():
	for i in 10:
		if stop_yield:
			break
		for j in 36:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= rand_range(0.35, 0.45)
			bullet.name = "%s_%s" % [i, j]
			add_child(bullet)
			bullet.position.x = 1300
			bullet.position.y = j * 60
			bullet.add_to_group("bullet_2")
		yield(get_tree().create_timer(0.6), "timeout")

func pattern_3():
	for i in 10:
		if stop_yield:
			break
		for j in 4:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= rand_range(1.1, 1.2)
			var rand:float = randf()
			add_child(bullet)
			bullet.position.x = 1300
			if rand < 0.5:
				bullet.position.y = rand_range(0, 360)
				bullet.name = "%s_%s" % [j + i * 4, 0]
			else:
				bullet.position.y = rand_range(360, 720)
				bullet.name = "%s_%s" % [j + i * 4, 1]
			bullet.add_to_group("bullet_3")
		yield(get_tree().create_timer(0.7), "timeout")

func pattern_4():
	for i in 45:
		var bullet = Sprite.new()
		bullet.texture = bullet_texture
		bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
		bullet.scale *= rand_range(0.3, 1.5)
		bullet.position.x = rand_range(1300, 5000)
		if randf() < 0.5:
			bullet.position.y = rand_range(180, 540)
		else:
			bullet.position.y = rand_range(0, 720)
		add_child(bullet)
		bullet.name = "b%s" % [i]
		bullet.add_to_group("bullet_4")
	for i in 200:
		for j in 2:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= 0.4
			bullet.position.x = 1300
			bullet.position.y = sin(i / 20.0 * PI) * 360 * (1 if j == 0 else -1) + 360 + rand_range(-20, 20)
			add_child(bullet)
			bullet.add_to_group("bullet_4")
		yield(get_tree().create_timer(0.06), "timeout")

func pattern_5():
	for i in 20:
		var y_pos = rand_range(0, 720)
		for j in 40:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= 0.35
			bullet.position.x = 1300
			bullet.position.y = y_pos
			bullet.rotation = j / 40.0 * PI + PI / 2
			add_child(bullet)
			bullet.add_to_group("bullet_5")
		yield(get_tree().create_timer(0.5), "timeout")

func pattern_6():
	for i in 15:
		for j in 8:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= 2
			bullet.position.x = 1350
			bullet.position.y = rand_range(0, 720)
			add_child(bullet)
			bullet.add_to_group("bullet_6")
		yield(get_tree().create_timer(0.5), "timeout")

func pattern_7():
	for i in 350:
		var bullet = Sprite.new()
		bullet.texture = bullet_texture
		bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
		bullet.scale *= rand_range(0.2, 1.3)
		bullet.position.x = 1300 + rand_range(0, (2.5 - bullet.scale.x) * 3200)
		bullet.position.y = rand_range(0, 720)
		add_child(bullet)
		bullet.add_to_group("bullet_7")

func _on_Timer_timeout():
	secs_elapsed += 1
