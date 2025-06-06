extends Control

@onready var game = get_node("/root/Game")
@onready var current = $UI/Current
@onready var ship0 = $Ship0
@onready var ship0_engine = $Ship0/Fire
@onready var ship1 = $Ship1
@onready var ship1_engine = $Ship1/Fire
@onready var ship2 = $Ship2
@onready var ship2_engine = $Ship2/Fire
@onready var ship3 = $Ship3
@onready var ship3_engine = $Ship3/Fire
var star_texture = preload("res://Graphics/Effects/spotlight_8_s.png")
var star_shader = preload("res://Shaders/Star.gdshader")
var time_speed:float = 1.0
var hard_battle:bool = false
var max_lv_ship:int = 0
var green_enemy:int = -1
var purple_enemy:int = -1
var HXs_rekt:int = 0

enum EDiff {EASY, NORMAL, HARD}
var e_diff:int = 2

var victory_panel_scene = preload("res://Scenes/Panels/VictoryPanel.tscn")
var HX1_scene = preload("res://Scenes/Battle/HX.tscn")
var target_scene = preload("res://Scenes/TargetButton.tscn")
var HP_icon = preload("res://Graphics/Icons/HP.png")
var atk_icon = preload("res://Graphics/Icons/attack.png")
var def_icon = preload("res://Graphics/Icons/defense.png")
var acc_icon = preload("res://Graphics/Icons/accuracy.png")
var eva_icon = preload("res://Graphics/Icons/agility.png")
var w_1_1
var w_1_2
var w_1_3
var w_2_1
var w_2_2
var w_2_3
var w_3_1
var w_3_2
var w_3_3_1
var w_3_3_2
var w_4_1
var w_4_2
var w_4_3

var star:Sprite2D#Shown right before HX magic

var ship_data:Array = []# = [{"lv":1, "HP":40, "total_HP":40, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "name":"???" "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}, "upgrades":[1.0,1.0,1.0,1.0,1.0], "rage":0, "ability":"none", "superweapon":"none"}]
var HX_data:Array
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
var light_mult:float
var ship_buffs = []
var pending_supers = {}

var victory_panel

enum BattleStages {START, CHOOSING, TARGETING, PLAYER, ENEMY}
enum MoveMethod {STANDARD, MOUSE, FRICTION, CLICK}#Standard: red enemies, mouse: green enemies, gravity: blue enemies, click: purple

var stage = BattleStages.START
var move_method = MoveMethod.STANDARD

func _ready():
	if game.subject_levels.dimensional_power >= 4:
		time_speed = log(game.u_i.time_speed - 1.0 + exp(1.0))
	else:
		time_speed = game.u_i.time_speed
	$CurrentPattern.visible = false#not OS.has_feature("standalone")
	$Timer.wait_time = min(1.0, 1.0 / time_speed)
	Helper.set_back_btn($UI/Back)
	randomize()
	var total_enemy_stats:float = 0.0
	var total_ship_stats:float = 0.0
	var bright_star:bool = false
	$WorldEnvironment.environment.glow_enabled = Settings.enable_shaders
	ship_data = game.ship_data
	var p_i:Dictionary = game.planet_data[game.c_p]
	if game.is_conquering_all:
		HX_data = Helper.get_conquer_all_data().HX_data
	else:
		HX_data = p_i.HX_data
	for HX in HX_data:
		var total_stats = pow(HX.total_HP, 2) + pow(HX.atk * 2.5, 2) + pow(HX.acc, 2) + pow(HX.eva, 2)
		total_enemy_stats += total_stats
		HX.total_stats = total_stats
	HX_data.sort_custom(func(a, b): return a.total_stats > b.total_stats)
	HX_data = HX_data.slice(0, 12)
	var orbit_vector = Vector2(cos(p_i.angle - PI/2), sin(p_i.angle + PI/2)).rotated(PI / 2.0) * Vector2(-1, 0)
	var max_star_lum:float = 0.0
	var max_star_size:float = 0.0
	for star in game.system_data[game.c_s].stars:
		var shift:float = 0
		shift = orbit_vector.dot(star.pos) * 1000.0 / p_i.distance
		var star_spr = Sprite2D.new()
		star_spr.texture = load("res://Graphics/Effects/spotlight_%s.png" % [int(star.temperature) % 3 + 4])
		star_spr.scale *= 0.5 * star.size / (p_i.distance / 500)
		var star_mod = Helper.get_star_modulate(star["class"])
		
		star_spr.material = ShaderMaterial.new()
		star_spr.material.shader = preload("res://Shaders/Star.gdshader")
		star_spr.material.set_shader_parameter("time_offset", 10.0 * randf())
		star_spr.material.set_shader_parameter("color", star_mod)
		#star_spr.material.set_shader_parameter("alpha", 0.0)
		star_spr.modulate = star_mod# * clamp(remap(star_spr.scale.x, 1.0, 2.25, 1.5, 1.02), 1.02, 1.5)
		
		star_spr.position.x = remap(p_i.angle, 0, 2 * PI, 100, 1180) + shift
		star_spr.position.y = 200 * cos(game.c_p * 10) + 300
		if star_spr.scale.x > 2:
			bright_star = true
			star_spr.material = CanvasItemMaterial.new()
			star_spr.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		$BG.material.shader = preload("res://Shaders/PlanetBG.gdshader")
		if star.luminosity > max_star_lum:
			$BG.material.set_shader_parameter("strength", max(0.3, sqrt(star_spr.scale.x)))
			$BG.material.set_shader_parameter("lum", min(0.3, pow(star.luminosity, 0.2)))
			$BG.material.set_shader_parameter("star_mod", Helper.get_star_modulate(star["class"]))
			$BG.material.set_shader_parameter("u", remap(star_spr.position.x, 0, 1280, 0.0, 1.0))
			max_star_lum = star.luminosity
		if star_spr.scale.x > max_star_size:
			max_star_size = star_spr.scale.x
		$Stars.add_child(star_spr)
	light_mult = remap(min(max_star_size, 0.4), 0.4, 0.0, 1.0, 3.0)
	if not p_i.type in [11, 12]:
		$BG.texture = load("res://Graphics/Planets/BGs/%s.png" % p_i.type)
	else:
		$BG.texture = null
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		e_diff = config.get_value("game", "e_diff", 1)
	$Ship0/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship1/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship2/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$Ship3/Sprite2D.material.set_shader_parameter("frequency", 6 * time_speed)
	$UI/FightPanel/Panel/BattleProgress.text = "%s / %s" % [HXs_rekt, len(HX_data)]
	$UI/ControlKeyboard/GoUp.text = OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_W))
	$Help.text = "%s\n%s\n%s" % [tr("BATTLE_HELP"), tr("BATTLE_HELP2") % [OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_W)), OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_S)), "Shift"], tr("PRESS_ANY_KEY_TO_CONTINUE")]
	$UI/Current.material["shader_parameter/frequency"] = 12.0 * time_speed
	for i in len(ship_data):
		max_lv_ship = max(max_lv_ship, ship_data[i].lv)
		ship_data[i].HP = ship_data[i].total_HP * ship_data[i].HP_mult
		ship_data[i].rage = 0
		total_ship_stats += pow(ship_data[i].total_HP, 2)
		total_ship_stats += pow(ship_data[i].atk * (Data.bullet_data[ship_data[i].bullet.lv - 1].damage + Data.laser_data[ship_data[i].laser.lv - 1].damage + Data.bomb_data[ship_data[i].bomb.lv - 1].damage + Data.light_data[ship_data[i].light.lv - 1].damage) / 4.0, 2)
		total_ship_stats += pow(ship_data[i].acc, 2)
		total_ship_stats += pow(ship_data[i].eva, 2)
		get_node("Ship%s" % i).visible = true
		get_node("Ship%s/CollisionShape2D" % i).disabled = false
		weapon_XPs.append({"bullet":0, "laser":0, "bomb":0, "light":0})
		get_node("Ship%s/HP" % i).max_value = ship_data[i].total_HP * ship_data[i].HP_mult
		get_node("Ship%s/HP" % i).value = ship_data[i].HP
		get_node("Ship%s/Rage" % i).value = ship_data[i].rage
		get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
		ship_buffs.append({"acc":0, "atk":0})
	total_ship_stats *= max(log(game.u_i.speed_of_light - 1.0 + exp(1.0)), max(log(game.u_i.planck - 1.0 + exp(1.0)), log(game.u_i.charge - 1.0 + exp(1.0))))
	if bright_star:
		$WorldEnvironment.environment.adjustment_enabled = true
		$WorldAnim.play("WorldAnim")
	else:
		$WorldEnvironment.environment.adjustment_enabled = false
	$CurrentPattern.text = "Ship strength: %s | Enemy strength: %s" % [Helper.format_num(total_ship_stats), Helper.format_num(total_enemy_stats)]
	game.get_node("ShaderExport/SubViewport/Starfield").material.set_shader_parameter("position", (game.system_data[game.c_s].pos / 10000.0).rotated(game.planet_data[game.c_p].angle))
	game.update_starfield_BG()
	if total_enemy_stats > total_ship_stats:
		hard_battle = true
		$UI/FightPanel.modulate.a = 0
		$UI/Back.modulate.a = 0
		$InitialFade.play("SceneFade", -1, 0.5)
		game.switch_music(preload("res://Audio/op_battle.ogg"), game.u_i.time_speed)
		await get_tree().create_timer(0.5).timeout
		send_HXs()
		await get_tree().create_timer(1.0).timeout
		refresh_fight_panel()
		stage = BattleStages.CHOOSING
	else:
		$InitialFade.play("SceneFade")
		send_HXs()
		refresh_fight_panel()
		stage = BattleStages.CHOOSING

