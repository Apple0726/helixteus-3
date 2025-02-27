extends Node2D

@onready var game = get_node("/root/Game")

const METERS_PER_AGILITY = 10.0
const PIXELS_PER_METER = 5.0

var battle_GUI:BattleGUI
var HX_scene = preload("res://Scenes/Battle/HX.tscn")

var HX_data:Array
var ship_data:Array
var hard_battle:bool = false
var time_speed:float = 1.0
var initiative_order = []
var whose_turn_is_it_index:int = -1
var HX_nodes = []
var ship_nodes = []
var mouse_position_global:Vector2
var mouse_position_local:Vector2

enum {
	ENEMY,
	SHIP,
}

func _ready() -> void:
	time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, game.u_i.time_speed)
	var p_i:Dictionary = game.planet_data[game.c_p]
	if game.is_conquering_all:
		HX_data = Helper.get_conquer_all_data().HX_data
	else:
		HX_data = p_i.HX_data
	ship_data = game.ship_data
	for i in range(0, 4):
		if len(ship_data) > i:
			var ship_node = preload("res://Scenes/Battle/Ship.tscn").instantiate()
			ship_node.METERS_PER_AGILITY = METERS_PER_AGILITY
			ship_node.PIXELS_PER_METER = PIXELS_PER_METER
			ship_node.initialize_stats(ship_data[i])
			ship_node.roll_initiative()
			ship_node.position = ship_data[i].initial_position
			ship_node.battle_scene = self
			ship_node.battle_GUI = battle_GUI
			ship_node.next_turn.connect(next_turn)
			ship_node.get_node("Sprite2D").texture = load("res://Graphics/Ships/Ship%s.png" % i)
			ship_node.get_node("Sprite2D").material.set_shader_parameter("frequency", 6 * time_speed)
			ship_node.get_node("Info/HP").max_value = ship_data[i].HP
			ship_node.get_node("Info/HP").value = ship_data[i].HP
			ship_node.get_node("Info/Label").text = "%s %s" % [tr("LV"), ship_data[i].lv]
			ship_node.get_node("ThrusterFire").emitting = false
			add_child(ship_node)
			ship_nodes.append(ship_node)
	for i in len(HX_data):
		var HX = HX_scene.instantiate()
		HX.METERS_PER_AGILITY = METERS_PER_AGILITY
		HX.PIXELS_PER_METER = PIXELS_PER_METER
		HX.initialize_stats(HX_data[i])
		HX.battle_scene = self
		HX.battle_GUI = battle_GUI
		HX.HX_nodes = HX_nodes
		HX.ship_nodes = ship_nodes
		HX.roll_initiative()
		HX.get_node("Sprite2D").texture = load("res://Graphics/HX/%s_%s.png" % [HX_data[i]["class"], HX_data[i].type])
		HX.get_node("Sprite2D").material.set_shader_parameter("frequency", 6 * time_speed)
		HX.get_node("Info/HP").max_value = HX_data[i].HP
		HX.get_node("Info/HP").value = HX_data[i].HP
		HX.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_data[i].lv]
		if hard_battle:
			HX.get_node("LabelAnimation").play("LabelAnim")
		HX.position = Vector2(1340, randf_range(150, 570))
		var tween = get_tree().create_tween()
		tween.tween_property(HX, "position", HX_data[i].initial_position, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(i * 0.2)
		if i == len(HX_data) - 1:
			tween.finished.connect(initialize_battle)
		HX.get_node("Info/Effects/Fire").mouse_entered.connect(game.show_tooltip.bind(tr("BURN_DESC")))
		HX.get_node("Info/Effects/Fire").mouse_exited.connect(game.hide_tooltip)
		HX.get_node("Info/Effects/Stun").mouse_entered.connect(game.show_tooltip.bind(tr("STUN_DESC")))
		HX.get_node("Info/Effects/Stun").mouse_exited.connect(game.hide_tooltip)
		HX.next_turn.connect(next_turn)
		add_child(HX)
		HX_nodes.append(HX)


func initialize_battle():
	for i in len(HX_nodes):
		initiative_order.append({"type":ENEMY, "idx":i, "initiative":HX_nodes[i].initiative})
	for i in len(ship_nodes):
		initiative_order.append({"type":SHIP, "idx":i, "initiative":ship_nodes[i].initiative})
	initiative_order.sort_custom(sort_initiative)
	for i in len(initiative_order) + 1:
		var turn_order_button = preload("res://Scenes/Battle/TurnOrderButton.tscn").instantiate()
		if i > 0:
			var delay = create_tween()
			delay.tween_callback(turn_order_button.get_node("AnimationPlayer").play.bind("InitialAnim")).set_delay(0.15 * i)
			turn_order_button.modulate.a = 0.0
		battle_GUI.turn_order_hbox.add_child(turn_order_button)
		turn_order_button.custom_minimum_size.x = 0.0
		turn_order_button.get_node("TextureRect").modulate.a = 0.5
		if i == len(initiative_order): # Environment always goes last
			turn_order_button.show_initiative(0, 0.15 * len(initiative_order) + 3.0)
			turn_order_button.set_texture(load("res://Graphics/Achievements/BStar.png"))
			turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(1.0, 1.0, 0.0, 0.7)
		else:
			var entity = initiative_order[i]
			turn_order_button.show_initiative(entity.initiative, 0.15 * i + 3.0)
			if entity.type == ENEMY:
				turn_order_button.set_texture(load("res://Graphics/HX/%s_%s.png" % [HX_data[entity.idx]["class"], HX_data[entity.idx].type]))
				turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(1.0, 0.0, 0.0, 0.7)
				HX_nodes[entity.idx].show_initiative(entity.initiative)
				HX_nodes[entity.idx].turn_index = i
			elif entity.type == SHIP:
				turn_order_button.set_texture(load("res://Graphics/Ships/Ship%s.png" % entity.idx))
				turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color(0.0, 0.8, 1.0, 0.7)
				ship_nodes[entity.idx].show_initiative(entity.initiative)
				ship_nodes[entity.idx].turn_index = i
	next_turn()

func next_turn():
	whose_turn_is_it_index += 1
	var move_view_tween = create_tween().set_parallel()
	battle_GUI.ship_node = null
	if whose_turn_is_it_index == len(initiative_order):
		var view_scale:float = 0.4
		move_view_tween.tween_property(game.view, "scale", Vector2.ONE * view_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
		move_view_tween.tween_property(game.view, "position", Vector2(640, 360) - Vector2(640, 360) * view_scale, 1.0).set_trans(Tween.TRANS_CUBIC)
		battle_GUI.turn_order_hbox.get_child(whose_turn_is_it_index).get_node("AnimationPlayer").play("ChangeSize")
	elif initiative_order[whose_turn_is_it_index].type == SHIP:
		var ship_node = ship_nodes[initiative_order[whose_turn_is_it_index].idx]
		battle_GUI.main_panel.get_node("AnimationPlayer").play("Fade")
		battle_GUI.ship_node = ship_node
		move_view_tween.tween_property(game.view, "position", Vector2(640, 360) - ship_node.position * game.view.scale.x, 1.0).set_trans(Tween.TRANS_CUBIC)
		ship_node.take_turn()
	elif initiative_order[whose_turn_is_it_index].type == ENEMY:
		var HX_node = HX_nodes[initiative_order[whose_turn_is_it_index].idx]
		move_view_tween.tween_property(game.view, "position", Vector2(640, 360) - HX_node.position * game.view.scale.x, 1.0).set_trans(Tween.TRANS_CUBIC)
		HX_node.take_turn()

func sort_initiative(a, b):
	return a.initiative > b.initiative


func _process(delta: float) -> void:
	pass


func add_damage_text(missed: bool, label_position:Vector2, damage: float = 0.0, critical: bool = false, label_initial_velocity:Vector2 = Vector2.ZERO):
	var damage_text = preload("res://Scenes/Battle/DamageText.tscn").instantiate()
	damage_text.missed = missed
	damage_text.damage = damage
	damage_text.critical = critical
	damage_text.velocity = label_initial_velocity
	damage_text.position = label_position
	add_child(damage_text)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position_global = event.position
		mouse_position_local = to_local(event.position)
	if Input.is_action_just_pressed("A"):
		display_stats("attack")
	if Input.is_action_just_pressed("D"):
		display_stats("defense")
	if Input.is_action_just_pressed("C"):
		display_stats("accuracy")
	if Input.is_action_just_pressed("G"):
		display_stats("agility")
	if Input.is_action_just_pressed("H"):
		display_stats("HP")
	if Input.is_action_just_released("A") or Input.is_action_just_released("D") or Input.is_action_just_released("C") or Input.is_action_just_released("G") or Input.is_action_just_released("H"):
		for HX_node in HX_nodes:
			HX_node.get_node("Info/Icon").hide()
			HX_node.get_node("Info/Label").text = "%s %s" % [tr("LV"), HX_node.lv]
		for ship_node in ship_nodes:
			ship_node.get_node("Info/Icon").hide()
			ship_node.get_node("Info/Label").text = "%s %s" % [tr("LV"), ship_node.lv]


func display_stats(type:String):
	for i in len(HX_nodes):
		var HX = HX_nodes[i]
		HX.get_node("Info/Icon").show()
		HX.get_node("Info/Icon").texture = load("res://Graphics/Icons/%s.png" % type)
		if type == "HP":
			HX.get_node("Info/Label").text = "%s / %s" % [str(HX.HP), str(HX.total_HP)]
		else:
			HX.get_node("Info/Label").text = str(HX[type] + HX[type + "_buff"])
	for ship_node in ship_nodes:
		ship_node.get_node("Info/Icon").show()
		ship_node.get_node("Info/Icon").texture = load("res://Graphics/Icons/%s.png" % type)
		if type == "HP":
			ship_node.get_node("Info/Label").text = "%s / %s" % [str(ship_node.HP), str(ship_node.total_HP)]
		else:
			ship_node.get_node("Info/Label").text = str(ship_node[type] + ship_node[type + "_buff"])
