extends Control

onready var game = get_node("/root/Game")
onready var current = $Current
onready var ship0 = $Ship0
onready var ship0_engine = $Ship0/Fire
onready var ship1 = $Ship1
onready var ship1_engine = $Ship1/Fire
onready var ship2 = $Ship2
onready var ship2_engine = $Ship2/Fire
onready var ship3 = $Ship3
onready var ship3_engine = $Ship3/Fire
var star_texture = preload("res://Graphics/Effects/spotlight_8_s.png")
var star_shader = preload("res://Shaders/Star.shader")
const DEF_EXPO_SHIP = 1
const DEF_EXPO_ENEMY = 1
onready var time_speed = game.u_i.time_speed if game else 2.5

enum EDiff {EASY, NORMAL, HARD}
var e_diff:int = 2

var victory_panel_scene = preload("res://Scenes/Panels/VictoryPanel.tscn")
var HX1_scene = preload("res://Scenes/HX/HX1.tscn")
var target_scene = preload("res://Scenes/TargetButton.tscn")
var HP_icon = preload("res://Graphics/Icons/HP.png")
var atk_icon = preload("res://Graphics/Icons/atk.png")
var def_icon = preload("res://Graphics/Icons/def.png")
var acc_icon = preload("res://Graphics/Icons/acc.png")
var eva_icon = preload("res://Graphics/Icons/eva.png")
var w_1_1 = preload("res://Scenes/HX/Weapons/1_1.tscn")
var w_1_2 = preload("res://Scenes/HX/Weapons/1_2.tscn")
var w_1_3 = preload("res://Scenes/HX/Weapons/1_3.tscn")
var w_2_1 = preload("res://Scenes/HX/Weapons/2_1.tscn")
var w_2_2 = preload("res://Scenes/HX/Weapons/2_2.tscn")
var w_2_3 = preload("res://Scenes/HX/Weapons/2_3.tscn")
var w_3_1 = preload("res://Scenes/HX/Weapons/3_1.tscn")
var w_3_2 = preload("res://Scenes/HX/Weapons/3_2.tscn")
var w_3_3_1 = preload("res://Scenes/HX/Weapons/3_3_1.tscn")
var w_3_3_2 = preload("res://Scenes/HX/Weapons/3_3_2.tscn")
var w_4_1 = preload("res://Scenes/HX/Weapons/4_1.tscn")
var w_4_2 = preload("res://Scenes/HX/Weapons/4_2.tscn")
var w_4_3 = preload("res://Scenes/HX/Weapons/4_3.tscn")

var star:Sprite#Shown right before HX magic

var ship_data:Array = []# = [{"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "name":"???" "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}, "upgrades":[1.0,1.0,1.0,1.0,1.0]}]
var HX_data
var HXs = []
var HX_c_d:Dictionary = {}#HX_custom_data
var w_c_d:Dictionary = {}#weapon_custom_data
var HX_w_c_d:Dictionary = {}#HX_weapon_custom_data
var a_p_c_d:Dictionary = {}#attack_pattern_custom_data
var curr_sh:int = 0#current_ship
var curr_en:int = 0#current_enemy
var weapon_type:String = ""#Type of weapon the player chose (bullet, laser etc.)
var immune:bool = false
var wave:int = 0
var weapon_XPs:Array = []
var tgt_sh:int = -1#target_ship
var hit_amount:int#Number of times your ships got hit (combined)
var pattern:String = "" #"1_1", "2_3" etc.

var victory_panel

enum BattleStages {CHOOSING, PLAYER, ENEMY}

var stage = BattleStages.CHOOSING