func refresh_fight_panel():
	$UI/FightPanel/AnimationPlayer.play("FightPanelAnim")
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		get_node("UI/FightPanel/%s/TextureRect" % [weapon]).texture = load("res://Graphics/Weapons/%s%s.png" % [weapon.to_lower(), ship_data[curr_sh][weapon.to_lower()].lv])
	$UI/FightPanel/Ability.visible = false
	if ship_data[curr_sh].ability != "none":
		$UI/FightPanel/Ability.visible = true
		$UI/FightPanel/Ability/TextureRect.texture = load("res://Graphics/Buttons/%s.png" % ship_data[curr_sh].ability)
	$UI/FightPanel/Superweapon.visible = false
	if ship_data[curr_sh].superweapon != "none":
		$UI/FightPanel/Superweapon.visible = true
		$UI/FightPanel/Superweapon/TextureRect.texture = load("res://Graphics/Buttons/%s.png" % ship_data[curr_sh].superweapon)
	#$UI/FightPanel/Superweapon/Glow/AnimationPlayer.seek(0)
	$UI/FightPanel/Superweapon/Glow/AnimationPlayer.stop()
	if curr_sh in pending_supers.keys() && pending_supers[curr_sh] == 0:
		$UI/FightPanel/Superweapon/Glow/AnimationPlayer.play("Glow")

func send_HXs():
	for j in 4:
		var k:int = j + wave * 4
		if k >= len(HX_data):
			break
		var btn = TextureButton.new()
		btn.position = -Vector2(90, 50)
		btn.size = Vector2(180, 100)
		var HX = HX1_scene.instantiate()
		if HX_data[k]["class"] == 2:
			green_enemy = k
		elif HX_data[k]["class"] == 2:
			purple_enemy = k
		HX.get_node("Sprite2D").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data[k]["class"], HX_data[k].type])
		HX.get_node("Sprite2D").material.set_shader_parameter("frequency", 6 * time_speed)
		HX.scale *= 0.4
		HX.get_node("Info/HP").max_value = HX_data[k].total_HP
		HX.get_node("Info/HP").value = HX_data[k].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[k].lv]
		if hard_battle:
			HX.get_node("LabelAnimation").play("LabelAnim")
		HX.position = Vector2(2000, 360)
		HX.add_child(btn)
		btn.connect("mouse_entered",Callable(self,"on_HX_over").bind(k))
		btn.connect("mouse_exited",Callable(self,"on_HX_out"))
		HX.get_node("Info/Effects/Fire").connect("mouse_entered",Callable(self,"on_effect_over").bind(tr("BURN_DESC")))
		HX.get_node("Info/Effects/Fire").connect("mouse_exited",Callable(self,"on_effect_out"))
		HX.get_node("Info/Effects/Stun").connect("mouse_entered",Callable(self,"on_effect_over").bind(tr("STUN_DESC")))
		HX.get_node("Info/Effects/Stun").connect("mouse_exited",Callable(self,"on_effect_out"))
		add_child(HX)
		HXs.append(HX)
		HX_c_d[HX.name] = {"position":Vector2((j % 2) * 300 + 850, (j / 2) * 200 + 200)}

func on_effect_over(st:String):
	if game:
		game.show_tooltip(st)

func on_effect_out():
	if game:
		game.hide_tooltip()

func on_HX_over(id:int):
	if game:
		game.show_tooltip("@i %s / %s\n@i %s   @i %s\n@i %s   @i %s" % [
			ceil(HX_data[id].HP),
			HX_data[id].total_HP,
			round(HX_data[id].atk * (1.0 + HX_c_d[HXs[id].name].atk if HX_c_d[HXs[id].name].has("atk") else 1.0)),
			HX_data[id].def,
			round(HX_data[id].acc * (1.0 + HX_c_d[HXs[id].name].acc if HX_c_d[HXs[id].name].has("acc") else 1.0)),
			HX_data[id].eva,
			],
			[HP_icon, atk_icon, def_icon, acc_icon, eva_icon])

func on_HX_out():
	if game:
		game.hide_tooltip()

var mouse_pos:Vector2 = Vector2.ZERO
func _input(event):
	Helper.set_back_btn($UI/Back)
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	if stage == BattleStages.TARGETING and Input.is_action_just_released("right_click"):
		remove_targets()
		stage = BattleStages.CHOOSING
		if $UI/FightPanel.modulate.a < 1:
			refresh_fight_panel()
	else:
		if move_method == MoveMethod.CLICK:
			var curr_ship = self["ship%s" % tgt_sh]
			if Input.is_action_just_pressed("left_click"):
				if curr_ship.get_node("Sprite2D").flip_v:
					curr_ship.y_speed = -3.0
				else:
					curr_ship.y_speed = 3.0
			if Input.is_action_just_pressed("right_click"):
				curr_ship.get_node("Sprite2D").flip_v = not curr_ship.get_node("Sprite2D").flip_v
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
			HX.get_node("Info/Label")["theme_override_colors/font_color"] = Color.WHITE
		for i in len(ship_data):
			get_node("Ship%s/Icon" % i).visible = false
			get_node("Ship%s/Label" % i).text = "%s %s" % [tr("LV"), ship_data[i].lv]
	if Input.is_action_just_pressed("W"):
		ship_dir = "left"
	if Input.is_action_just_pressed("S"):
		ship_dir = "right"
	if Input.is_action_just_released("W") and Input.is_action_pressed("S"):
		ship_dir = "right"
	elif Input.is_action_just_released("W"):
		ship_dir = ""
	if Input.is_action_just_released("S") and Input.is_action_pressed("W"):
		ship_dir = "left"
	elif Input.is_action_just_released("S"):
		ship_dir = ""
	if $Help.modulate.a == 1:
		if game.help.has("battle") and event is InputEventKey:
			game.help.erase("battle")
			$Help/AnimationPlayer.play_backwards("Fade")
			enemy_attack()
		elif green_enemy != -1 and event is InputEventMouseButton:
			game.help.erase("battle")
			game.help.erase("battle2")
			green_enemy = -1
			$Help/AnimationPlayer.play_backwards("Fade")
			enemy_attack()
		elif purple_enemy != -1 and event is InputEventMouseButton:
			game.help.erase("battle")
			game.help.erase("battle3")
			purple_enemy = -1
			$Help/AnimationPlayer.play_backwards("Fade")
			enemy_attack()

