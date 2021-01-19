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
	for i in 2:
		if i >= len(ship_data):
			$Grid.get_node("Panel%s" % (i + 1)).modulate.a = 0
			break
		else:
			$Grid.get_node("Panel%s/XP/Label" % (i + 1)).text = "+ %s" % [XP]
			for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
				get_node("Grid/Panel%s/%s/Label" % [i + 1, weapon]).text = "+ %s" % [weapon_XPs[i][weapon.to_lower()]]
			$Grid.get_node("Panel%s" % (i + 1)).show_weapon_XPs = true
			$Grid.get_node("Panel%s" % (i + 1)).refresh()

func _process(delta):
	for i in len(ship_data):
		for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
			var node = get_node("Grid/Panel%s/%s/TextureProgress2" % [i + 1, weapon])
			var text_node = get_node("Grid/Panel%s/%s/Label2" % [i + 1, weapon])
			var XP_get = weapon_XPs[i][weapon.to_lower()]
			node.value = move_toward(node.value, node.value + XP_get, (XP_get + ship_data[i][weapon.to_lower()].XP - node.value) * delta * 2)
			text_node.text = "%s / %s" % [round(node.value), ship_data[i][weapon.to_lower()].XP_to_lv]
		var XP_node = $Grid.get_node("Panel%s/XP/TextureProgress2" % (i + 1))
		var XP_text_node = $Grid.get_node("Panel%s/XP/Label2" % (i + 1))
		XP_node.value = move_toward(XP_node.value, XP_node.value + XP, (XP + ship_data[i].XP - XP_node.value) * delta * 2)
		XP_text_node.text = "%s / %s" % [round(XP_node.value), ship_data[i].XP_to_lv]

func _on_close_button_pressed():
	game.money += money
	for i in len(ship_data):
		Helper.add_ship_XP(i, XP)
		for weapon in ["bullet", "laser", "bomb", "light"]:
			Helper.add_weapon_XP(i, weapon, weapon_XPs[i][weapon])
	game.planet_data[p_id].conquered = true
	var all_conquered = true
	for planet in game.planet_data:
		if not planet.conquered:
			all_conquered = false
	game.system_data[game.c_s].conquered = all_conquered
	Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	game.switch_view("system")