func _ready():
	Helper.set_back_btn($Back)
	randomize()
	if game:
		ship_data = game.ship_data
		var p_i:Dictionary = game.planet_data[game.c_p]
		if game.is_conquering_all:
			HX_data = Helper.get_conquer_all_data().HX_data
		else:
			HX_data = p_i.HX_data
		var orbit_vector = Vector2(cos(p_i.angle - PI/2), sin(p_i.angle + PI/2))
		var lum:float = 0.0
		for star in game.system_data[game.c_s].stars:
			var shift:float = 0
			if star.pos != Vector2.ZERO:
				shift = orbit_vector.dot(star.pos) / 2.0
			var star_spr = Sprite.new()
			star_spr.texture = load("res://Graphics/Effects/spotlight_%s.png" % [int(star.temperature) % 3 + 4])
			star_spr.modulate = Helper.get_star_modulate(star.class)
			star_spr.position.x = range_lerp(p_i.angle, 0, 2 * PI, 100, 1180) + shift
			star_spr.position.y = 200 * cos(game.c_p * 10) + 300
			star_spr.scale *= 0.5 * star.size / (p_i.distance / 500)
			if game.enable_shaders:
				star_spr.material = ShaderMaterial.new()
				star_spr.material.shader = star_shader
				star_spr.material.set_shader_param("time_offset", 10.0 * randf())
				star_spr.material.set_shader_param("brightness_offset", 2.0)
				star_spr.material.set_shader_param("twinkle_speed", 0.8)
				star_spr.material.set_shader_param("amplitude", 0.3)
				if star.luminosity > lum:
					print(star_spr.position.x)
					$BG.material.set_shader_param("strength", pow(star.luminosity, 0.1))
					$BG.material.set_shader_param("shine_r", range_lerp(star_spr.scale.x, 0.0, 2.0, 0.0, 1.4))
					$BG.material.set_shader_param("u", range_lerp(star_spr.position.x, 0, 1280, 0.0, 1.0) - 0.1)
					lum = star.luminosity
			add_child(star_spr)
			move_child(star_spr, 0)
		if not p_i.type in [11, 12]:
			$BG.texture = load("res://Graphics/Planets/BGs/%s.png" % p_i.type)
		else:
			$BG.texture = null
		for i in int(min(10000, 2 * game.galaxy_data[game.c_g].system_num / pow(game.system_data[game.c_s].pos.length(), 0.2))):
			var star:Sprite = Sprite.new()
			star.texture = star_texture
			star.scale *= pow(rand_range(0.4, 0.7), 2)
			star.modulate = Helper.get_star_modulate("%s%s" % [["M", "K", "G", "F", "A", "B", "O"][Helper.rand_int(0, 6)], Helper.rand_int(0, 9)])
			star.modulate.a = rand_range(0, 1)
			star.rotation = rand_range(0, 2*PI)
			star.position.x = rand_range(0, 1280)
			star.position.y = rand_range(0, 720)
			if game.enable_shaders:
				star.material = ShaderMaterial.new()
				star.material.shader = star_shader
				star.material.set_shader_param("time_offset", 10.0 * randf())
			$Stars.add_child(star)
		var config = ConfigFile.new()
		var err = config.load("user://settings.cfg")
		if err == OK:
			e_diff = config.get_value("game", "e_diff", 1)
	else:
		for i in 1000:
			var star:Sprite = Sprite.new()
			star.texture = star_texture
			star.scale *= pow(rand_range(0.4, 0.7), 2)
			star.modulate = Helper.get_star_modulate("%s%s" % [["M", "K", "G", "F", "A", "B", "O"][Helper.rand_int(0, 6)], Helper.rand_int(0, 9)])
			star.modulate.a = pow(rand_range(0.5, 1), 5)
			star.rotation = rand_range(0, 2*PI)
			star.position.x = rand_range(0, 1280)
			star.position.y = rand_range(0, 720)
			star.material = ShaderMaterial.new()
			star.material.shader = star_shader
			star.material.set_shader_param("time_offset", 10.0 * randf())
			$Stars.add_child(star)
		HX_data = []
		ship_data.append({"name":tr("SHIP"), "lv":1, "HP":25, "total_HP":25, "atk":10, "def":5, "acc":10, "eva":10, "points":2, "HP_mult":1.0, "atk_mult":1.0, "def_mult":1.0, "acc_mult":1.0, "eva_mult":1.0, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}})
		for k in 4:
			var lv = 1
			var HP = round(rand_range(1, 1.5) * 15 * pow(1.2, lv))
			var atk = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var def = 5
			var acc = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var eva = round(rand_range(1, 1.5) * 8 * pow(1.2, lv))
			var money = round(rand_range(0.2, 2.5) * pow(1.2, lv) * 10000)
			var XP = round(pow(1.3, lv) * 5)
			HX_data.append({"type":Helper.rand_int(4, 4), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva, "money":money, "XP":XP})
	if OS.get_latin_keyboard_variant() == "AZERTY":
		$Help.text = "%s\n%s\n%s" % [tr("BATTLE_HELP"), tr("BATTLE_HELP2") % ["Z", "M", "S", "ù", "Shift"], tr("PRESS_ANY_KEY_TO_CONTINUE")]
	else:
		$Help.text = "%s\n%s\n%s" % [tr("BATTLE_HELP"), tr("BATTLE_HELP2") % ["W", ";", "S", "'", "Shift"], tr("PRESS_ANY_KEY_TO_CONTINUE")]
	stage = BattleStages.CHOOSING
	$Current.material["shader_param/frequency"] = 12.0 / time_speed
	for i in len(ship_data):
		ship_data[i].HP = ship_data[i].total_HP * ship_data[i].HP_mult
		get_node("Ship%s" % i).visible = true
		get_node("Ship%s/CollisionShape2D" % i).disabled = false
		weapon_XPs.append({"bullet":0, "laser":0, "bomb":0, "light":0})
		get_node("Ship%s/HP" % i).max_value = ship_data[i].total_HP * ship_data[i].HP_mult
		get_node("Ship%s/HP" % i).value = ship_data[i].HP
		get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
	refresh_fight_panel()
	send_HXs()

func refresh_fight_panel():
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		get_node("FightPanel/HBox/%s/TextureRect" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), ship_data[curr_sh][weapon.to_lower()].lv])

func send_HXs():
	for j in 4:
		var k:int = j + wave * 4
		if k >= len(HX_data):
			break
		var btn = TextureButton.new()
		btn.rect_position = -Vector2(90, 50)
		btn.rect_size = Vector2(180, 100)
		var HX = HX1_scene.instance()
		HX.get_node("HX/Sprite").texture = load("res://Graphics/HX/%s.png" % [HX_data[k].type])
		HX.scale *= 0.4
		HX.get_node("HX/HP").max_value = HX_data[k].total_HP
		HX.get_node("HX/HP").value = HX_data[k].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[k].lv]
		#HX.get_node("HX").set_script(load("res://Scripts/FloatAnim.gd"))
		#HX.get_node("HX").float_speed /= time_speed
		HX.position = Vector2(2000, 360)
		HX.add_child(btn)
		btn.connect("mouse_entered", self, "on_HX_over", [k])
		btn.connect("mouse_exited", self, "on_HX_out")
		add_child(HX)
		HXs.append(HX)
		HX_c_d[HX.name] = {"knockback":Vector2.ZERO, "kb_dur":0, "kb_rot":0, "kb_spd":0, "position":Vector2((j % 2) * 300 + 850, (j / 2) * 150 + 250)}
	
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
		display_stats("atk")
	if Input.is_action_just_pressed("D"):
		display_stats("def")
	if Input.is_action_just_pressed("C"):
		display_stats("acc")
	if Input.is_action_just_pressed("E"):
		display_stats("eva")
	if Input.is_action_just_pressed("H"):
		display_stats("HP")
	if Input.is_action_just_released("A") or Input.is_action_just_released("D") or Input.is_action_just_released("C") or Input.is_action_just_released("E") or Input.is_action_just_released("H"):
		for i in len(HXs):
			var HX = HXs[i]
			HX.get_node("Info/Icon").visible = false
			HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[i].lv]
		for i in len(ship_data):
			get_node("Ship%s/Icon" % i).visible = false
			get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
	if Input.is_action_just_pressed("battle_up"):
		ship_dir = "left"
	if Input.is_action_just_pressed("battle_down"):
		ship_dir = "right"
	if Input.is_action_just_released("battle_up") and Input.is_action_pressed("battle_down"):
		ship_dir = "right"
	elif Input.is_action_just_released("battle_up"):
		ship_dir = ""
	if Input.is_action_just_released("battle_down") and Input.is_action_pressed("battle_up"):
		ship_dir = "left"
	elif Input.is_action_just_released("battle_down"):
		ship_dir = ""
	if $Help.modulate.a == 1 and event is InputEventKey:
		game.help.battle = false
		$Help.modulate.a = 0
		tween.interpolate_property($Help, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5)
		tween.interpolate_property($Help, "rect_position", Vector2(0, 339), Vector2(0, 354), 0.5, Tween.TRANS_BACK, Tween.EASE_IN)
		tween.start()
		enemy_attack()