func display_stats(type:String):
	for i in len(HXs):
		var HX = HXs[i]
		HX.get_node("Info/Icon").visible = true
		HX.get_node("Info/Icon").texture = self["%s_icon" % [type]]
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [Helper.format_num(HX_data[i].HP), Helper.format_num(HX_data[i].total_HP)]
		else:
			if HX_c_d[HXs[i].name].has(type):
				if HX_c_d[HXs[i].name][type] > 0:
					HX.get_node("Info/Label")["theme_override_colors/font_color"] = Color.GREEN
				elif HX_c_d[HXs[i].name][type] < 0:
					HX.get_node("Info/Label")["theme_override_colors/font_color"] = Color.RED
				HX.get_node("Info/Label").text = Helper.format_num(round(HX_data[i][type] * (1.0 + HX_c_d[HXs[i].name][type])))
			else:
				HX.get_node("Info/Label").text = Helper.format_num(HX_data[i][type])
	for i in len(ship_data):
		get_node("Ship%s/Icon" % i)
		get_node("Ship%s/Icon" % i).visible = true
		get_node("Ship%s/Icon" % i).texture = self["%s_icon" % [type]]
		if type == "HP":
			get_node("Ship%s/Label" % i).text = "%s / %s" % [Helper.format_num(ship_data[i].HP), Helper.format_num(ship_data[i].total_HP * ship_data[i].HP_mult)]
		else:
			get_node("Ship%s/Label" % i).text = Helper.format_num(round(ship_data[i][type] * ship_data[i]["%s_mult" % type] * (1 + ship_buffs[i][type]) if ship_buffs[i].has(type) else 1.0))

func _on_Back_pressed():
	if $UI/Back.modulate.a < 1:
		return
	if hard_battle:
		game.switch_music(load("res://Audio/ambient" + str(Helper.rand_int(1, 3)) + ".ogg"), game.u_i.time_speed)
	game.switch_view("system")

var ship_dir:String = ""

func damage_HX(id:int, dmg:float, crit:bool = false):
	HX_data[id].HP -= round(dmg)
	HXs[id].get_node("Info/HP").value = HX_data[id].HP
	Helper.show_dmg(round(dmg), HXs[id].position, self, 40, false, crit)
	if HX_data[id].HP <= 0 and not HX_data[id].has("rekt"):
		HXs_rekt += 1
		HX_data[id].rekt = true
		$UI/FightPanel/Panel/BattleProgress.text = "%s / %s" % [HXs_rekt, len(HX_data)]

func hit_formula(acc:float, eva:float):
	return clamp(1 / (1 + eva / (acc * (game.maths_bonus.COSHEF if game else 1.5))), 0.05, 0.95)

func hitbox_size():
	if game:
		return 1 - (game.MUs.SHSR - 1) * 0.01
	else:
		return 1

func set_buff_text(buff:float, buff_type:String, node):
	if buff != 0:
		node.get_node("Info/Effects/%s" % buff_type).visible = true
		node.get_node("Info/Effects/%sLabel" % buff_type).visible = true
		node.get_node("Info/Effects/%sLabel" % buff_type).text = "%s%%" % (buff * 100)
		if buff > 0:
			node.get_node("Info/Effects/%sLabel" % buff_type)["theme_override_colors/font_color"] = Color.GREEN
		elif buff < 0:
			node.get_node("Info/Effects/%sLabel" % buff_type)["theme_override_colors/font_color"] = Color.RED
	else:
		node.get_node("Info/Effects/%s" % buff_type).visible = false
		node.get_node("Info/Effects/%sLabel" % buff_type).visible = false

func on_explosion_finished(animation, explosion:Node2D):
	remove_child(explosion)
	explosion.queue_free()

