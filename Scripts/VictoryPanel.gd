extends Control

onready var game = get_node("/root/Game")
var HX_data# = [{"money":100, "XP":14}]
var ship_data# = [{"lv":1, "HP":20, "total_HP":20, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
var weapon_XPs:Array# = [{"bullet":0, "laser":2, "bomb":0, "light":0}]
var XP:float = 0
var money:float = 0
var p_id:int
var mult:float

func _ready():
	for HX in HX_data:
		money += round(HX.money * mult)
		XP += round(HX.XP * mult)
	Helper.put_rsrc($HBoxContainer, 42, {"money":money})
	for i in 2:
		if i >= len(ship_data):
			$Grid.get_node("Panel%s" % (i + 1)).visible = false
			break
		else:
			$Grid.get_node("Panel%s/XP/Label" % (i + 1)).text = "+ %s" % [XP]
			for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
				get_node("Grid/Panel%s/%s/Label" % [i + 1, weapon]).text = "+ %s" % [round(weapon_XPs[i][weapon.to_lower()] * mult)]
			$Grid.get_node("Panel%s" % (i + 1)).show_weapon_XPs = true
			$Grid.get_node("Panel%s" % (i + 1)).refresh()
	$Bonus.text = "%s: %sx" % [tr("LOOT_XP_BONUS"), mult]

func _process(delta):
	for i in len(ship_data):
		for weapon in ["Bullet", "Laser", "Bomb", "Light"]:
			var node = get_node("Grid/Panel%s/%s/TextureProgress2" % [i + 1, weapon])
			var text_node = get_node("Grid/Panel%s/%s/Label2" % [i + 1, weapon])
			var XP_get = round(weapon_XPs[i][weapon.to_lower()] * mult)
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
			Helper.add_weapon_XP(i, weapon, round(weapon_XPs[i][weapon] * mult))
	game.planet_data[p_id].conquered = true
	var all_conquered = true
	for planet in game.planet_data:
		if not planet.conquered:
			all_conquered = false
	game.stats.planets_conquered += 1
	if not game.objective.empty() and game.objective.type == game.ObjectiveType.CONQUER and game.objective.data == "planet":
		game.objective.current += 1
	game.system_data[game.c_s].conquered = all_conquered
	Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	game.switch_view("system")

func _on_Bonus_mouse_entered():
	game.show_tooltip(tr("LOOT_XP_BONUS_DESC"))

func _on_mouse_exited():
	game.hide_tooltip()