func display_stats(type:String):
	for i in len(HXs):
		var HX = HXs[i]
		HX.get_node("Info/Icon").visible = true
		HX.get_node("Info/Icon").texture = self["%s_icon" % [type]]
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [HX_data[i].HP, HX_data[i].total_HP]
		else:
			HX.get_node("Info/Label").text = String(HX_data[i][type])
	for i in len(ship_data):
		get_node("Ship%s/Icon" % i)
		get_node("Ship%s/Icon" % i).visible = true
		get_node("Ship%s/Icon" % i).texture = self["%s_icon" % [type]]
		if type == "HP":
			get_node("Ship%s/Label" % i).text = "%s / %s" % [ship_data[i].HP, (ship_data[i].total_HP * ship_data[i].HP_mult)]
		else:
			get_node("Ship%s/Label" % i).text = String(ship_data[i][type] * ship_data[i]["%s_mult" % type])

func _on_Back_pressed():
	game.switch_view("system")

var ship_dir:String = ""

func damage_HX(id:int, dmg:float, crit:bool = false):
	HX_data[id].HP -= round(dmg)
	HXs[id].get_node("HX/HP").value = HX_data[id].HP
	Helper.show_dmg(round(dmg), HXs[id].position, self, 0.6, false, crit)

func hit_formula(acc:float, eva:float):
	return 1 / (1 + eva / pow(acc, 1.4))

func hitbox_size():
	if game:
		return 1 - (game.MUs.SHSR - 1) * 0.01
	else:
		return 1

func weapon_hit_HX(sh:int, weapon_data:Dictionary, pos:Vector2 = Vector2.ZERO):
	var w_data = "%s_data" % [weapon_type]
	var t = weapon_data.target
	var remove_weapon_b:bool = false
	if t == -1:
		remove_weapon_b = true
		var light = Sprite.new()
		light.texture = preload("res://Graphics/Decoratives/light.png")
		light.position = pos
		light.scale *= 0.2
		light.modulate.a = 0.7
		add_child(light)
		light.add_to_group("lights")
		var light_hit:bool = false
		for i in len(HXs):
			if HX_data[i].HP <= 0:
				continue
			if randf() < hit_formula(ship_data[sh].acc * weapon_data.acc_mult * ship_data[sh].acc_mult, HX_data[i].eva):
				var dmg = ship_data[sh].atk * Data[w_data][ship_data[sh][weapon_type].lv - 1].damage * ship_data[sh].atk_mult / pow(HX_data[i].def, DEF_EXPO_ENEMY)
				var crit = randf() < 0.1 + ((game.MUs.CHR - 1) * 0.025 if game else 0)
				if crit:
					dmg *= 1.5
				damage_HX(i, dmg, crit)
				light_hit = true
			else:
				Helper.show_dmg(0, HXs[i].position, self, 0.6, true)
		if light_hit:
			weapon_XPs[sh].light += 1
	else:
		if randf() < hit_formula(ship_data[sh].acc * weapon_data.acc_mult * ship_data[sh].acc_mult, HX_data[t].eva):
			var dmg = ship_data[sh].atk * Data[w_data][ship_data[sh][weapon_type].lv - 1].damage * ship_data[sh].atk_mult / pow(HX_data[weapon_data.target].def, DEF_EXPO_ENEMY)
			if game and weapon_type == "laser":
				dmg *= game.u_i.speed_of_light
			var crit = randf() < 0.1
			if crit:
				dmg *= 1.5
			damage_HX(t, dmg, crit)
			weapon_XPs[sh][weapon_type] += 1
			remove_weapon_b = true
		else:
			weapon_data.has_hit = true
			Helper.show_dmg(0, HXs[t].position, self, 0.6, true)
	$Timer.start(min(1.0, 1.0 / time_speed))
	return remove_weapon_b