func weapon_hit_HX(sh:int, w_c_d:Dictionary, weapon = null):
	var timer_delay:float = 1.0
	var w_data = "%s_data" % [weapon_type]
	var t = w_c_d.target
	var remove_weapon_b:bool = false
	var weapon_lv:int = ship_data[sh][weapon_type].lv
	var acc_buff
	var atk_buff
	if weapon_type == "light":
		remove_weapon_b = true
		var light = Sprite2D.new()
		light.texture = preload("res://Graphics/Decoratives/light.png")
		light.position = Vector2(1000, 360)
		light.scale *= 0.2
		light.modulate *= 0.8 + weapon_lv / 16.0
		add_child(light)
		light.add_to_group("lights")
		var light_hit:bool = false
		for i in len(HXs):
			if HX_data[i].HP <= 0:
				continue
			if HX_c_d[HXs[i].name].has("stun") or randf() < hit_formula(ship_data[sh].acc * w_c_d.acc_mult * ship_data[sh].acc_mult * (1 + ship_buffs[sh].acc), HX_data[i].eva):
				var dmg = ship_data[sh].atk * Data[w_data][weapon_lv - 1].damage * light_mult * ship_data[sh].atk_mult * (1 + ship_buffs[sh].atk) / HX_data[i].def
				dmg *= log(game.u_i.speed_of_light - 1.0 + exp(1.0))
				var crit = randf() < 0.1 + ((game.MUs.CHR - 1) * 0.01 if game else 0)
				if crit:
					dmg *= 1.5
				damage_HX(i, dmg, crit)
				light_hit = true
				HXs[i].get_node("HurtAnimation").stop()
				HXs[i].get_node("HurtAnimation").play("Hurt", -1, time_speed)
				HXs[i].get_node("KnockbackAnimation").stop()
				HXs[i].get_node("KnockbackAnimation").play("Small knockback" if HX_data[i].HP > 0 else "Dead", -1, time_speed)
				HXs[i].get_node("LightParticles").emitting = true
				var int_mult:float = pow(light_mult * remap(weapon_lv, 1, 4, 1, 2), 0.7)
				HXs[i].get_node("LightParticles").lifetime = int_mult
				HXs[i].get_node("LightParticles").speed_scale = time_speed
				HXs[i].get_node("LightParticles").amount = int(50 * int_mult)
				HXs[i].get_node("LightParticles").process_material.initial_velocity_min = 250.0 * int_mult
				HXs[i].get_node("LightParticles").process_material.initial_velocity_max = 250.0 * int_mult
				HXs[i].get_node("LightParticles").process_material.scale_min = 0.1 * int_mult
				HXs[i].get_node("LightParticles").process_material.scale_max = 0.1 * int_mult
				var debuff:float = -0.2 - weapon_lv * 0.1
				if HX_c_d[HXs[i].name].has("acc"):
					HX_c_d[HXs[i].name].acc = max(debuff, HX_c_d[HXs[i].name].acc + debuff)
				else:
					HX_c_d[HXs[i].name].acc = debuff
				set_buff_text(HX_c_d[HXs[i].name].acc, "Acc", HXs[i])
			else:
				HXs[i].get_node("MissAnimation").stop()
				HXs[i].get_node("MissAnimation").play("Miss", -1, time_speed)
				Helper.show_dmg(0, HXs[i].position, self, 30, true)
		if light_hit:
			weapon_XPs[sh].light += 1
	else:
		if HX_c_d[HXs[t].name].has("stun") or randf() < hit_formula(ship_data[sh].acc * w_c_d.acc_mult * ship_data[sh].acc_mult * (1 + ship_buffs[sh].acc), HX_data[t].eva):
			var dmg = ship_data[sh].atk * Data[w_data][weapon_lv - 1].damage * ship_data[sh].atk_mult * (1 + ship_buffs[sh].atk) / HX_data[w_c_d.target].def
			if game:
				if weapon_type in ["bullet", "bomb"]:
					dmg *= log(game.u_i.planck - 1.0 + exp(1.0))
				elif weapon_type == "laser":
					dmg *= log(game.u_i.charge - 1.0 + exp(1.0))
			var crit = randf() < 0.1 + ((game.MUs.CHR - 1) * 0.01 if game else 0)
			if crit:
				dmg *= 1.5
			damage_HX(t, dmg, crit)
			HXs[t].get_node("HurtAnimation").stop()
			HXs[t].get_node("HurtAnimation").play("Hurt", -1, time_speed)
			if weapon_type == "bullet":
				HXs[t].get_node("BulletParticles").emitting = true
				HXs[t].get_node("BulletParticles").speed_scale = time_speed
				HXs[t].get_node("KnockbackAnimation").stop()
				HXs[t].get_node("KnockbackAnimation").play("Knockback" if HX_data[t].HP > 0 else "Dead", -1, time_speed)
				weapon_XPs[sh][weapon_type] += 1
			elif weapon_type == "bomb":
				var impact_light = Sprite2D.new()
				impact_light.texture = preload("res://Graphics/Misc/bullet.png")
				impact_light.scale *= 4.0
				impact_light.position = HXs[t].position
				add_child(impact_light)
				var tween = get_tree().create_tween()
				tween.set_speed_scale(time_speed)
				tween.tween_property(impact_light, "modulate:a", 0.0, 0.2)
				tween.tween_callback(impact_light.queue_free)
				HXs[t].get_node("BombParticles").amount = 100 + 50 * weapon_lv 
				HXs[t].get_node("BombParticles").emitting = true
				HXs[t].get_node("BombParticles").speed_scale = time_speed
				HX_c_d[HXs[t].name].burn = weapon_lv
				HXs[t].get_node("Sprite2D/Fire").visible = true
				HXs[t].get_node("Info/Effects/Fire").visible = true
				HXs[t].get_node("Info/Effects/FireLabel").visible = true
				HXs[t].get_node("Info/Effects/FireLabel").text = str(weapon_lv)
				var white_rect:ColorRect = $UI/WhiteRect
				white_rect.color.a = 0.05
				var tween_white_rect = get_tree().create_tween()
				tween_white_rect.set_speed_scale(time_speed)
				tween_white_rect.tween_property(white_rect, "color:a", 0.0, 0.3)
				#duration = 0.2, frequency = 15, amplitude = 16, priority = 0
				if Settings.screen_shake:
					get_node("/root/Game/Camera2D/Screenshake").start(0.5,15,4)
				HXs[t].get_node("KnockbackAnimation").stop()
				HXs[t].get_node("KnockbackAnimation").play("Big knockback" if HX_data[t].HP > 0 else "Dead", -1, time_speed)
				weapon_XPs[sh][weapon_type] += weapon_lv
				timer_delay = 1.3
			elif weapon_type == "laser":
				if not HX_c_d[HXs[t].name].has("stun"):
					HX_c_d[HXs[t].name].stun = weapon_lv
					HXs[t].get_node("Info/Effects/StunLabel").text = str(weapon_lv)
				HXs[t].get_node("Sprite2D/Stun").visible = true
				HXs[t].get_node("Info/Effects/Stun").visible = true
				HXs[t].get_node("Info/Effects/StunLabel").visible = true
				HXs[t].get_node("KnockbackAnimation").stop()
				HXs[t].get_node("KnockbackAnimation").play("Small knockback" if HX_data[t].HP > 0 else "Dead", -1, time_speed)
				weapon_XPs[sh][weapon_type] += weapon_lv
			var all_dead:bool = true
			var last_id:int = min((wave + 1) * 4, len(HXs))
			for i in range(wave * 4, last_id):
				if HX_data[i].HP > 0 and t != i:
					all_dead = false
					break
			if w_c_d.has("bounces_remaining") and not all_dead:
				var new_t:int = t
				var old_t:int = t
				remove_weapon_b = w_c_d.bounces_remaining <= 0
				if not remove_weapon_b:
					while new_t == t or HX_data[new_t].HP <= 0:
						new_t = Helper.rand_int(wave * 4, last_id - 1)
					var HX_pos:Vector2 = HXs[new_t].position
					weapon.rotation = atan2(HX_pos.y - HXs[old_t].position.y, HX_pos.x - HXs[old_t].position.x)
					w_c_d.v = 30.0 * Vector2.from_angle(weapon.rotation)
					if is_zero_approx(w_c_d.v.x):
						w_c_d.v.x = 0.0
					w_c_d.target = new_t
					w_c_d.lim = HX_pos
					w_c_d.has_hit = false
					w_c_d.bounces_remaining -= 1
				else:
					w_c_d.has_hit = true
			else:
				w_c_d.has_hit = true
				remove_weapon_b = not w_c_d.has("bounces_remaining")
		else:
			w_c_d.has_hit = true
			HXs[t].get_node("MissAnimation").stop()
			HXs[t].get_node("MissAnimation").play("Miss", -1, time_speed)
			Helper.show_dmg(0, HXs[t].position, self, 30, true)
	$Timer.start(min(timer_delay, timer_delay / time_speed))
	return remove_weapon_b

