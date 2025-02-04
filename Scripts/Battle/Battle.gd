extends Node

@onready var game = get_node("/root/Game")

var battle_GUI:BattleGUI
var HX_scene = preload("res://Scenes/Battle/HX.tscn")

var HX_data:Array
var ship_data:Array
var hard_battle:bool = false
var time_speed:float = 1.0
var initiative_order = []
var whose_turn_is_it_index:int = 0
var HX_nodes = []
var ship_nodes = []

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
			get_node("Ship%s" % (i + 1)).show()
			get_node("Ship%s" % (i + 1)).agility = ship_data[i].agility
			get_node("Ship%s" % (i + 1)).roll_initiative()
			get_node("Ship%s" % (i + 1)).position = ship_data[i].initial_position
			get_node("Ship%s/Sprite2D" % (i + 1)).material.set_shader_parameter("frequency", 6 * time_speed)
			get_node("Ship%s/HP" % (i + 1)).max_value = ship_data[i].HP
			get_node("Ship%s/HP" % (i + 1)).value = ship_data[i].HP
			get_node("Ship%s/Label" % (i + 1)).text = "%s %s" % [tr("LV"), ship_data[i].lv]
			get_node("Ship%s/ThrusterFire" % (i + 1)).emitting = false
			ship_nodes.append(get_node("Ship%s" % (i + 1)))
	for i in len(HX_data):
		var HX = HX_scene.instantiate()
		HX.agility = HX_data[i].agility
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
		add_child(HX)
		HX_nodes.append(HX)


func initialize_battle():
	for i in len(HX_nodes):
		initiative_order.append({"type":ENEMY, "idx":i, "initiative":HX_nodes[i].initiative})
	for i in len(ship_nodes):
		initiative_order.append({"type":SHIP, "idx":i, "initiative":ship_nodes[i].initiative})
	initiative_order.sort_custom(sort_initiative)
	if initiative_order[0].type == SHIP:
		battle_GUI.main_panel.get_node("AnimationPlayer").play("Fade")
	for i in len(initiative_order):
		var entity = initiative_order[i]
		var turn_order_button = preload("res://Scenes/Battle/TurnOrderButton.tscn").instantiate()
		if entity.type == ENEMY:
			turn_order_button.set_texture(load("res://Graphics/HX/%s_%s.png" % [HX_data[entity.idx]["class"], HX_data[entity.idx].type]))
			turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color.RED
		elif entity.type == SHIP:
			turn_order_button.set_texture(load("res://Graphics/Ships/Ship%s.png" % entity.idx))
			turn_order_button.get_node("Panel")["theme_override_styles/panel"].border_color = Color("#00c1ffc9")
		battle_GUI.turn_order_hbox.add_child(turn_order_button)
		turn_order_button.modulate.a = 0.0
		turn_order_button.custom_minimum_size.x = 0.0
		var delay = create_tween()
		delay.tween_callback(turn_order_button.get_node("AnimationPlayer").play.bind("InitialAnim")).set_delay(0.15 * i)
		


func sort_initiative(a, b):
	return a.initiative > b.initiative


func _process(delta: float) -> void:
	pass