func _process(delta):
	if is_instance_valid(star):
		star.scale += Vector2(0.12, 0.12) * delta * 60 * time_speed
		star.modulate.a -= 0.03 * delta * 60 * time_speed
		star.rotation += 0.04 * delta * 60 * time_speed
		if star.modulate.a <= 0:
			remove_child(star)
			star.free()
	var battle_lost:bool = true
	for i in len(ship_data):
		if ship_data[i].HP <= 0:
			self["ship%s" % i].modulate.a = max(self["ship%s" % i].modulate.a - 0.03, 0)
		else:
			battle_lost = false
	if battle_lost:
		for i in len(ship_data):
			ship_data[i].HP = ship_data[i].total_HP * ship_data[i].HP_mult
		game.switch_view("system")
		game.long_popup(tr("BATTLE_LOST_DESC"), tr("BATTLE_LOST"))
		return
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
		var ship0_dist:float = ship0.position.distance_to(Vector2(200, 200))
		ship0_engine.emitting = ship0_dist > 10
		ship1_engine.emitting = ship0_dist > 10
		ship2_engine.emitting = ship0_dist > 10
		ship3_engine.emitting = ship0_dist > 10
		ship0.position = ship0.position.move_toward(Vector2(200, 200), ship0_dist * delta * 5 * time_speed)
		ship1.position = ship1.position.move_toward(Vector2(400, 200), ship1.position.distance_to(Vector2(400, 200)) * delta * 5 * time_speed)
		ship2.position = ship2.position.move_toward(Vector2(200, 400), ship2.position.distance_to(Vector2(200, 400)) * delta * 5 * time_speed)
		ship3.position = ship3.position.move_toward(Vector2(400, 400), ship3.position.distance_to(Vector2(400, 400)) * delta * 5 * time_speed)
		current.position = self["ship%s" % [curr_sh]].position + Vector2(0, -65)
		var hitbox_size:float = hitbox_size()
		for i in len(ship_data):
			if ship_data[i].HP <= 0:
				continue
			var ship_i = self["ship%s" % i]
			ship_i.scale = ship_i.scale.move_toward(Vector2.ONE, ship_i.scale.distance_to(Vector2.ONE) * delta * 5 * time_speed)
			ship_i.modulate.a = min(ship_i.modulate.a + 0.03, 1)
	elif stage == BattleStages.ENEMY:
		var hitbox_size:float = hitbox_size()
		for i in len(ship_data):
			var ship_i = self["ship%s" % i]
			if i == tgt_sh:
				ship_i.scale = ship_i.scale.move_toward(Vector2.ONE * hitbox_size, ship_i.scale.distance_to(Vector2.ONE * hitbox_size) * delta * 5 * time_speed)
				ship_i.position.x = move_toward(ship_i.position.x, 200, (abs(int(ship_i.position.x - 200))) * delta * 5 * time_speed)
				if ship_data[i].HP > 0:
					ship_i.modulate.a = min(ship_i.modulate.a + 0.03 * time_speed, 1)
			else:
				ship_i.scale = ship_i.scale.move_toward(Vector2.ONE, ship_i.scale.distance_to(Vector2.ONE) * delta * 5 * time_speed)
				ship_i.modulate.a = max(ship_i.modulate.a - 0.03 * time_speed, 0.2)
		var boost:int = 2.5 if Input.is_action_pressed("shift") or Input.is_action_pressed("X") else 1.1
		if ship_dir == "left":
			self["ship%s" % tgt_sh].position.y = max(0, self["ship%s" % tgt_sh].position.y - 10 * boost * delta * 60 * time_speed)
			self["ship%s_engine" % tgt_sh].emitting = true
		elif ship_dir == "right":
			self["ship%s_engine" % tgt_sh].modulate.a = 0.2 * boost
			self["ship%s_engine" % tgt_sh].emitting = true
			self["ship%s" % tgt_sh].position.y = min(720, self["ship%s" % tgt_sh].position.y + 10 * boost * delta * 60 * time_speed)
		else:
			self["ship%s_engine" % tgt_sh].emitting = false
	for light in get_tree().get_nodes_in_group("lights"):
		light.scale += Vector2(0.1, 0.1) * delta * 60 * time_speed
		light.modulate.a -= 0.02 * delta * 60 * time_speed
		if light.modulate.a <= 0:
			light.remove_from_group("lights")
			remove_child(light)
			light.free()
	for weapon in get_tree().get_nodes_in_group("weapon"):
		var sh:int = w_c_d[weapon.name].shooter
		weapon.position += w_c_d[weapon.name].v * delta * 60 * time_speed
		var remove_weapon_b:bool = weapon.position.x > 1350
		if weapon.position.x > w_c_d[weapon.name].lim and not w_c_d[weapon.name].has_hit:
			remove_weapon_b = weapon_hit_HX(sh, w_c_d[weapon.name], weapon.position)
		if remove_weapon_b:
			weapon.remove_from_group("weapon")
			remove_child(weapon)
			weapon.queue_free()
	for weapon in get_tree().get_nodes_in_group("w_%s" % pattern):
		HX_w_c_d[weapon.name].delay -= delta * time_speed
		if HX_w_c_d[weapon.name].delay < 0:
			call("process_%s" % pattern, weapon, delta * 60 * time_speed)
	if a_p_c_d.has("pattern"):
		a_p_c_d.delay -= delta * time_speed
		HX_c_d[HXs[a_p_c_d.HX_id].name].position.y = a_p_c_d.y_poses[a_p_c_d.i]
		if a_p_c_d.delay < 0:
			a_p_c_d.delay = a_p_c_d.init_delay
			if a_p_c_d.i >= len(a_p_c_d.y_poses) - 1:
				a_p_c_d.clear()
			else:
				a_p_c_d.i += 1

func process_1_1(weapon, delta):
	if not HX_w_c_d[weapon.name].has("v"):
		var div:float = 150.0
		if e_diff == EDiff.EASY:
			div = 250
		elif e_diff == EDiff.HARD:
			div = 80
		HX_w_c_d[weapon.name].v = (weapon.position - self["ship%s" % tgt_sh].position) / div
		weapon.visible = true
	weapon.position -= HX_w_c_d[weapon.name].v * delta
	HX_w_c_d[weapon.name].v *= HX_w_c_d[weapon.name].spd_growth * delta + 1
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_1_1")

func process_1_2(weapon, delta):
	if HX_w_c_d[weapon.name].stage == 0:
		weapon.visible = true
		weapon.scale.y += HX_w_c_d[weapon.name].grow_spd * delta
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
		weapon.modulate.a -= 0.03 * delta
		if weapon.modulate.a <= 0:
			remove_weapon(weapon, "w_1_2")

func process_1_3(weapon, delta):
	if HX_w_c_d[weapon.name].stage == 0:
		weapon.visible = true
		weapon.position = weapon.position.move_toward(HX_w_c_d[weapon.name].target, weapon.position.distance_to(HX_w_c_d[weapon.name].target) * delta * 5 / 60.0)
		if HX_w_c_d[weapon.name].delay < -1:
			HX_w_c_d[weapon.name].stage = 1
		if HX_w_c_d[weapon.name].delay < -0.3:
			weapon.rotation = move_toward(weapon.rotation, 0, 0.12 * delta)
	else:
		weapon.position += HX_w_c_d[weapon.name].v * delta
		HX_w_c_d[weapon.name].v *= 0.02 * delta + 1
		if weapon.position.x < -100:
			remove_weapon(weapon, "w_1_3")

func process_2_1(weapon, delta):
	weapon.position.x -= 14 * delta
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_2_1")
	
func process_2_2(weapon, delta):
	if HX_w_c_d[weapon.name].stage == 0:
		weapon.position.y = move_toward(weapon.position.y, HX_w_c_d[weapon.name].y_target, abs(HX_w_c_d[weapon.name].y_target - weapon.position.y) * delta * 4 / 60.0)
		if HX_w_c_d[weapon.name].delay < -1.2:
			HX_w_c_d[weapon.name].stage = 1
	else:
		weapon.position -= (Vector2(HX_w_c_d[weapon.name].init_x, HX_w_c_d[weapon.name].y_target) - Vector2(-100, HX_w_c_d[weapon.name].y_target2)) * delta * 0.8 / 60.0
		if weapon.position.x < -100:
			remove_weapon(weapon, "w_2_2")

