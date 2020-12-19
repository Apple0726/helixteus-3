extends Control

onready var game = get_node("/root/Game")
onready var current = $Current
onready var ship1 = $Ship1
onready var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
onready var target_scene = preload("res://Scenes/TargetButton.tscn")
onready var HP_icon = preload("res://Graphics/Icons/HP.png")
onready var atk_icon = preload("res://Graphics/Icons/atk.png")
onready var def_icon = preload("res://Graphics/Icons/def.png")
onready var acc_icon = preload("res://Graphics/Icons/acc.png")
onready var eva_icon = preload("res://Graphics/Icons/eva.png")
onready var w_1_1 = preload("res://Scenes/HX/Weapons/1_1.tscn")
onready var w_1_2 = preload("res://Scenes/HX/Weapons/1_2.tscn")
onready var w_1_3 = preload("res://Scenes/HX/Weapons/1_3.tscn")
onready var w_2_1 = preload("res://Scenes/HX/Weapons/2_1.tscn")
onready var w_2_2 = preload("res://Scenes/HX/Weapons/2_2.tscn")
onready var w_2_3 = preload("res://Scenes/HX/Weapons/2_3.tscn")

var star:Sprite#Shown right before HX magic

var ship_data = [{"HP":20, "total_HP":20, "atk":10, "def":10, "acc":10, "eva":10, "XP":0, "bullet":0, "laser":0, "bomb":0, "light":0}]
var HX_data = []
var HXs = []
var HX_c_d:Dictionary = {}#HX_custom_data
var w_c_d:Dictionary = {}#weapon_custom_data
var HX_w_c_d:Dictionary = {}#HX_weapon_custom_data
var curr_sh:int = 1#current_ship
var curr_en:int = 0#current_enemy
var weapon_type:String = ""
var immune:bool = false
var wave:int = 0

enum BattleStages {CHOOSING, PLAYER, ENEMY}

var stage

func _ready():
	randomize()
	stage = BattleStages.CHOOSING
	$Current/Current.float_height = 5
	$Current/Current.float_speed = 0.25
	$Ship1/HP.max_value = ship_data[0].total_HP
	$Ship1/HP.value = ship_data[0].HP
	for k in 5:
		var lv = 1
		var HP = round(rand_range(1, 1.5) * 15 * pow(1.3, lv))
		var atk = round(rand_range(1, 1.5) * 8 * pow(1.3, lv))
		var def = round(rand_range(1, 1.5) * 8 * pow(1.3, lv))
		var acc = round(rand_range(1, 1.5) * 8 * pow(1.3, lv))
		var eva = round(rand_range(1, 1.5) * 8 * pow(1.3, lv))
		HX_data.append({"type":Helper.rand_int(1, 2), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva})

func send_HXs():
	for k in 4 + (wave * 4):
		var btn = TextureButton.new()
		btn.rect_position = -Vector2(90, 50)
		btn.rect_size = Vector2(180, 100)
		var HX = HX1_scene.instance()
		HX.get_node("HX/Sprite").texture = load("res://Graphics/HX/%s.png" % [HX_data[k].type])
		HX.scale *= 0.4
		HX.get_node("HX/HP").max_value = HX_data[k].total_HP
		HX.get_node("HX/HP").value = HX_data[k].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[k].lv]
		HX.get_node("HX").set_script(load("res://Scripts/FloatAnim.gd"))
		HX.position = Vector2(2000, 360)
		HX.add_child(btn)
		btn.connect("mouse_entered", self, "on_HX_over", [k])
		btn.connect("mouse_exited", self, "on_HX_out")
		add_child(HX)
		HXs.append(HX)
		HX_c_d[HX.name] = {"knockback":Vector2.ZERO, "kb_dur":0, "kb_rot":0, "kb_spd":0, "position":Vector2((k % 2) * 300 + 850, (k / 2) * 150 + 250)}
	
func on_HX_over(id:int):
	if game:
		game.show_adv_tooltip("@i %s / %s\n@i %s   @i %s\n@i %s   @i %s" % [ceil(HX_data[id].HP), HX_data[id].total_HP, HX_data[id].atk, HX_data[id].def, HX_data[id].acc, HX_data[id].eva], [HP_icon, atk_icon, def_icon, acc_icon, eva_icon])

