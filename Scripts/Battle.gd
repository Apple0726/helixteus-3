extends Node

@onready var game = get_node("/root/Game")
var HX_data
var ship_data

var HX1_scene = preload("res://Scenes/Battle/HX.tscn")

var hard_battle:bool = false
var time_speed:float = 1.0
var HX_nodes = []

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
			get_node("Ship%s" % (i + 1)).position = ship_data[i].initial_position
			get_node("Ship%s/Sprite2D" % (i + 1)).material.set_shader_parameter("frequency", 6 * time_speed)
			get_node("Ship%s/HP" % (i + 1)).max_value = ship_data[i].HP
			get_node("Ship%s/HP" % (i + 1)).value = ship_data[i].HP
			get_node("Ship%s/Label" % (i + 1)).text = "%s %s" % [tr("LV"), ship_data[i].lv]
			get_node("Ship%s/ThrusterFire" % (i + 1)).emitting = false
	for i in len(HX_data):
		var HX = HX1_scene.instantiate()
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
		HX.get_node("Info/Effects/Fire").mouse_entered.connect(game.show_tooltip.bind(tr("BURN_DESC")))
		HX.get_node("Info/Effects/Fire").mouse_exited.connect(game.hide_tooltip)
		HX.get_node("Info/Effects/Stun").mouse_entered.connect(game.show_tooltip.bind(tr("STUN_DESC")))
		HX.get_node("Info/Effects/Stun").mouse_exited.connect(game.hide_tooltip)
		add_child(HX)
		HX_nodes.append(HX)

func _process(delta: float) -> void:
	pass