func process_2_3(weapon, delta):
	weapon.position += HX_w_c_d[weapon.name].v * delta
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_2_3")

func process_3_1(weapon, delta):
	weapon.visible = true
	weapon.position += HX_w_c_d[weapon.name].v * delta
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_3_1")

func process_3_2(weapon, delta):
	weapon.position -= Vector2(10, 0) * delta
	if weapon.position.x < 300:
		weapon.get_node("CollisionPolygon2D").disabled = false
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_3_2")

func process_3_3(weapon, delta):
	weapon.position.x -= 5 * delta
	if HX_w_c_d[weapon.name].has("vy"):
		HX_w_c_d[weapon.name].delay2 -= delta / 60.0
		if HX_w_c_d[weapon.name].delay2 < 0:
			weapon.visible = true
			weapon.position.y += HX_w_c_d[weapon.name].vy * delta
	if weapon.position.x < -150 or weapon.position.y < -20 or weapon.position.y > 740:
		remove_weapon(weapon, "w_3_3")

func process_4_1(weapon, delta):
	weapon.visible = true
	weapon.position += HX_w_c_d[weapon.name].v * delta
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_4_1")

func process_4_2(weapon, delta):
	weapon.visible = true
	weapon.rotation += 0.1 * delta
	weapon.position += HX_w_c_d[weapon.name].v * delta
	HX_w_c_d[weapon.name].v.x += HX_w_c_d[weapon.name].acc * delta
	if weapon.position.x > 1400:
		remove_weapon(weapon, "w_4_2")

func process_4_3(weapon, delta):
	weapon.position.x -= delta * HX_w_c_d[weapon.name].v_mult
	if weapon.position.x < -100:
		remove_weapon(weapon, "w_4_3")

func remove_weapon(weapon, group:String):
	weapon.remove_from_group(group)
	remove_child(weapon)
	weapon.queue_free()
	if get_tree().get_nodes_in_group(group).empty():
		$Timer.start()

func remove_targets():
	for target in get_tree().get_nodes_in_group("targets"):
		target.remove_from_group("targets")
		remove_child(target)
		target.queue_free()
	for HX in HXs:
		HX.get_node("HX").modulate.a = 1

func place_targets():
	remove_targets()
	var target_id:int = -1
	for i in len(HXs):
		if HX_data[i].HP <= 0:
			continue
		if target_id == -1:#A way to not show target buttons if there's only one target alive
			target_id = i
		else:
			target_id = -2
		var HX = HXs[i]
		HX.get_node("HX").modulate.a = 0.5
		var target = target_scene.instance()
		target.position = HX.position
		add_child(target)
		target.get_node("TextureButton").shortcut = ShortCut.new()
		target.get_node("TextureButton").shortcut.shortcut = InputEventAction.new()
		target.get_node("TextureButton").shortcut.shortcut.action = String((i % 4) + 1)
		target.get_node("TextureButton").connect("pressed", self, "on_target_pressed", [i])
		target.get_node("Label").text = String((i % 4) + 1)
		target.add_to_group("targets")
	if target_id != -2:
		on_target_pressed(target_id)

func on_target_pressed(target:int):
	var weapon_data = ship_data[curr_sh][weapon_type]
	$FightPanel.visible = false
	$Current.visible = false
	$Back.visible = false
	stage = BattleStages.PLAYER
	var ship_pos = self["ship%s" % [curr_sh]].position
	var HX_pos = Vector2(1000, 360) if target == -1 else HXs[target].position
	if weapon_type == "laser":
		$Laser.visible = true
		$Laser.rect_position = ship_pos
		$Laser.rect_rotation = rad2deg(atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x))
		if target % 2 == 0:
			$Laser.rect_scale.x = 1
		else:
			$Laser.rect_scale.x = 1.4
		$Laser/Texture.material["shader_param/beams"] = weapon_data.lv
		$Laser/Texture.material["shader_param/outline_thickness"] = weapon_data.lv * 0.02
		if weapon_data.lv == 2:
			$Laser/Texture.material["shader_param/outline_color"] = Color.orange
		elif weapon_data.lv == 3:
			$Laser/Texture.material["shader_param/outline_color"] = Color.yellow
		elif weapon_data.lv == 4:
			$Laser/Texture.material["shader_param/outline_color"] = Color.green
		$Laser/AnimationPlayer.play("LaserFade", -1, time_speed)
		weapon_hit_HX(curr_sh, {
			"target":target,
			"shooter":curr_sh,
			"acc_mult":Data.laser_data[weapon_data.lv - 1].accuracy,
			"has_hit":true})
	else:
		var weapon = Sprite.new()
		weapon.add_to_group("weapon")
		weapon.texture = load("res://Graphics/Weapons/%s%s.png" % [weapon_type, weapon_data.lv])
		weapon.position = ship_pos
		weapon.scale *= 0.5
		add_child(weapon)
		weapon.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
		w_c_d[weapon.name] = {"v":(HX_pos - ship_pos) / 30.0}
		w_c_d[weapon.name].target = target
		w_c_d[weapon.name].shooter = curr_sh
		w_c_d[weapon.name].lim = HX_pos.x
		w_c_d[weapon.name].acc_mult = Data["%s_data" % [weapon_type]][weapon_data.lv - 1].accuracy
		w_c_d[weapon.name].has_hit = false
	remove_targets()
	curr_sh += 1
	while curr_sh < len(ship_data) and ship_data[curr_sh].HP <= 0:
		curr_sh += 1

func _on_weapon_pressed(_weapon_type:String):
	if game:
		game.hide_tooltip()
	weapon_type = _weapon_type
	$FightPanel.visible = false
	if weapon_type == "light":
		on_target_pressed(-1)
	else:
		place_targets()