func on_HX_out():
	if game:
		game.hide_adv_tooltip()

var mouse_pos:Vector2 = Vector2.ZERO
func _input(event):
	Helper.set_back_btn($Back)
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	if stage == BattleStages.CHOOSING and Input.is_action_just_released("right_click"):
		remove_targets()
		$FightPanel.visible = true
	if Input.is_action_just_pressed("A"):
		display_HX_info("atk")
	if Input.is_action_just_pressed("D"):
		display_HX_info("def")
	if Input.is_action_just_pressed("C"):
		display_HX_info("acc")
	if Input.is_action_just_pressed("E"):
		display_HX_info("eva")
	if Input.is_action_just_pressed("H"):
		display_HX_info("HP")
	if Input.is_action_just_released("A") or Input.is_action_just_released("D") or Input.is_action_just_released("C") or Input.is_action_just_released("E") or Input.is_action_just_released("H"):
		var i:int = 0
		for HX in HXs:
			HX.get_node("Info/Sprite").visible = false
			HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[i].lv]
	if Input.is_action_just_pressed("left"):
		ship_dir = "left"
	if Input.is_action_just_pressed("right"):
		ship_dir = "right"
	if Input.is_action_just_released("left") and Input.is_action_pressed("right"):
		ship_dir = "right"
	elif Input.is_action_just_released("left"):
		ship_dir = ""
	if Input.is_action_just_released("right") and Input.is_action_pressed("left"):
		ship_dir = "left"
	elif Input.is_action_just_released("right"):
		ship_dir = ""

func display_HX_info(type:String):
	var i:int = 0
	for HX in HXs:
		HX.get_node("Info/Sprite").visible = true
		HX.get_node("Info/Sprite").texture = self["%s_icon" % [type]]
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [HX_data[i].HP, HX_data[i].total_HP]
		else:
			HX.get_node("Info/Label").text = String(HX_data[i][type])
		i += 1

func _on_Back_pressed():
	game.switch_view("system")

var ship_dir:String = ""

func damage_HX(id:int, dmg:float):
	HX_data[id].HP -= dmg
	HXs[id].get_node("HX/HP").value = HX_data[id].HP
	Helper.show_dmg(dmg, HXs[id].position, self, 0.6)
	