func _process(delta):
	var time_mult:float = delta * 60.0 * time_speed
	$UI/FightPanel.visible = $UI/FightPanel.modulate.a > 0
	if is_instance_valid(star):
		star.scale += Vector2(0.12, 0.12) * time_mult
		star.modulate.a -= 0.03 * time_mult
		star.rotation += 0.04 * time_mult
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
		if hard_battle:
			game.switch_music(load("res://Audio/ambient" + str(Helper.rand_int(1, 3)) + ".ogg"), game.u_i.time_speed)
		game.switch_view("system")
		game.popup_window(tr("BATTLE_LOST_DESC"), tr("BATTLE_LOST"))
		return
	for i in len(HXs):
		var HX = HXs[i]
		if HX_data[i].HP <= 0 and HX.get_node("Sprite2D").modulate.a > 0:
			if HX_data[i].lv >= max_lv_ship + 30 and not game.achievement_data.random.has("rekt_enemy_30_levels_higher"):
				game.earn_achievement("random", "rekt_enemy_30_levels_higher")
		var pos = HX_c_d[HX.name].position
		HX.position = HX.position.move_toward(pos, HX.position.distance_to(pos) * delta * 5 * game.u_i.time_speed)
	if stage in [BattleStages.START, BattleStages.CHOOSING]:
		var ship0_dist:float = ship0.position.distance_to(Vector2(200, 200))
		var ship1_dist:float = ship1.position.distance_to(Vector2(400, 200))
		var ship2_dist:float = ship2.position.distance_to(Vector2(200, 400))
		var ship3_dist:float = ship3.position.distance_to(Vector2(400, 400))
		ship0_engine.emitting = ship0_dist > 10
		ship1_engine.emitting = ship1_dist > 10
		ship2_engine.emitting = ship2_dist > 10
		ship3_engine.emitting = ship3_dist > 10
		ship0.position = ship0.position.move_toward(Vector2(200, 200), ship0_dist * delta * 5 * time_speed)
		ship1.position = ship1.position.move_toward(Vector2(400, 200), ship1_dist * delta * 5 * time_speed)
		ship2.position = ship2.position.move_toward(Vector2(200, 400), ship2_dist * delta * 5 * time_speed)
		ship3.position = ship3.position.move_toward(Vector2(400, 400), ship3_dist * delta * 5 * time_speed)
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
		var curr_ship = self["ship%s" % tgt_sh]
		if move_method == MoveMethod.STANDARD:
			var boost:int = 2.5 if Input.is_action_pressed("shift") or Input.is_action_pressed("X") else 1.1
			if ship_dir == "left":
				curr_ship.position.y = max(0, curr_ship.position.y - 10 * boost * time_mult)
				self["ship%s_engine" % tgt_sh].emitting = true
			elif ship_dir == "right":
				self["ship%s_engine" % tgt_sh].modulate.a = 0.2 * boost
				self["ship%s_engine" % tgt_sh].emitting = true
				curr_ship.position.y = min(720, curr_ship.position.y + 10 * boost * time_mult)
			else:
				self["ship%s_engine" % tgt_sh].emitting = false
		elif move_method == MoveMethod.MOUSE:
			curr_ship.position.y = move_toward(curr_ship.position.y, mouse_pos.y, pow(abs(mouse_pos.y - curr_ship.position.y), 1.2) * time_mult * 0.05)
			self["ship%s_engine" % tgt_sh].emitting = true
		elif move_method == MoveMethod.FRICTION:
			var boost:int = 2.5 if Input.is_action_pressed("shift") or Input.is_action_pressed("X") else 1.0
			if ship_dir == "left":
				self["ship%s_engine" % tgt_sh].emitting = true
				curr_ship.y_acc = -0.8 * boost
			elif ship_dir == "right":
				self["ship%s_engine" % tgt_sh].emitting = true
				curr_ship.y_acc = 0.8 * boost
			else:
				self["ship%s_engine" % tgt_sh].emitting = false
				curr_ship.y_acc = 0
			curr_ship.y_speed = curr_ship.y_speed * time_mult + curr_ship.y_acc * time_mult
			curr_ship.position.y = clamp(curr_ship.position.y + curr_ship.y_speed * time_mult, 0, 720)
		elif move_method == MoveMethod.CLICK:
			self["ship%s_engine" % tgt_sh].emitting = true
			if curr_ship.get_node("Sprite2D").flip_v:
				curr_ship.y_acc = -0.8
			else:
				curr_ship.y_acc = 0.8
			curr_ship.y_speed = curr_ship.y_speed * time_mult + curr_ship.y_acc * time_mult
			curr_ship.position.y = clamp(curr_ship.position.y + curr_ship.y_speed * time_mult, 0, 720)
	for light in get_tree().get_nodes_in_group("lights"):
		light.scale += Vector2(0.1, 0.1) * time_mult
		light.modulate.a -= 0.05 * time_mult
		if light.modulate.a <= 0:
			light.remove_from_group("lights")
			light.free()
	for weapon in get_tree().get_nodes_in_group("weapon"):
		var sh:int = w_c_d[weapon.name].shooter
		var vel:Vector2 = w_c_d[weapon.name].v
		weapon.position += vel * time_mult
		var remove_weapon_b:bool
		var has_hit:bool = w_c_d[weapon.name].has_hit
		if vel.x > 0:
			remove_weapon_b = weapon.position.x > 1350
			if weapon.position.x > w_c_d[weapon.name].lim.x and not has_hit:
				remove_weapon_b = weapon_hit_HX(sh, w_c_d[weapon.name], weapon)
		elif vel.x < 0:
			remove_weapon_b = weapon.position.x < -80
			if weapon.position.x < w_c_d[weapon.name].lim.x and not has_hit:
				remove_weapon_b = weapon_hit_HX(sh, w_c_d[weapon.name], weapon)
		elif vel.y > 0:
			remove_weapon_b = weapon.position.y > 800
			if weapon.position.y > w_c_d[weapon.name].lim.y and not has_hit:
				remove_weapon_b = weapon_hit_HX(sh, w_c_d[weapon.name], weapon)
		elif vel.y < 0:
			remove_weapon_b = weapon.position.y < -80
			if weapon.position.y < w_c_d[weapon.name].lim.y and not has_hit:
				remove_weapon_b = weapon_hit_HX(sh, w_c_d[weapon.name], weapon)
		if remove_weapon_b:
			weapon.remove_from_group("weapon")
			remove_child(weapon)
			weapon.queue_free()
	for weapon in get_tree().get_nodes_in_group("w_%s" % pattern):
		HX_w_c_d[weapon.name].delay -= delta * time_speed
		if HX_w_c_d[weapon.name].delay < 0:
			var curr_p_str:String = "process_%s" % pattern
			#$CurrentPattern.text = curr_p_str
			call(curr_p_str, weapon, time_mult)
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
			weapon.scale.y = 2
			weapon.modulate.a = 1
			weapon.get_node("CollisionShape2D").disabled = false
			HXs[HX_w_c_d[weapon.name].id].get_node("KnockbackAnimation").stop()
			HXs[HX_w_c_d[weapon.name].id].get_node("KnockbackAnimation").play("Knockback", -1, time_speed)
			
	elif HX_w_c_d[weapon.name].stage == 1:
		weapon.modulate.a -= 0.04 * delta * time_speed
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
	if get_tree().get_nodes_in_group(group).is_empty():
		$Timer.start()

func remove_targets():
	for target in get_tree().get_nodes_in_group("targets"):
		target.remove_from_group("targets")
		remove_child(target)
		target.queue_free()
	for i in len(HXs):
		if HX_data[i].HP <= 0:
			continue
		HXs[i].modulate.a = 1

func place_targets(attacking:bool = true):
	remove_targets()
	stage = BattleStages.TARGETING
	var one_enemy:bool = false
	var target_id:int = -1
	if attacking:
		for i in len(HXs):
			if HX_data[i].HP <= 0:
				continue
			if target_id == -1:#A way to not show target buttons if there's only one target alive
				target_id = i
				one_enemy = true
			else:
				target_id = -2
			var HX = HXs[i]
			HX.modulate.a = 0.5
			var target = target_scene.instantiate()
			target.position = HX.position
			add_child(target)
			target.get_node("TextureButton").shortcut = Shortcut.new()
			target.get_node("TextureButton").shortcut.events.append(InputEventKey.new())
			target.get_node("TextureButton").shortcut.events[0].physical_keycode = 49 + (i % 4)
			target.get_node("TextureButton").connect("pressed",Callable(self,"on_target_pressed").bind(i))
			target.get_node("TextureButton").connect("mouse_entered",Callable(self,"on_target_over").bind(i))
			target.get_node("TextureButton").connect("mouse_exited",Callable(self,"on_target_out"))
			target.get_node("Label").text = str((i % 4) + 1)
			target.add_to_group("targets")
		if target_id != -2:
			on_target_pressed(target_id, one_enemy)
	else:
		for i in len(ship_data): #Target your ships instead
			if ship_data[i].HP > 0:
				var target = target_scene.instantiate()
				target.position = get_node("Ship%s" % i).position
				add_child(target)
				target.get_node("TextureButton").shortcut = Shortcut.new()
				target.get_node("TextureButton").shortcut.shortcut = InputEventAction.new()
				target.get_node("TextureButton").shortcut.shortcut.action = str((i % 4) + 1)
				target.get_node("TextureButton").connect("pressed",Callable(self,"on_target_pressed").bind(i))
				target.get_node("TextureButton").connect("mouse_entered",Callable(self,"on_target_over").bind(i))
				target.get_node("TextureButton").connect("mouse_exited",Callable(self,"on_target_out"))
				target.get_node("Label").text = str((i % 4) + 1)
				target.add_to_group("targets")

func on_target_over(target:int):
	if weapon_type in ["bullet", "laser", "bomb", "light"]:
		var acc:float = ship_data[curr_sh].acc
		var acc_mult:float = Data["%s_data" % weapon_type][ship_data[curr_sh][weapon_type].lv - 1].accuracy
		var eva:float = HX_data[target].eva
		var chance:float = hit_formula(acc * acc_mult * ship_data[curr_sh].acc_mult * (1 + ship_buffs[curr_sh].acc), eva)
		game.show_tooltip("%s: %s%%" % [tr("CHANCE_OF_HITTING"), round(chance * 100.0)])
	else:
		game.show_tooltip("attac")

func on_target_out():
	game.hide_tooltip()