func _on_Timer_timeout():
	var HXs_rekt:int = wave * 4
	while curr_en < len(HX_data) and HX_data[curr_en].HP <= 0:
		HXs_rekt += 1
		curr_en += 1
	if HXs_rekt >= len(HX_data):
		victory_panel = victory_panel_scene.instance()
		victory_panel.HX_data = HX_data
		victory_panel.ship_data = ship_data
		victory_panel.weapon_XPs = weapon_XPs
		victory_panel.rect_position = Vector2(108, 60)
		victory_panel.p_id = game.c_p
		if hit_amount == 0:
			victory_panel.mult = 1.5
		elif hit_amount == 1:
			victory_panel.mult = 1.25
		elif hit_amount == 2:
			victory_panel.mult = 1.1
		else:
			victory_panel.mult = 1
		if e_diff == 1:
			victory_panel.diff_mult = 1.25
		elif e_diff == 2:
			victory_panel.diff_mult = 1.5
		else:
			victory_panel.diff_mult = 1
		add_child(victory_panel)
		return
	if HXs_rekt >= (wave + 1) * 4:
		wave += 1
		send_HXs()
		curr_sh = 0
		while ship_data[curr_sh].HP <= 0:
			curr_sh += 1
		curr_en = wave * 4
		stage = BattleStages.CHOOSING
		$FightPanel.visible = true
		refresh_fight_panel()
		$Current.visible = true
		$Back.visible = true
	else:
		if curr_sh >= len(ship_data):
			stage = BattleStages.ENEMY
			$Timer.wait_time = min(0.2, 0.2 / time_speed)
			tgt_sh = Helper.rand_int(1, len(ship_data)) - 1
			while ship_data[tgt_sh].HP <= 0:
				tgt_sh = Helper.rand_int(1, len(ship_data)) - 1
			enemy_attack()
		else:
			curr_en = wave * 4
			stage = BattleStages.CHOOSING
			$FightPanel.visible = true
			refresh_fight_panel()
			$Current.visible = true
			$Back.visible = true

var tween:Tween
func enemy_attack():
	if game and game.help.battle:
		tween = Tween.new()
		add_child(tween)
		$UI/Help2.modulate.a = 0
		$UI/Help2.visible = true
		tween.interpolate_property($UI/Help2, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.5)
		tween.interpolate_property($UI/Help2, "rect_position", Vector2(448, 263), Vector2(448, 248), 0.5)
		tween.start()
	else:
		if curr_en == min((wave + 1) * 4, len(HX_data)):
			curr_sh = 0
			while ship_data[curr_sh].HP <= 0:
				curr_sh += 1
			curr_en = wave * 4
			stage = BattleStages.CHOOSING
			$Timer.wait_time = min(1.0, 1.0 / time_speed)
			$FightPanel.visible = true
			$Back.visible = true
			$Current.visible = true
			refresh_fight_panel()
		else:
			pattern = "%s_%s" % [HX_data[curr_en].type, Helper.rand_int(1, 3)]
			call("atk_%s" % pattern, curr_en)
			curr_en += 1

func put_magic(id:int):
	star = Sprite.new()
	star.texture = preload("res://Graphics/Decoratives/Star2.png")
	star.position = HXs[id].position - Vector2(0, 15)
	star.scale *= 0.5
	add_child(star)

func atk_1_1(id:int):
	var num:int = 10
	var delay_mult:float = 0.3
	var spd_growth:float = 0.05
	if e_diff == EDiff.EASY:
		num = 7
		spd_growth = 0.04
		delay_mult = 0.4
	elif e_diff == EDiff.HARD:
		num = 15
		spd_growth = 0.06
		delay_mult = 0.2
	for i in num:
		var fireball = w_1_1.instance()
		fireball.position = HXs[id].position
		fireball.visible = false
		fireball.add_to_group("w_1_1")
		add_child(fireball)
		HX_w_c_d[fireball.name] = {"group":"w_1_1", "damage":2.5, "id":id, "delay":i * delay_mult, "spd_growth":spd_growth}

func atk_1_2(id:int):
	var delay_mult:float = 1.2
	var grow_spd:float = 0.004
	var num = 4
	var num2 = 2
	if e_diff == EDiff.EASY:
		grow_spd = 0.003
		num = 3
		delay_mult = 1.8
	elif e_diff == EDiff.HARD:
		num = 5
		delay_mult = 1.1
		num2 = 3
	for i in num:
		var y_pos:int = 0
		for j in num2:
			var beam = w_1_2.instance()
			var target:Vector2 = Vector2(0, rand_range(0, 720))
			if j == 0:
				y_pos = target.y
			else:
				while abs(target.y - y_pos) < 200:
					target.y = rand_range(0, 720)
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
			HX_w_c_d[beam.name] = {"group":"w_1_2", "damage":3, "stage":0, "id":id, "delay":i * delay_mult, "grow_spd":grow_spd}

func atk_1_3(id:int):
	var num1:int = 5
	var num2:int = 20
	var delay_mult:float = 0.8
	if e_diff == EDiff.EASY:
		num1 = 4
		num2 = 15
		delay_mult = 1.2
	elif e_diff == EDiff.HARD:
		num1 = 7
		num2 = 27
		delay_mult = 0.6
	for i in num1:
		for j in num2:
			var bullet = w_1_3.instance()
			var target:Vector2 = Vector2(1100, rand_range(0, 720))
			var pos = HXs[id].position
			bullet.position = pos
			bullet.rotation = atan2(pos.y - target.y, pos.x - target.x)
			bullet.visible = false
			bullet.scale *= 0.8
			bullet.add_to_group("w_1_3")
			add_child(bullet)
			HX_w_c_d[bullet.name] = {"group":"w_1_3", "v":Vector2(-1, 0), "target":target, "damage":2.5, "stage":0, "id":id, "delay":i * delay_mult}

func atk_2_1(id:int):
	put_magic(id)
	var delay_mult:float = 0.5
	var upper_bound:int = -50
	var upper_bound2:int = 230
	var lower_bound:int = 490
	var lower_bound2:int = 770
	if e_diff == EDiff.EASY:
		upper_bound2 = 180
		lower_bound = 540
		delay_mult = 0.65
	elif e_diff == EDiff.HARD:
		upper_bound = 130
		lower_bound2 = 670
	for i in 8:
		var pillar = w_2_1.instance()
		if i % 2 == 0:
			pillar.scale.y *= -1
			pillar.position.y = rand_range(upper_bound, upper_bound2)
		else:
			pillar.position.y = rand_range(lower_bound, lower_bound2)
		pillar.position.x = 1400
		add_child(pillar)
		pillar.add_to_group("w_2_1")
		HX_w_c_d[pillar.name] = {"group":"w_2_1", "damage":3, "id":id, "delay":i * delay_mult + 0.5}

