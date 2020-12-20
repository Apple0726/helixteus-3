extends Control

onready var game = get_node("/root/Game")
var HX_data# = [{"money":100, "XP":14}]
var ship_data# = [{"lv":1, "HP":20, "total_HP":20, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
var weapon_XPs:Array# = [{"bullet":0, "laser":2, "bomb":0, "light":0}]
var XP:float = 0
var money:float = 0

func _ready():
	for HX in HX_data:
		money += HX.money
		XP += HX.XP
	Helper.put_rsrc($HBoxContainer, 42, {"money":money})
	$Grid/Panel1/XP/Label.text = "+ %s" % [XP]
	$Grid/Panel1/XP/TextureProgress.value = ship_data[0].XP
	$Grid/Panel1/XP/TextureProgress2.value = ship_data[0].XP
	$Grid/Panel1/XP/TextureProgress.max_value = ship_data[0].XP_to_lv
	$Grid/Panel1/XP/TextureProgress2.max_value = ship_data[0].XP_to_lv
	$Grid/Panel1/Lv.text = "%s %s" % [tr("LV"), ship_data[0].lv]
	for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
		get_node("Grid/Panel1/%s/TextureProgress" % [weapon]).value = ship_data[0][weapon.to_lower()].XP
		get_node("Grid/Panel1/%s/TextureProgress" % [weapon]).max_value = ship_data[0][weapon.to_lower()].XP_to_lv
		get_node("Grid/Panel1/%s/TextureProgress2" % [weapon]).value = ship_data[0][weapon.to_lower()].XP
		get_node("Grid/Panel1/%s/TextureProgress2" % [weapon]).max_value = ship_data[0][weapon.to_lower()].XP_to_lv
		get_node("Grid/Panel1/%s/Label" % [weapon]).text = "+ %s" % [weapon_XPs[0][weapon.to_lower()]]
	

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
	game.money += money
	for weapon in ["bullet", "laser", "bomb", "light"]:
		ship_data[0][weapon].XP += weapon_XPs[0][weapon]
	game.switch_view("system")
