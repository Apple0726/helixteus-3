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

func _ready():
	help_tween = Tween.new()
	add_child(help_tween)
	$Back.text = "<- " + tr("BACK") + " (Z)"
	$Level.text = "%s 1" % [tr("LEVEL")]
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
		fn_to_call = "pattern_2"
		$Help.visible = true
		show_help(tr("MOVE_SHIP_WITH_MOUSE"))
		$Timer.paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func show_help(st:String):
	$Help.text = "%s (%s)" % [st, tr("CLICK_ANYWHERE_TO_CONTINUE")]
	help_tween.interpolate_property($Help, "modulate", null, Color.white, 0.5)
	help_tween.interpolate_property($Help, "rect_position", null, $Help.rect_position - Vector2(0, 15), 0.5)
	help_tween.start()

func hide_help():
	help_tween.interpolate_property($Help, "modulate", Color.white, Color(1, 1, 1, 0), 0.5)
	help_tween.interpolate_property($Help, "rect_position", null, $Help.rect_position + Vector2(0, 30), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
	help_tween.start()

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
		if red_flash.modulate.a <= 0 and Geometry.is_point_in_circle(m_pos, bullet.position, 13 * bullet.scale.x):
			red_flash.modulate.a = 0.3
			penalty_time += 3000
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_1")
			if get_tree().get_nodes_in_group("bullet_1").empty():
				show_help(tr("STM_AFTER_PATTERN_1"))
				ship.modulate.a = 1.0
				fn_to_call = "pattern_2"
				$Timer.paused = true
			remove_child(bullet)
	for bullet in get_tree().get_nodes_in_group("bullet_2"):
		bullet.position.x -= 3
		if red_flash.modulate.a <= 0 and Geometry.is_point_in_circle(m_pos, bullet.position, 13 * bullet.scale.x):
			red_flash.modulate.a = 0.3
			penalty_time += 3000
		bullet.position.y -= int(bullet.name.split("_")[0]) / 5.0
		if bullet.position.x < -25:
			bullet.remove_from_group("bullet_2")
			if get_tree().get_nodes_in_group("bullet_2").empty():
				show_help(tr("STM_AFTER_PATTERN_2"))
				ship.modulate.a = 1.0
				fn_to_call = "pattern_3"
				$Timer.paused = true
			remove_child(bullet)

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
	for i in 15:
		if stop_yield:
			break
		for j in 36:
			var bullet = Sprite.new()
			bullet.texture = bullet_texture
			bullet.modulate = [Color(1, 0.6, 0.6, 1), Color(0.6, 1, 0.6, 1), Color(0.6, 0.6, 1, 1)][Helper.rand_int(0, 2)]
			bullet.scale *= rand_range(0.2, 0.4)
			bullet.name = "%s_%s" % [i, j]
			add_child(bullet)
			bullet.position.x = 1300
			bullet.position.y = j * 60
			bullet.add_to_group("bullet_2")
		yield(get_tree().create_timer(0.5), "timeout")

func pattern_3():
	pass


func _on_Timer_timeout():
	secs_elapsed += 1
