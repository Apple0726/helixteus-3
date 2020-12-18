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

var ship_data = [{"HP":20, "total_HP":20, "atk":10, "def":10, "acc":10, "eva":10, "XP":0, "bullet":0, "laser":0, "bomb":0, "light":0}]
var HX_data = []
var HXs = []
var HX_c_d:Dictionary = {}#HX_custom_data
var w_c_d:Dictionary = {}#weapon_custom_data
var HX_w_c_d:Dictionary = {}#HX_weapon_custom_data
var curr_sh:int = 1#current_ship
var curr_en:int = 0#current_enemy
var weapon_type:String = ""

enum BattleStages {CHOOSING, PLAYER, ENEMY}

var stage

func _ready():
	stage = BattleStages.CHOOSING
	$Current/Current.float_height = 5
	$Current/Current.float_speed = 0.25
	$Ship1/HP.max_value = ship_data[0].total_HP
	$Ship1/HP.value = ship_data[0].HP
	for k in 5:
		var lv = Helper.rand_int(1, 4)
		var HP = round(rand_range(1, 1.5) * 20 * pow(1.3, lv))
		var atk = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var def = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var acc = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var eva = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		HX_data.append({"type":Helper.rand_int(1, 3), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva})
	for k in 4:
		var btn = TextureButton.new()
		btn.rect_position = -Vector2(90, 50)
		btn.rect_size = Vector2(180, 100)
		var HX = HX1_scene.instance()
		HX.get_node("HX/Sprite").texture = load("res://Graphics/HX/%s.png" % [HX_data[k].type])
		HX.scale *= 0.4
		HX.get_node("HX/HP").max_value = HX_data[k].total_HP
		HX.get_node("HX/HP").value = HX_data[k].HP
		HX.get_node("HX").set_script(load("res://Scripts/FloatAnim.gd"))
		HX.position = Vector2(2000, 360)
		HX.add_child(btn)
		btn.connect("mouse_entered", self, "on_HX_over", [k])
		btn.connect("mouse_exited", self, "on_HX_out")
		add_child(HX)
		HXs.append(HX)
		HX_c_d[HX.name] = {"position":Vector2((k % 2) * 300 + 850, (k / 2) * 150 + 250)}

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
		for HX in HXs:
			HX.get_node("Info").visible = false
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
		HX.get_node("Info").visible = true
		HX.get_node("Info/Sprite").texture = self["%s_icon" % [type]]
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [HX_data[i].HP, HX_data[i].total_HP]
		else:
			HX.get_node("Info/Label").text = String(HX_data[i][type])
		i += 1

func _on_Back_pressed():
	game.switch_view("system")

var ship_dir:String = ""

func _process(delta):
	for HX in HXs:
		var pos = HX_c_d[HX.name].position
		HX.position = HX.position.move_toward(pos, HX.position.distance_to(pos) * delta * 5)
	if stage == BattleStages.CHOOSING:
		ship1.position = ship1.position.move_toward(Vector2(200, 200), ship1.position.distance_to(Vector2(200, 200)) * delta * 5)
		current.position = self["ship%s" % [curr_sh]].position + Vector2(0, -45)
	for weapon in get_tree().get_nodes_in_group("weapon"):
		weapon.position += w_c_d[weapon.name].v * delta * 60
		if weapon.position.x > w_c_d[weapon.name].lim:
			weapon.remove_from_group("weapon")
			remove_child(weapon)
			var w_data = "%s_data" % [weapon_type]
			var t = w_c_d[weapon.name].target
			var dmg = ship_data[0].atk * Data[w_data][ship_data[0][weapon_type]].damage / HX_data[w_c_d[weapon.name].target].def
			HX_data[t].HP -= dmg
			HXs[t].get_node("HX/HP").value = HX_data[t].HP
			Helper.show_dmg(dmg, weapon.position, self, 0.6)
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
				weapon.remove_from_group("w_1_1")
				remove_child(weapon)
	if stage == BattleStages.ENEMY:
		var boost:int = 2.5 if Input.is_action_pressed("X") else 1.1
		if ship_dir == "left":
			ship1.position.y = max(0, ship1.position.y - 10 * boost * delta * 60)
		elif ship_dir == "right":
			ship1.position.y = min(720, ship1.position.y + 10 * boost * delta * 60)

func remove_targets():
	for target in get_tree().get_nodes_in_group("targets"):
		target.remove_from_group("targets")
		remove_child(target)
	for HX in HXs:
		HX.get_node("HX").modulate.a = 1

func place_targets():
	remove_targets()
	var i:int = 1
	for HX in HXs:
		HX.get_node("HX").modulate.a = 0.5
		var target = target_scene.instance()
		target.position = HX.position
		add_child(target)
		target.get_node("TextureButton").shortcut = ShortCut.new()
		target.get_node("TextureButton").shortcut.shortcut = InputEventAction.new()
		target.get_node("TextureButton").shortcut.shortcut.action = String(i)
		target.get_node("TextureButton").connect("pressed", self, "on_target_pressed", [i - 1])
		target.get_node("Label").text = String(i)
		target.add_to_group("targets")
		i += 1

func on_target_pressed(target:int):
	$FightPanel.visible = false
	$Current.visible = false
	var weapon = Sprite.new()
	weapon.add_to_group("weapon")
	weapon.texture = load("res://Graphics/Weapons/%s.png" % [weapon_type])
	var ship_pos = self["ship%s" % [curr_sh]].position
	var HX_pos = HXs[target].position
	weapon.position = ship_pos
	weapon.scale *= 0.5
	weapon.rotation = atan2(HX_pos.y - ship_pos.y, HX_pos.x - ship_pos.x)
	add_child(weapon)
	$Back.visible = false
	stage = BattleStages.PLAYER
	w_c_d[weapon.name] = {"v":(HX_pos - ship_pos) / 30.0}
	w_c_d[weapon.name].target = target
	w_c_d[weapon.name].lim = HX_pos.x
	remove_targets()

func _on_weapon_pressed(_weapon_type:String):
	weapon_type = _weapon_type
	$FightPanel.visible = false
	place_targets()

func _on_Timer_timeout():
	stage = BattleStages.ENEMY
	enemy_attack()

func enemy_attack():
	call("atk_%s_%s" % [1, Helper.rand_int(1, 1)], curr_en)
	curr_en += 1

func atk_1_1(id:int):
	for i in 10:
		var fireball = w_1_1.instance()
		fireball.position = HXs[id].position
		fireball.visible = false
		fireball.add_to_group("w_1_1")
		add_child(fireball)
		HX_w_c_d[fireball.name] = {"group":"w_1_1", "damage":2, "id":id, "delay":i * 0.4}

func _on_Ship1_area_entered(area):
	var HX = HX_data[HX_w_c_d[area.name].id]
	var dmg = HX_w_c_d[area.name].damage * HX.atk / ship_data[0].def
	Helper.show_dmg(dmg, ship1.position, self, 0.6)
	ship_data[0].HP -= dmg
	area.remove_from_group(HX_w_c_d[area.name].group)
	$Ship1/HP.value = ship_data[0].HP
	remove_child(area)