func atk_2_2(id:int):
	put_magic(id)
	var delay_mult:float = 0.4
	var scale_mult:float = 0.8
	var num:int = 10
	if e_diff == EDiff.EASY:
		num = 8
		delay_mult = 0.7
		scale_mult = 0.7
	elif e_diff == EDiff.HARD:
		delay_mult = 0.2
		num = 16
		scale_mult = 1.0
	for i in num:
		var ball = w_2_2.instance()
		if i % 2 == 0:
			ball.position.y = -200
		else:
			ball.position.y = 920
		ball.scale *= scale_mult
		var y_target = rand_range(280, 440)
		var y_target2 = rand_range(-50, 770)
		while abs(y_target2 - y_target) < 100:
			y_target2 = rand_range(-50, 770)
		ball.position.x = rand_range(900, 1250)
		add_child(ball)
		ball.add_to_group("w_2_2")
		HX_w_c_d[ball.name] = {"group":"w_2_2", "init_x":ball.position.x, "y_target":y_target, "y_target2":y_target2, "stage":0, "damage":2.5, "id":id, "delay":i * delay_mult + 0.5}

func atk_2_3(id:int):
	put_magic(id)
	var num:int = 35
	var v_mult:float = 1
	var delay_mult:float = 0.15
	if e_diff == EDiff.EASY:
		num = 20
		v_mult = 0.8
		delay_mult = 0.25
	elif e_diff == EDiff.HARD:
		num = 45
		v_mult = 1.7
		delay_mult = 0.1
	for i in num:
		var mine = w_2_3.instance()
		var v:Vector2 = Vector2(-8, rand_range(0, 6))
		mine.position = Vector2(1350, rand_range(0, 720))
		mine.scale *= rand_range(0.6, 0.9)
		if mine.position.y > 360:
			v.y *= -1
		v *= (1.7 - mine.scale.x) * v_mult
		mine.rotation = rand_range(0, 2 * PI)
		add_child(mine)
		mine.add_to_group("w_2_3")
		HX_w_c_d[mine.name] = {"group":"w_2_3", "v":v, "damage":2.5, "id":id, "delay":i * delay_mult + 0.5}

func atk_3_1(id:int):
	a_p_c_d.clear()
	var y_poses = []
	var num:int = 6
	var delay:float = 0.8
	var proj_num_mult = 1.0
	var v_mult:float = 6
	if e_diff == EDiff.EASY:
		num = 4
		proj_num_mult = 0.7
		v_mult = 5
		delay = 1.0
	elif e_diff == EDiff.HARD:
		num = 9
		v_mult = 10
		delay = 0.6
	for i in num:#orange spikes
		var y_pos = rand_range(100, 620)
		y_poses.append(y_pos)
		var proj_num:int = (7 if id % 2 == 0 else 11) * proj_num_mult
		var spread:float = (0.2 if id % 2 == 0 else 0.13) / proj_num_mult
		for j in proj_num:
			var spike = w_3_1.instance()
			spike.rotation = (j - proj_num / 2) * spread
			spike.position = Vector2(HXs[id].position.x, y_pos)
			var v = -Vector2(cos(spike.rotation), sin(spike.rotation)) * v_mult
			spike.visible = false
			add_child(spike)
			spike.add_to_group("w_3_1")
			HX_w_c_d[spike.name] = {"group":"w_3_1", "id":id, "v":v, "damage":2.5, "delay":i * delay + 0.5}
	y_poses.append(HXs[id].position.y)
	a_p_c_d = {"pattern":"3_1", "HX_id":id, "y_poses":y_poses, "i":0, "delay":delay, "init_delay":delay}

func atk_3_2(id:int):
	put_magic(id)
	var path:int = Helper.rand_int(0, 12)
	var dir = rand_range(0.1, 0.9)
	while abs(dir - 0.5) < 0.2:
		dir = rand_range(0.1, 0.9)
	var dir_bool = true
	var gap:int = 4
	if e_diff == EDiff.EASY:
		gap = 5
	elif e_diff == EDiff.HARD:
		gap = 3
	for i in 50:
		for j in 16:
			if j >= path and j <= path + gap:
				continue
			var diamond = w_3_2.instance()
			diamond.position = Vector2(1350 + i * 48, j * 48)
			diamond.get_node("CollisionPolygon2D").disabled = true
			add_child(diamond)
			diamond.add_to_group("w_3_2")
			diamond.modulate = Color(rand_range(0.5, 1), rand_range(0.5, 1), rand_range(0.5, 1), 1)
			HX_w_c_d[diamond.name] = {"group":"w_3_2", "id":id, "damage":2.4, "delay":0.5}
		if randf() < 0.6:
			if dir_bool and randf() < dir or not dir_bool and randf() > dir:
				path -= 1
				if path < 0:
					dir_bool = not dir_bool
					path = 1
			else:
				path += 1
				if path > 12:
					dir_bool = not dir_bool
					path = 12

func atk_3_3(id:int):
	put_magic(id)
	var int_mult:float = 1.0
	if e_diff == EDiff.EASY:
		int_mult = 1.2
	elif e_diff == EDiff.HARD:
		int_mult = 0.8
	for i in 3:
		var platform = w_3_3_1.instance()
		platform.position = Vector2(1400, rand_range(200, 520))
		add_child(platform)
		platform.add_to_group("w_3_3")
		var platform_delay:float = i * 1.5 + 0.5
		HX_w_c_d[platform.name] = {"group":"w_3_3", "id":id, "damage":6, "delay":platform_delay}
		var interval:float = rand_range(0.65, 0.7) * int_mult
		for j in 14:
			var bullet = w_3_3_2.instance()
			bullet.position = Vector2(1400, platform.position.y)
			bullet.visible = false
			add_child(bullet)
			bullet.add_to_group("w_3_3")
			HX_w_c_d[bullet.name] = {"group":"w_3_3", "vy":3 if j % 2 == 0 else -3, "id":id, "damage":2.5, "delay":platform_delay, "delay2":interval * (j / 2)}