func _process(delta):
	for i in len(HXs):
		var HX = HXs[i]
		if HX_data[i].HP <= 0 and HX.modulate.a > 0:
			HX.modulate.a -= 0.03
		var pos = HX_c_d[HX.name].position
		var kb_rot = HX_c_d[HX.name].kb_rot
		if HX_c_d[HX.name].knockback != Vector2.ZERO:
			var kb = HX_c_d[HX.name].knockback
			HX.position = HX.position.move_toward(pos + kb, HX.position.distance_to(pos + kb) * delta * 5)
			HX.rotation = move_toward(HX.rotation, kb_rot, kb_rot * delta)
			HX_c_d[HX.name].kb_dur -= delta
			if HX_c_d[HX.name].kb_dur < 0:
				HX_c_d[HX.name].knockback = Vector2.ZERO
		else:
			HX.rotation = move_toward(HX.rotation, 0, kb_rot * delta)
			HX.position = HX.position.move_toward(pos, HX.position.distance_to(pos) * delta * 5)
	if stage == BattleStages.CHOOSING:
		ship1.position = ship1.position.move_toward(Vector2(200, 200), ship1.position.distance_to(Vector2(200, 200)) * delta * 5)
		current.position = self["ship%s" % [curr_sh]].position + Vector2(0, -45)
	for light in get_tree().get_nodes_in_group("lights"):
		light.scale += Vector2(0.1, 0.1)
		light.modulate.a -= 0.02
		if light.modulate.a <= 0:
			light.remove_from_group("lights")
			remove_child(light)
	for weapon in get_tree().get_nodes_in_group("weapon"):
		weapon.position += w_c_d[weapon.name].v * delta * 60
		if weapon.position.x > w_c_d[weapon.name].lim:
			weapon.remove_from_group("weapon")
			remove_child(weapon)
			var w_data = "%s_data" % [weapon_type]
			var t = w_c_d[weapon.name].target
			var dmg = ship_data[0].atk * Data[w_data][ship_data[0][weapon_type]].damage / HX_data[w_c_d[weapon.name].target].def
			if t == -1:
				var light = Sprite.new()
				light.texture = preload("res://Graphics/Decoratives/light.png")
				light.position = weapon.position
				light.scale *= 0.2
				light.modulate.a = 0.7
				add_child(light)
				light.add_to_group("lights")
				for i in len(HXs):
					if HX_data[i].HP <= 0:
						continue
					damage_HX(i, dmg)
			else:
				damage_HX(t, dmg)
			$Timer.start()
	for weapon in get_tree().get_nodes_in_group("w_1_1"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if not HX_w_c_d[weapon.name].has("v"):
				HX_w_c_d[weapon.name].v = (weapon.position - ship1.position) / 150.0
				weapon.visible = true
			weapon.position -= HX_w_c_d[weapon.name].v * delta * 60
			HX_w_c_d[weapon.name].v *= 0.07 * delta * 60 + 1
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_1_1")
	for weapon in get_tree().get_nodes_in_group("w_1_2"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.visible = true
				weapon.scale.y += 0.005
				if weapon.scale.y > 0.2:
					HX_w_c_d[weapon.name].stage = 1
			elif HX_w_c_d[weapon.name].stage == 1:
				weapon.scale.y = 2
				weapon.modulate.a = 1
				HX_w_c_d[weapon.name].stage = 2
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].knockback = Vector2(35, 0)
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_dur = 0.5
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_spd = 2
				HX_c_d[HXs[HX_w_c_d[weapon.name].id].name].kb_rot = PI / 8
				weapon.get_node("CollisionShape2D").disabled = false
			elif HX_w_c_d[weapon.name].stage == 2:
				weapon.modulate.a -= 0.02
				if weapon.modulate.a <= 0:
					remove_weapon(weapon, "w_1_2")
	for weapon in get_tree().get_nodes_in_group("w_1_3"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.visible = true
				weapon.position = weapon.position.move_toward(HX_w_c_d[weapon.name].target, weapon.position.distance_to(HX_w_c_d[weapon.name].target) * delta * 5)
				if HX_w_c_d[weapon.name].delay < -1:
					HX_w_c_d[weapon.name].stage = 1
				if HX_w_c_d[weapon.name].delay < -0.3:
					weapon.rotation = move_toward(weapon.rotation, 0, 0.12)
			else:
				weapon.position += HX_w_c_d[weapon.name].v * delta * 60
				HX_w_c_d[weapon.name].v *= 0.02 * delta * 60 + 1
				if weapon.position.x < -100:
					remove_weapon(weapon, "w_1_3")
	for weapon in get_tree().get_nodes_in_group("w_2_1"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position.x -= 14 * delta * 60
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_2_1")
	for weapon in get_tree().get_nodes_in_group("w_2_2"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			if HX_w_c_d[weapon.name].stage == 0:
				weapon.position.y = move_toward(weapon.position.y, HX_w_c_d[weapon.name].y_target, abs(HX_w_c_d[weapon.name].y_target - weapon.position.y) * delta * 4)
				if HX_w_c_d[weapon.name].delay < -1.2:
					HX_w_c_d[weapon.name].stage = 1
			else:
				weapon.position -= (Vector2(HX_w_c_d[weapon.name].init_x, HX_w_c_d[weapon.name].y_target) - Vector2(-100, HX_w_c_d[weapon.name].y_target2)) * delta * 0.8
				if weapon.position.x < -100:
					remove_weapon(weapon, "w_2_2")
	for weapon in get_tree().get_nodes_in_group("w_2_3"):
		HX_w_c_d[weapon.name].delay -= delta
		if HX_w_c_d[weapon.name].delay < 0:
			weapon.position += HX_w_c_d[weapon.name].v
			if weapon.position.x < -100:
				remove_weapon(weapon, "w_2_3")
	if stage == BattleStages.ENEMY:
		var boost:int = 2.5 if Input.is_action_pressed("X") else 1.1
		if ship_dir == "left":
			ship1.position.y = max(0, ship1.position.y - 10 * boost * delta * 60)
		elif ship_dir == "right":
			ship1.position.y = min(720, ship1.position.y + 10 * boost * delta * 60)
	if star:
		star.scale += Vector2(0.12, 0.12) * delta * 60
		star.modulate.a -= 0.03 * delta * 60
		star.rotation += 0.04 * delta * 60
		if star.modulate.a <= 0:
			remove_child(star)
			star = null

func remove_weapon(weapon, group:String):
	weapon.remove_from_group(group)
	remove_child(weapon)
	if get_tree().get_nodes_in_group(group).empty():
		$Timer.start()

func remove_targets():
	for target in get_tree().get_nodes_in_group("targets"):
		target.remove_from_group("targets")
		remove_child(target)
	for HX in HXs:
		HX.get_node("HX").modulate.a = 1

func place_targets():
	remove_targets()
	for i in len(HXs):
		if HX_data[i].HP <= 0:
			continue
		var HX = HXs[i]
		HX.get_node("HX").modulate.a = 0.5
		var target = target_scene.instance()
		target.position = HX.position
		add_child(target)
		target.get_node("TextureButton").shortcut = ShortCut.new()
		target.get_node("TextureButton").shortcut.shortcut = InputEventAction.new()
		target.get_node("TextureButton").shortcut.shortcut.action = String(i + 1)
		target.get_node("TextureButton").connect("pressed", self, "on_target_pressed", [i])
		target.get_node("Label").text = String(i + 1)
		target.add_to_group("targets")

func on_target_pressed(target:int):
	$FightPanel.visible = false
	$Current.visible = false
	$Back.visible = false
	stage = BattleStages.PLAYER
	var weapon = Sprite.new()
	weapon.add_to_group("weapon")
	weapon.texture = load("res://Graphics/Weapons/%s.png" % [weapon_type])
	var ship_pos = self["ship%s" % [curr_sh]].position
	weapon.position = ship_pos
	weapon.scale *= 0.5
	add_child(weapon)
	var HX_pos = Vector2(1000, 360) if target == -1 else HXs[target].position 
	weapon.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
	w_c_d[weapon.name] = {"v":(HX_pos - ship_pos) / 30.0}
	w_c_d[weapon.name].target = target
	w_c_d[weapon.name].lim = HX_pos.x
	remove_targets()

func _on_weapon_pressed(_weapon_type:String):
	weapon_type = _weapon_type
	$FightPanel.visible = false
	if weapon_type == "light":
		on_target_pressed(-1)
	else:
		place_targets()

func _on_Timer_timeout():
	stage = BattleStages.ENEMY
	$Timer.wait_time = 0.2
	enemy_attack()

func enemy_attack():
	while HX_data[curr_en].HP <= 0 and curr_en < 4:
		curr_en += 1
	if curr_en == 4:
		curr_en = 0
		stage = BattleStages.CHOOSING
		$Timer.wait_time = 1.0
		$FightPanel.visible = true
		$Back.visible = true
		$Current.visible = true
	else:
		call("atk_%s_%s" % [HX_data[curr_en].type, Helper.rand_int(1, 3)], curr_en)
		curr_en += 1

func put_magic(id:int):
	star = Sprite.new()
	star.texture = preload("res://Graphics/Decoratives/Star2.png")
	star.position = HXs[id].position - Vector2(0, 15)
	star.scale *= 0.5
	add_child(star)

func atk_1_1(id:int):
	for i in 10:
		var fireball = w_1_1.instance()
		fireball.position = HXs[id].position
		fireball.visible = false
		fireball.add_to_group("w_1_1")
		add_child(fireball)
		HX_w_c_d[fireball.name] = {"group":"w_1_1", "damage":2, "id":id, "delay":i * 0.4}

func atk_1_2(id:int):
	for i in 4:
		for j in 2:
			var beam = w_1_2.instance()
			var target:Vector2 = Vector2(0, rand_range(0, 720))
			var pos = HXs[id].position
			beam.position = pos
			beam.rotation = atan2(pos.y - target.y, pos.x - target.x)
			beam.visible = false
			beam.scale.x = 4
			beam.modulate.a = 0.5
			beam.scale.y = 0
			beam.get_node("CollisionShape2D").disabled = true
			beam.add_to_group("w_1_2")
			add_child(beam)
			HX_w_c_d[beam.name] = {"group":"w_1_2", "damage":2.5, "stage":0, "id":id, "delay":i * 1.2}

func atk_1_3(id:int):
	for i in 5:
		for j in 9:
			var bullet = w_1_3.instance()
			var target:Vector2 = Vector2(1100, rand_range(0, 720))
			var pos = HXs[id].position
			bullet.position = pos
			bullet.rotation = atan2(pos.y - target.y, pos.x - target.x)
			bullet.visible = false
			bullet.scale *= 0.8
			bullet.add_to_group("w_1_3")
			add_child(bullet)
			HX_w_c_d[bullet.name] = {"group":"w_1_3", "v":Vector2(-1, 0), "target":target, "damage":2, "stage":0, "id":id, "delay":i * 0.8}

func atk_2_1(id:int):
	put_magic(id)
	for i in 8:
		var pillar = w_2_1.instance()
		if i % 2 == 0:
			pillar.scale.y *= -1
			pillar.position.y = rand_range(-100, 300)
		else:
			pillar.position.y = rand_range(420, 820)
		pillar.position.x = 1400
		add_child(pillar)
		pillar.add_to_group("w_2_1")
		HX_w_c_d[pillar.name] = {"group":"w_2_1", "damage":3, "id":id, "delay":i * 0.5 + 0.5}

func atk_2_2(id:int):
	put_magic(id)
	for i in 18:
		var ball = w_2_2.instance()
		if i % 2 == 0:
			ball.position.y = -200
		else:
			ball.position.y = 920
		var y_target = rand_range(280, 440)
		var y_target2 = rand_range(0, 720)
		while abs(y_target2 - y_target) < 100:
			y_target2 = rand_range(0, 720)
		ball.position.x = rand_range(900, 1250)
		add_child(ball)
		ball.add_to_group("w_2_2")
		HX_w_c_d[ball.name] = {"group":"w_2_2", "init_x":ball.position.x, "y_target":y_target, "y_target2":y_target2, "stage":0, "damage":2.7, "id":id, "delay":i * 0.25 + 0.5}

func atk_2_3(id:int):
	put_magic(id)
	for i in 40:
		var mine = w_2_3.instance()
		var v:Vector2 = Vector2(-8, rand_range(0, 6))
		mine.position = Vector2(1350, rand_range(0, 720))
		mine.scale *= rand_range(0.6, 0.9)
		if mine.position.y > 360:
			v.y *= -1
		v *= 1.8 - mine.scale.x
		mine.rotation = rand_range(0, 2 * PI)
		add_child(mine)
		mine.add_to_group("w_2_3")
		HX_w_c_d[mine.name] = {"group":"w_2_3", "v":v, "damage":2.2, "id":id, "delay":i * 0.15 + 0.5}

func _on_Ship_area_entered(area, ship_id:int):
	if immune:
		return
	var HX = HX_data[HX_w_c_d[area.name].id]
	var dmg = HX_w_c_d[area.name].damage * HX.atk / ship_data[ship_id].def
	Helper.show_dmg(dmg, ship1.position, self, 0.6)
	ship_data[ship_id].HP -= dmg
	$ImmuneTimer.start()
	immune = true
	if not HX_w_c_d[area.name].group in ["w_1_2", "w_2_1"]:
		remove_weapon(area, HX_w_c_d[area.name].group)
	get_node("Ship%s/HP" % [ship_id + 1]).value = ship_data[ship_id].HP


func _on_ImmuneTimer_timeout():
	immune = false