func on_target_pressed(target:int, one_enemy:bool = false):
	game.hide_tooltip()
	var weapon_data
	if ship_data[curr_sh].has(weapon_type):
		weapon_data = ship_data[curr_sh][weapon_type]
	if $UI/FightPanel.modulate.a > 0:
		$UI/FightPanel/AnimationPlayer.play_backwards("FightPanelAnim")
	$UI/Current.visible = false
	stage = BattleStages.PLAYER
	var ship_pos = self["ship%s" % [curr_sh]].position
	if weapon_type == "laser":
		var HX_pos = Vector2(1000, 360) if target == -1 else HX_c_d[HXs[target].name].position
		$Laser.visible = true
		$Laser.position = ship_pos
		$Laser.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
		$Laser.scale.x = (HX_pos.x - ship_pos.x) / 650.0
		$Laser/Texture2D.material["shader_parameter/beams"] = weapon_data.lv + 1
		$Laser/Texture2D.material["shader_parameter/outline_thickness"] = (weapon_data.lv + 1) * 0.01
		if weapon_data.lv == 2:
			$Laser/Texture2D.material["shader_parameter/outline_color"] = Color.ORANGE
		elif weapon_data.lv == 3:
			$Laser/Texture2D.material["shader_parameter/outline_color"] = Color.YELLOW
		elif weapon_data.lv == 4:
			$Laser/Texture2D.material["shader_parameter/outline_color"] = Color.GREEN
		elif weapon_data.lv == 5:
			$Laser/Texture2D.material["shader_parameter/outline_color"] = Color.BLUE
		$Laser/AnimationPlayer.play("LaserFade", -1, time_speed)
		weapon_hit_HX(curr_sh, {
			"target":target,
			"shooter":curr_sh,
			"acc_mult":Data.laser_data[weapon_data.lv - 1].accuracy,
			"has_hit":true})
	elif weapon_type in ["buff", "debuff", "repair"]:
		if weapon_type == "buff":
			#Buff attack and accuracy by 20%
			var ship = get_node("Ship%s" % target)
			ship_buffs[target].atk += 0.2
			ship_buffs[target].acc += 0.2
			set_buff_text(ship_buffs[target].atk, "Atk", ship)
			set_buff_text(ship_buffs[target].acc, "Acc", ship)
		elif weapon_type == "debuff":
			#Debuff attack and accuracy by 20%
			var i = target
			var acc_buff = -0.2
			if HX_c_d[HXs[i].name].has("acc"):
				acc_buff += HX_c_d[HXs[i].name].acc
			HX_c_d[HXs[i].name].acc = acc_buff
			set_buff_text(acc_buff, "Acc", HXs[i])
			var atk_buff = -0.2
			if HX_c_d[HXs[i].name].has("atk"):
				atk_buff += HX_c_d[HXs[i].name].atk
			HX_c_d[HXs[i].name].atk = atk_buff
			set_buff_text(atk_buff, "Atk", HXs[i])
		else:
			#Heal for 20%
			ship_data[target].HP = min(ship_data[target].HP + ship_data[target].total_HP * 0.2, ship_data[target].total_HP)
			var ship = get_node("Ship%s" % target)
			ship.get_node("HP").value = ship_data[target].HP
		$Timer.start(min(0.5, 1 / time_speed))
	else:
		var HX_pos = Vector2(1000, 360) if target == -1 else HX_c_d[HXs[target].name].position
		var weapon = Sprite2D.new()
		weapon.add_to_group("weapon")
		weapon.texture = load("res://Graphics/Weapons/%s%s.png" % [weapon_type, weapon_data.lv])
		weapon.position = ship_pos
		weapon.scale *= 0.5
		add_child(weapon)
		weapon.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
		w_c_d[weapon.name] = {"v":(60.0 if weapon_type == "light" else 30.0) * Vector2.from_angle(weapon.rotation)}
		w_c_d[weapon.name].target = target
		w_c_d[weapon.name].shooter = curr_sh
		w_c_d[weapon.name].lim = HX_pos
		w_c_d[weapon.name].acc_mult = Data["%s_data" % [weapon_type]][weapon_data.lv - 1].accuracy
		w_c_d[weapon.name].has_hit = false
		if weapon_type == "bullet":
			w_c_d[weapon.name].bounces_remaining = 0 if one_enemy else weapon_data.lv
	remove_targets()
	curr_sh += 1
	while curr_sh < len(ship_data) and ship_data[curr_sh].HP <= 0:
		curr_sh += 1

func _on_weapon_pressed(_weapon_type:String):
	if game:
		game.hide_tooltip()
	if stage != BattleStages.CHOOSING:
		return
	weapon_type = _weapon_type
	if $UI/FightPanel.modulate.a > 0:
		$UI/FightPanel/AnimationPlayer.play_backwards("FightPanelAnim")
	if weapon_type == "light":
		on_target_pressed(-1)
	else:
		place_targets()

func add_victory_panel():
	victory_panel = victory_panel_scene.instantiate()
	victory_panel.HX_data = HX_data
	victory_panel.ship_data = ship_data
	victory_panel.weapon_XPs = weapon_XPs
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
	$UI.add_child(victory_panel)

func _on_Timer_timeout():
	#var HXs_rekt:int = wave * 4
	while curr_en < min((wave + 1) * 4, len(HX_data)):
		if HX_data[curr_en].HP <= 0:
			curr_en += 1
		elif HX_c_d[HXs[curr_en].name].has("stun"):
			curr_en += 1
		else:
			break
	if HXs_rekt >= len(HX_data):
		add_victory_panel()
		return
	if HXs_rekt >= (wave + 1) * 4:
		wave += 1
		send_HXs()
		curr_sh = 0
		while ship_data[curr_sh].HP <= 0:
			curr_sh += 1
		curr_en = wave * 4
		stage = BattleStages.CHOOSING
		refresh_fight_panel()
		$UI/Current.visible = true
		$UI/Back.visible = true
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
			refresh_fight_panel()
			$UI/Current.visible = true
			$UI/Back.visible = true