func atk_4_1(id:int):
	var num:int = 15
	var v_mult:float = 8
	var delay_mult:float = 0.2
	if e_diff == EDiff.EASY:
		num = 12
		v_mult = 6
		delay_mult = 0.3
	elif e_diff == EDiff.HARD:
		num = 35
		v_mult = 10
		delay_mult = 0.08
	for i in num:
		var light = w_4_1.instance()
		light.position = HXs[id].position
		light.scale *= 0.6
		var min_angle = atan2(light.position.y, light.position.x) + 0.2
		var max_angle = atan2(light.position.y - 720, light.position.x) - 0.2
		light.rotation = rand_range(min_angle, max_angle)
		light.visible = false
		var v = -Vector2(cos(light.rotation), sin(light.rotation)) * v_mult
		if HXs[id].position.x > 853:
			v *= 1.3
		add_child(light)
		light.add_to_group("w_4_1")
		HX_w_c_d[light.name] = {"group":"w_4_1", "id":id, "v":v, "damage":2, "delay":delay_mult * i}

func atk_4_2(id:int):
	a_p_c_d.clear()
	var y_poses = []
	var num:int = 5
	var v_mult:float = 22
	var delay:float = 0.6
	var acc:float = 0.25
	if e_diff == EDiff.EASY:
		num = 3
		v_mult = 15
		delay = 0.9
		acc = 0.16
	elif e_diff == EDiff.HARD:
		num = 7
		v_mult = 25
		acc = 0.27
	for i in num:
		var y_pos = rand_range(50, 670)
		y_poses.append(y_pos)
		var boomerang = w_4_2.instance()
		boomerang.position = Vector2(HXs[id].position.x, y_pos)
		var v = Vector2(-1, 0) * v_mult
		if HXs[id].position.x > 853:
			v *= 1.25
		boomerang.visible = false
		add_child(boomerang)
		boomerang.add_to_group("w_4_2")
		HX_w_c_d[boomerang.name] = {"group":"w_4_2", "id":id, "v":v, "damage":3, "delay":i * delay + 0.5, "acc":acc}
	y_poses.append(HXs[id].position.y)
	a_p_c_d = {"pattern":"4_2", "HX_id":id, "y_poses":y_poses, "i":0, "delay":delay, "init_delay":delay}

func atk_4_3(id:int):
	put_magic(id)
	var num:int = 6
	var delay_mult:float = 0.6
	var v_mult:float = 18
	if e_diff == EDiff.EASY:
		num = 4
		delay_mult = 0.9
		v_mult = 12
	elif e_diff == EDiff.HARD:
		num = 9
		delay_mult = 0.3
		v_mult = 21
	for i in num:
		var y_poses = [stepify(rand_range(0, 600), 120) + 64, stepify(rand_range(0, 600), 120) + 64, stepify(rand_range(0, 600), 120) + 64]
		while y_poses[1] == y_poses[0]:
			y_poses[1] = stepify(rand_range(0, 600), 120) + 64
		while y_poses[2] == y_poses[0] or y_poses[2] == y_poses[1]:
			y_poses[2] = stepify(rand_range(0, 600), 120) + 64
		for j in 3:
			var slab = w_4_3.instance()
			slab.position = Vector2(1350, y_poses[j])
			add_child(slab)
			slab.add_to_group("w_4_3")
			HX_w_c_d[slab.name] = {"group":"w_4_3", "id":id, "damage":4, "delay":delay_mult * i + 0.5, "v_mult":v_mult}

func _on_Ship_area_entered(area, ship_id:int):
	if immune or self["ship%s" % ship_id].modulate.a != 1.0:
		return
	var HX = HX_data[HX_w_c_d[area.name].id]
	if randf() < hit_formula(HX.acc, ship_data[ship_id].eva * ship_data[ship_id].eva_mult):
		var dmg:int = HX_w_c_d[area.name].damage * HX.atk / pow(ship_data[ship_id].def * ship_data[ship_id].def_mult, DEF_EXPO_SHIP)
		Helper.show_dmg(dmg, self["ship%s" % ship_id].position, self, 0.6)
		ship_data[ship_id].HP -= dmg
	else:
		Helper.show_dmg(0, self["ship%s" % ship_id].position, self, 0.6, true)
	$ImmuneTimer.start()
	hit_amount += 1
	immune = true
	if not HX_w_c_d[area.name].group in ["w_1_2", "w_2_1", "w_3_3"]:
		remove_weapon(area, HX_w_c_d[area.name].group)
	get_node("Ship%s/HP" % [ship_id]).value = ship_data[ship_id].HP

func _on_ImmuneTimer_timeout():
	immune = false

func _on_Battle_tree_exited():
	queue_free()

func _on_weapon_mouse_entered(weapon:String):
	if game:
		var w_lv:int = ship_data[curr_sh][weapon].lv
		game.show_tooltip("%s %s %s\n%s: %s\n%s: %s" % [tr(weapon.to_upper()), tr("LV"), w_lv, tr("BASE_DAMAGE"), Data["%s_data" % [weapon]][w_lv - 1].damage, tr("BASE_ACCURACY"), Data["%s_data" % [weapon]][w_lv - 1].accuracy])

func _on_weapon_mouse_exited():
	if game:
		game.hide_tooltip()

func _on_Easy_mouse_entered():
	$UI/Help2/Loot.text = "%s: x %s" % [tr("LOOT_XP_BONUS"), 1]

func _on_diff_mouse_exited():
	$UI/Help2/Loot.text = ""

func _on_Normal_mouse_entered():
	$UI/Help2/Loot.text = "%s: x %s" % [tr("LOOT_XP_BONUS"), 1.25]


func _on_Hard_mouse_entered():
	$UI/Help2/Loot.text = "%s: x %s" % [tr("LOOT_XP_BONUS"), 1.5]


func _on_diff_pressed(diff:int):
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("game", "e_diff", diff)
		config.save("user://settings.cfg")
		e_diff = diff
	$UI/Help2.visible = false
	tween.stop_all()
	tween.free()
	tween = Tween.new()
	add_child(tween)
	$Help.modulate.a = 0
	$Help.visible = true
	tween.interpolate_property($Help, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.5)
	tween.interpolate_property($Help, "rect_position", Vector2(0, 354), Vector2(0, 339), 0.5)
	tween.start()


func _on_AnimationPlayer_animation_finished(anim_name):
	$Laser.visible = false
