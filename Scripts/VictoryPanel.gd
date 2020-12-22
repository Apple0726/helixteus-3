extends Control

onready var game = get_node("/root/Game")
var HX_data# = [{"money":100, "XP":14}]
var ship_data# = [{"lv":1, "HP":20, "total_HP":20, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
var weapon_XPs:Array# = [{"bullet":0, "laser":2, "bomb":0, "light":0}]
var XP:float = 0
var money:float = 0
var p_id:int

func _ready():
	for HX in HX_data:
		money += HX.money
		XP += HX.XP
	Helper.put_rsrc($HBoxContainer, 42, {"money":money})
	$Grid/Panel1/XP/Label.text = "+ %s" % [XP]
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		get_node("%s/Label" % [weapon]).text = "+ %s" % [weapon_XPs[0][weapon.to_lower()]]
	$Grid/Panel1.show_weapon_stats = false
	$Grid/Panel1.refresh()

func _process(delta):
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		var node = get_node("Grid/Panel1/%s/TextureProgress2" % [weapon])
		var text_node = get_node("Grid/Panel1/%s/Label2" % [weapon])
		var XP_get = weapon_XPs[0][weapon.to_lower()]
		node.value = move_toward(node.value, node.value + XP_get, (XP_get + ship_data[0][weapon.to_lower()].XP - node.value) * delta * 2)
		text_node.text = "%s / %s" % [round(node.value), ship_data[0][weapon.to_lower()].XP_to_lv]
	var XP_node = $Grid/Panel1/XP/TextureProgress2
	var XP_text_node = $Grid/Panel1/XP/Label2
	XP_node.value = move_toward(XP_node.value, XP_node.value + XP, (XP + ship_data[0].XP - XP_node.value) * delta * 2)
	XP_text_node.text = "%s / %s" % [round(XP_node.value), ship_data[0].XP_to_lv]

func _on_close_button_pressed():
	ship_data[0].XP += XP
	if ship_data[0].XP >= ship_data[0].XP_to_lv:
		ship_data[0].XP -= ship_data[0].XP_to_lv
		ship_data[0].XP_to_lv = round(ship_data[0].XP_to_lv * 1.3)
		ship_data[0].lv += 1
		ship_data[0].HP = round(ship_data[0].XP_to_lv * 1.2)
		ship_data[0].atk = round(ship_data[0].atk * 1.2)
		ship_data[0].def = round(ship_data[0].def * 1.2)
		ship_data[0].acc = round(ship_data[0].acc * 1.2)
		ship_data[0].eva = round(ship_data[0].eva * 1.2)
	game.money += money
	for weapon in ["bullet", "laser", "bomb", "light"]:
		ship_data[0][weapon].XP += weapon_XPs[0][weapon]
		if ship_data[0][weapon].XP >= ship_data[0][weapon].XP_to_lv and ship_data[0][weapon].lv < 7:
			ship_data[0][weapon].XP -= ship_data[0][weapon].XP_to_lv
			ship_data[0][weapon].XP_to_lv = [100, 800, 4000, 20000, 75000, 0][ship_data[0][weapon].lv - 1]
			ship_data[0][weapon].lv += 1
	game.planet_data[p_id].conquered = true
	game.switch_view("system")
