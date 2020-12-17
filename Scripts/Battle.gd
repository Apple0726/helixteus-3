extends Control

onready var game = get_node("/root/Game")
onready var current = $Current
onready var ship1 = $Ship1
onready var HX1_scene = preload("res://Scenes/HX/HX1.tscn")

var HX_data = []
var HX_custom_data:Dictionary = {}
var curr_sh:int = 1#current_ship

func _ready():
	$Current/Current.float_height = 5
	$Current/Current.float_speed = 0.25
	for k in 5:
		var lv = Helper.rand_int(1, 4)
		var HP = round(rand_range(1, 1.5) * 20 * pow(1.3, lv))
		var atk = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var def = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var acc = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		var eva = round(rand_range(1, 1.5) * 10 * pow(1.3, lv))
		HX_data.append({"type":Helper.rand_int(1, 3), "lv":lv, "HP":HP, "total_HP":HP, "atk":atk, "def":def, "acc":acc, "eva":eva})
	for k in len(HX_data):
		var HX = HX1_scene.instance()
		HX.get_node("HX/Sprite").texture = load("res://Graphics/HX/%s.png" % [HX_data[k].type])
		HX.scale *= 0.4
		HX.get_node("HX/HP").max_value = HX_data[k].total_HP
		HX.get_node("HX/HP").value = HX_data[k].HP
		HX.get_node("HX").set_script(load("res://Scripts/FloatAnim.gd"))
		HX.position = Vector2(2000, 360)
		add_child(HX)
		HX.add_to_group("active_HX")
		HX_custom_data[HX.name] = {"position":Vector2(rand_range(680, 1160), rand_range(60, 660))}

func _input(event):
	Helper.set_back_btn($Back)

func _on_Back_pressed():
	game.switch_view("system")

func _process(delta):
	for HX in get_tree().get_nodes_in_group("active_HX"):
		var pos = HX_custom_data[HX.name].position
		HX.position = HX.position.move_toward(pos, HX.position.distance_to(pos) * delta * 5)
	ship1.position = ship1.position.move_toward(Vector2(200, 200), ship1.position.distance_to(Vector2(200, 200)) * delta * 5)
	current.position = self["ship%s" % [curr_sh]].position + Vector2(0, -45)