func enemy_attack():
	if game.help.has("battle"):
		$UI/Help2/AnimationPlayer.play("Fade")
		$UI/Help2.visible = true
		return
	if game.help.has("battle2") and curr_en == green_enemy:
		$Help.text = tr("GREEN_ENEMY_HELP")
		$Help/AnimationPlayer.play("Fade")
		$Help.visible = true
		return
	elif game.help.has("battle3") and curr_en == purple_enemy:
		$Help.text = tr("PURPLE_ENEMY_HELP")
		$Help/AnimationPlayer.play("Fade")
		$Help.visible = true
		return
	var last_id:int = min((wave + 1) * 4, len(HX_data))
	self["ship%s_engine" % tgt_sh].emitting = false
	if curr_en == last_id:
		curr_sh = 0
		while ship_data[curr_sh].HP <= 0:
			curr_sh += 1
		for i in range(wave * 4, last_id):
			if HX_data[i].HP > 0:
				if HX_c_d[HXs[i].name].has("burn"):
					damage_HX(i, HX_data[i].total_HP * 0.1)
					HXs[i].get_node("KnockbackAnimation").stop()
					HXs[i].get_node("KnockbackAnimation").play("Small knockback", -1, time_speed)
					HXs[i].get_node("HurtAnimation").stop()
					HXs[i].get_node("HurtAnimation").play("Hurt", -1, time_speed)
					HX_c_d[HXs[i].name].burn -= 1
					HXs[i].get_node("Info/Effects/FireLabel").text = str(HX_c_d[HXs[i].name].burn)
					if HX_c_d[HXs[i].name].burn <= 0:
						HX_c_d[HXs[i].name].erase("burn")
						HXs[i].get_node("Sprite2D/Fire").visible = false
						HXs[i].get_node("Info/Effects/Fire").visible = false
						HXs[i].get_node("Info/Effects/FireLabel").visible = false
				if HX_c_d[HXs[i].name].has("stun"):
					HX_c_d[HXs[i].name].stun -= 1
					HXs[i].get_node("Info/Effects/StunLabel").text = str(HX_c_d[HXs[i].name].stun)
					if HX_c_d[HXs[i].name].stun <= 0:
						HX_c_d[HXs[i].name].erase("stun")
						HXs[i].get_node("Sprite2D/Stun").visible = false
						HXs[i].get_node("Info/Effects/Stun").visible = false
						HXs[i].get_node("Info/Effects/StunLabel").visible = false
				if HX_c_d[HXs[i].name].has("acc"):
					if HX_c_d[HXs[i].name].acc > 0:
						HX_c_d[HXs[i].name].acc = max(0.0, HX_c_d[HXs[i].name].acc - 0.05)
					elif HX_c_d[HXs[i].name].acc < 0: 
						HX_c_d[HXs[i].name].acc = min(0.0, HX_c_d[HXs[i].name].acc + 0.05)
					set_buff_text(HX_c_d[HXs[i].name].acc, "Acc", HXs[i])
				if HX_c_d[HXs[i].name].has("atk"):
					if HX_c_d[HXs[i].name].atk > 0:
						HX_c_d[HXs[i].name].atk = max(0.0, HX_c_d[HXs[i].name].atk - 0.05)
					elif HX_c_d[HXs[i].name].atk < 0: 
						HX_c_d[HXs[i].name].atk = min(0.0, HX_c_d[HXs[i].name].atk + 0.05)
					set_buff_text(HX_c_d[HXs[i].name].atk, "Atk", HXs[i])
		for id in len(ship_data):
			var acc_buff = ship_buffs[id].acc
			if acc_buff > 0:
				acc_buff = max(acc_buff - 0.05, 0)
			elif acc_buff < 0:
				acc_buff = min(acc_buff + 0.05, 0)
			ship_buffs[id].acc = acc_buff
			set_buff_text(acc_buff, "Acc", get_node("Ship%s" % id))
			var atk_buff = ship_buffs[id].atk
			if atk_buff > 0:
				atk_buff = max(atk_buff - 0.05, 0)
			elif atk_buff < 0:
				atk_buff = min(atk_buff + 0.05, 0)
			ship_buffs[id].atk = atk_buff
			set_buff_text(atk_buff, "Atk", get_node("Ship%s" % id))
		if $UI/ControlKeyboard.visible:
			$UI/ControlKeyboard/AnimationPlayer.play_backwards("Fade")
		if $UI/ControlMouse.visible:
			$UI/ControlMouse/AnimationPlayer.play_backwards("Fade")
		if HXs_rekt == len(HX_data):
			await get_tree().create_timer(1.0).timeout
			add_victory_panel()
		else:
			_on_Timer_timeout()
	else:
		pattern = "%s_%s" % [HX_data[curr_en].type, Helper.rand_int(1, 3)]
		move_method = HX_data[curr_en]["class"] - 1
		if move_method in [MoveMethod.STANDARD, MoveMethod.FRICTION]:
			if not $UI/ControlKeyboard.visible:
				$UI/ControlKeyboard.visible = true
				$UI/ControlKeyboard/AnimationPlayer.play("Fade")
			if $UI/ControlMouse.visible:
				$UI/ControlMouse/AnimationPlayer.play_backwards("Fade")
		elif move_method in [MoveMethod.MOUSE, MoveMethod.CLICK]:
			if not $UI/ControlMouse.visible:
				$UI/ControlMouse.visible = true
				$UI/ControlMouse/AnimationPlayer.play("Fade")
			if $UI/ControlKeyboard.visible:
				$UI/ControlKeyboard/AnimationPlayer.play_backwards("Fade")
		call("atk_%s" % pattern, curr_en)
		curr_en += 1

func put_magic(id:int):
	star = Sprite2D.new()
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
		var fireball = w_1_1.instantiate()
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
			var beam = w_1_2.instantiate()
			var target:Vector2 = Vector2(0, randf_range(0, 720))
			if j == 0:
				y_pos = target.y
			else:
				while abs(target.y - y_pos) < 200:
					target.y = randf_range(0, 720)
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
			var bullet = w_1_3.instantiate()
			var target:Vector2 = Vector2(1100, randf_range(0, 720))
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
		var pillar = w_2_1.instantiate()
		if i % 2 == 0:
			pillar.scale.y *= -1
			pillar.position.y = randf_range(upper_bound, upper_bound2)
		else:
			pillar.position.y = randf_range(lower_bound, lower_bound2)
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
		var ball = w_2_2.instantiate()
		if i % 2 == 0:
			ball.position.y = -200
		else:
			ball.position.y = 920
		ball.scale *= scale_mult
		var y_target = randf_range(280, 440)
		var y_target2 = randf_range(-50, 770)
		while abs(y_target2 - y_target) < 100:
			y_target2 = randf_range(-50, 770)
		ball.position.x = randf_range(900, 1250)
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
		var mine = w_2_3.instantiate()
		var v:Vector2 = Vector2(-8, randf_range(0, 6))
		mine.position = Vector2(1350, randf_range(0, 720))
		mine.scale *= randf_range(0.6, 0.9)
		if mine.position.y > 360:
			v.y *= -1
		v *= (1.7 - mine.scale.x) * v_mult
		mine.rotation = randf_range(0, 2 * PI)
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
		var y_pos = randf_range(100, 620)
		y_poses.append(y_pos)
		var proj_num:int = (7 if id % 2 == 0 else 11) * proj_num_mult
		var spread:float = (0.2 if id % 2 == 0 else 0.13) / proj_num_mult
		for j in proj_num:
			var spike = w_3_1.instantiate()
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
	var path:int = randi() % 13
	var dir = randf_range(0.1, 0.9)
	while abs(dir - 0.5) < 0.2:
		dir = randf_range(0.1, 0.9)
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
			var diamond = w_3_2.instantiate()
			diamond.position = Vector2(1350 + i * 48, j * 48)
			diamond.get_node("CollisionPolygon2D").disabled = true
			add_child(diamond)
			diamond.add_to_group("w_3_2")
			diamond.modulate = Color(randf_range(0.5, 1), randf_range(0.5, 1), randf_range(0.5, 1), 1)
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
		var platform = w_3_3_1.instantiate()
		platform.position = Vector2(1400, randf_range(200, 520))
		add_child(platform)
		platform.add_to_group("w_3_3")
		var platform_delay:float = i * 1.5 + 0.5
		HX_w_c_d[platform.name] = {"group":"w_3_3", "id":id, "damage":6, "delay":platform_delay}
		var interval:float = randf_range(0.65, 0.7) * int_mult
		for j in 14:
			var bullet = w_3_3_2.instantiate()
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
		var light = w_4_1.instantiate()
		light.position = HXs[id].position
		light.scale *= 0.6
		var min_angle = atan2(light.position.y, light.position.x) + 0.2
		var max_angle = atan2(light.position.y - 720, light.position.x) - 0.2
		light.rotation = randf_range(min_angle, max_angle)
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
		var y_pos = randf_range(50, 670)
		y_poses.append(y_pos)
		var boomerang = w_4_2.instantiate()
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
		var y_poses = [snapped(randf_range(0, 600), 120) + 64, snapped(randf_range(0, 600), 120) + 64, snapped(randf_range(0, 600), 120) + 64]
		while y_poses[1] == y_poses[0]:
			y_poses[1] = snapped(randf_range(0, 600), 120) + 64
		while y_poses[2] == y_poses[0] or y_poses[2] == y_poses[1]:
			y_poses[2] = snapped(randf_range(0, 600), 120) + 64
		for j in 3:
			var slab = w_4_3.instantiate()
			slab.position = Vector2(1350, y_poses[j])
			add_child(slab)
			slab.add_to_group("w_4_3")
			HX_w_c_d[slab.name] = {"group":"w_4_3", "id":id, "damage":4, "delay":delay_mult * i + 0.5, "v_mult":v_mult}

