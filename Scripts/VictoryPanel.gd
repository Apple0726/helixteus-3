extends Control

@onready var game = get_node("/root/Game")
var HX_data# = [{"money":100, "XP":14}]
var ship_data# = [{"lv":1, "HP":20, "total_HP":20, "atk":15, "def":15, "acc":15, "eva":15, "XP":0, "XP_to_lv":20, "bullet":{"lv":1, "XP":0, "XP_to_lv":10}, "laser":{"lv":1, "XP":0, "XP_to_lv":10}, "bomb":{"lv":1, "XP":0, "XP_to_lv":10}, "light":{"lv":1, "XP":0, "XP_to_lv":20}}]
var weapon_XPs:Array# = [{"bullet":0, "laser":2, "bomb":0, "light":0}]
var XP:float = 0
var money:float = 0
var p_id:int
var mult:float
var diff_mult:float

func _ready():
	for HX in HX_data:
		money += round(HX.money * mult * diff_mult)
		XP += round(HX.XP * mult * diff_mult)
	Helper.put_rsrc($HBoxContainer, 42, {"money":money})
	for i in 4:
		if i >= len(ship_data):
			$Grid.get_node("Panel%s" % (i + 1)).visible = false
		else:
			$Grid.get_node("Panel%s" % (i + 1)).visible = true
			$Grid.get_node("Panel%s/XP/Label" % (i + 1)).text = "+ %s" % [XP]
			for weapon in ["Bullet", "Laser", "Bomb", "Light3D"]:
				get_node("Grid/Panel%s/%s/Label" % [i + 1, weapon]).text = "+ %s" % [round(weapon_XPs[i][weapon.to_lower()] * mult * diff_mult)]
			$Grid.get_node("Panel%s" % (i + 1)).show_weapon_XPs = true
			$Grid.get_node("Panel%s" % (i + 1)).refresh()
	$Bonus.text = "%s: %sx %s" % [tr("LOOT_XP_BONUS"), mult * diff_mult, "[img]Graphics/Icons/help.png[/img]"]
	$Bonus.help_text = "%s: x %s\n%s: x %s\n%s:\n%s" % [tr("PERFORMANCE_MULTIPLIER"), mult, tr("DIFFICULTY"), diff_mult, tr("PERFORMANCE_MULTIPLIER_VALUES"), tr("LOOT_XP_BONUS_DESC")]

func _process(delta):
	for i in len(ship_data):
		for weapon in ["Bullet", "Laser", "Bomb", "Light3D"]:
			var node = get_node("Grid/Panel%s/%s/TextureProgress2" % [i + 1, weapon])
			var text_node = get_node("Grid/Panel%s/%s/Label2" % [i + 1, weapon])
			var XP_get = round(weapon_XPs[i][weapon.to_lower()] * mult * diff_mult)
			node.value = move_toward(node.value, node.value + XP_get, (XP_get + ship_data[i][weapon.to_lower()].XP - node.value) * delta * 2)
			text_node.text = "%s / %s" % [round(node.value), ship_data[i][weapon.to_lower()].XP_to_lv]
		var XP_node = $Grid.get_node("Panel%s/XP/TextureProgress2" % (i + 1))
		var XP_text_node = $Grid.get_node("Panel%s/XP/Label2" % (i + 1))
		XP_node.value = move_toward(XP_node.value, XP_node.value + XP, (XP + ship_data[i].XP - XP_node.value) * delta * 2)
		XP_text_node.text = "%s / %s" % [round(XP_node.value), ship_data[i].XP_to_lv]

func _input(event):
	if Input.is_action_just_released("right_click"):
		_on_close_button_pressed()

func _on_close_button_pressed():
	game.add_resources({"money":money})
	for i in len(ship_data):
		Helper.add_ship_XP(i, XP)
		for weapon in ["bullet", "laser", "bomb", "light"]:
			Helper.add_weapon_XP(i, weapon, round(weapon_XPs[i][weapon] * mult * diff_mult))
	var all_conquered = true
	if not game.is_conquering_all:
		game.stats_univ.enemies_rekt_in_battle += len(game.planet_data[p_id].HX_data)
		game.stats_dim.enemies_rekt_in_battle += len(game.planet_data[p_id].HX_data)
		game.stats_global.enemies_rekt_in_battle += len(game.planet_data[p_id].HX_data)
		game.planet_data[p_id].conquered = true
		game.planet_data[p_id].erase("HX_data")
		for planet in game.planet_data:
			if not planet.has("conquered"):
				all_conquered = false
		game.stats_univ.planets_conquered += 1
		game.stats_dim.planets_conquered += 1
		game.stats_global.planets_conquered += 1
		if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.CONQUER and game.objective.data == "planet":
			game.objective.current += 1
	else:
		for planet in game.planet_data:
			if not planet.has("conquered") and planet.has("HX_data"):
				planet.conquered = true
				game.stats_univ.enemies_rekt_in_battle += len(planet.HX_data)
				game.stats_dim.enemies_rekt_in_battle += len(planet.HX_data)
				game.stats_global.enemies_rekt_in_battle += len(planet.HX_data)
				planet.erase("HX_data")
				game.stats_univ.planets_conquered += 1
				game.stats_dim.planets_conquered += 1
				game.stats_global.planets_conquered += 1
	if all_conquered:
		game.system_data[game.c_s].conquered = true
		game.stats_univ.systems_conquered += 1
		game.stats_dim.systems_conquered += 1
		game.stats_global.systems_conquered += 1
	if not game.new_bldgs.has("SP") and game.stats_univ.planets_conquered > 1:
		game.new_bldgs.SP = true
	Helper.save_obj("Systems", game.c_s_g, game.planet_data)
	if all_conquered:
		Helper.save_obj("Galaxies", game.c_g_g, game.system_data)
	if game.battle.hard_battle:
		game.switch_music(load("res://Audio/ambient" + str(Helper.rand_int(1, 3)) + ".ogg"))
	queue_free()
	if not game.help.has("SP"):
		game.long_popup(tr("NEW_BLDGS_UNLOCKED_DESC"), tr("NEW_BLDGS_UNLOCKED"))
		game.help.SP = true
	game.switch_view("system", {"dont_fade_anim":true})

func _on_mouse_exited():
	game.hide_tooltip()