func _on_Ship_area_entered(area, ship_id:int):
	if immune or self["ship%s" % ship_id].modulate.a != 1.0:
		return
	var shooter:int = HX_w_c_d[area.name].id
	var HX = HX_data[shooter]
	if randf() < hit_formula(HX.acc * (1.0 + HX_c_d[HXs[shooter].name].acc if HX_c_d[HXs[shooter].name].has("acc") else 1.0), ship_data[ship_id].eva * ship_data[ship_id].eva_mult):
		var dmg:int = HX_w_c_d[area.name].damage * HX.atk * (1.0 + HX_c_d[HXs[shooter].name].atk if HX_c_d[HXs[shooter].name].has("atk") else 1.0) / (ship_data[ship_id].def * ship_data[ship_id].def_mult)
		Helper.show_dmg(dmg, self["ship%s" % ship_id].position, self, 30)
		ship_data[ship_id].HP -= dmg
		ship_data[ship_id].rage = min(ship_data[ship_id].rage + float(dmg) / float(ship_data[ship_id].total_HP) * 300, 100) #Add rage based on the percentage of health lost
	else:
		Helper.show_dmg(0, self["ship%s" % ship_id].position, self, 30, true)
	$ImmuneTimer.start()
	hit_amount += 1
	immune = true
	if not HX_w_c_d[area.name].group in ["w_1_2", "w_2_1", "w_3_3"]:
		remove_weapon(area, HX_w_c_d[area.name].group)
	get_node("Ship%s/HP" % [ship_id]).value = ship_data[ship_id].HP
	get_node("Ship%s/Rage" % [ship_id]).value = ship_data[ship_id].rage

func _on_ImmuneTimer_timeout():
	immune = false

func _on_Battle_tree_exited():
	queue_free()

func _on_weapon_mouse_entered(weapon:String):
	if game and $UI/FightPanel.modulate.a == 1.0 and curr_sh < len(ship_data):
		var w_lv:int = ship_data[curr_sh][weapon].lv
		if weapon == "light":
			game.show_tooltip("%s %s %s\n%s: %s (%s: %s)\n%s: %s" % [
				tr(weapon.to_upper()),# Bullet
				tr("LV"),# Lv
				w_lv,# 1
				tr("BASE_DAMAGE"),# Base damage
				Helper.clever_round(Data["%s_data" % [weapon]][w_lv - 1].damage * light_mult * log(game.u_i.speed_of_light - 1.0 + exp(1.0))),# 5
				tr("BATTLEFIELD_DARKNESS_MULT"),
				Helper.clever_round(light_mult),# 1.3
				tr("BASE_ACCURACY"),# Base accuracy
				Data["%s_data" % [weapon]][w_lv - 1].accuracy])# 2
		else:
			var dmg_mult:float = 1.0
			if weapon in ["bullet", "bomb"]:
				dmg_mult = log(game.u_i.planck - 1.0 + exp(1.0))
			elif weapon == "laser":
				dmg_mult = log(game.u_i.charge - 1.0 + exp(1.0))
			game.show_tooltip("%s %s %s\n%s: %s\n%s: %s" % [
				tr(weapon.to_upper()),# Bullet
				tr("LV"),# Lv
				w_lv,# 1
				tr("BASE_DAMAGE"),# Base damage
				Helper.clever_round(Data["%s_data" % [weapon]][w_lv - 1].damage * dmg_mult),# 5
				tr("BASE_ACCURACY"),# Base accuracy
				Data["%s_data" % [weapon]][w_lv - 1].accuracy])# 2

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
	$UI/Help2/AnimationPlayer.play_backwards("Fade")
	$Help/AnimationPlayer.play("Fade")
	$Help.visible = true

func _on_AnimationPlayer_animation_finished(anim_name):
	$Laser.visible = false

func _on_ControlKeyboard_animation_finished(anim_name):
	if $UI/ControlKeyboard.modulate.a <= 0:
		$UI/ControlKeyboard.visible = false

func _on_ControlMouse_animation_finished(anim_name):
	if $UI/ControlMouse.modulate.a <= 0:
		$UI/ControlMouse.visible = false

func _on_Ability_pressed():
	if game:
		game.hide_tooltip()
	if stage != BattleStages.CHOOSING:
		return
	if $UI/FightPanel.modulate.a > 0:
		$UI/FightPanel/AnimationPlayer.play_backwards("FightPanelAnim")
	var ability = ship_data[curr_sh].ability
	weapon_type = ability
	var attacking = true
	if ability in ["buff", "repair"]:
		attacking = false
	place_targets(attacking)

func _on_Superweapon_pressed():
	if game:
		game.hide_tooltip()
	if stage != BattleStages.CHOOSING:
		return
	var _super = ship_data[curr_sh].superweapon
	
	if curr_sh in pending_supers.keys(): #If this ship is charging a superweapon
		if $UI/FightPanel.modulate.a > 0:
			$UI/FightPanel/AnimationPlayer.play_backwards("FightPanelAnim")
		if pending_supers[curr_sh] > 0: #If the amount of turns to charge is greater than zero
			pending_supers[curr_sh] -= 1
		else:
			pending_supers.erase(curr_sh)
			get_node("Ship%s/Charge" % [curr_sh]).emitting = false
			weapon_type = _super
			var dmg = 50 * ship_data[curr_sh].atk * ship_data[curr_sh].atk_mult * ship_buffs[curr_sh].atk #op damage calculation
			for id in len(HXs):
				if HX_data[id].HP > 0:
					HX_data[id].HP -= dmg / HX_data[id].def
					HXs[id].get_node("Info/HP").value = HX_data[id].HP
					Helper.show_dmg(dmg, HXs[id].position, self, 30, false)
					HXs[id].get_node("HurtAnimation").stop()
					HXs[id].get_node("HurtAnimation").play("Hurt", -1, time_speed)
					HXs[id].get_node("KnockbackAnimation").stop()
					HXs[id].get_node("KnockbackAnimation").play("Small knockback" if HX_data[id].HP > 0 else "Dead", -1, time_speed)
					if HX_data[id].HP <= 0 and not HX_data[id].has("rekt"):
						HXs_rekt += 1
						HX_data[id].rekt = true
						$UI/FightPanel/Panel/BattleProgress.text = "%s / %s" % [HXs_rekt, len(HX_data)]
			if _super == "charge":
				ship_data[curr_sh].HP -= dmg / (ship_data[curr_sh].def * ship_data[curr_sh].def_mult)
				get_node("Ship%s/HP" % [curr_sh]).value = ship_data[curr_sh].HP
			curr_sh += 1
			while ship_data[curr_sh].HP <= 0: #Find the next ship that can take a turn
				curr_sh += 1
				if curr_sh == 4:
					curr_sh = 0
			$Timer.start(min(1, 1 / time_speed))
	elif ship_data[curr_sh].rage == 100:
		if $UI/FightPanel.modulate.a > 0:
			$UI/FightPanel/AnimationPlayer.play_backwards("FightPanelAnim")
		ship_data[curr_sh].rage = 0
		get_node("Ship%s/Rage" % [curr_sh]).value = 0
		get_node("Ship%s/Charge" % [curr_sh]).emitting = true
		pending_supers[curr_sh] = 0
		curr_sh += 1
		while ship_data[curr_sh].HP <= 0: #Find the next ship that can take a turn
			curr_sh += 1
			if curr_sh == 4:
				curr_sh = 0
		$Timer.start(min(0.5, 0.5 / time_speed))


func _on_animation_player_animation_finished(anim_name):
	if $Help.modulate.a == 0.0:
		$Help.visible = false


func _on_help2_animation_player_animation_finished(anim_name):
	if $UI/Help2.modulate.a == 0.0:
		$UI/Help2.visible = false
