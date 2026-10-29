extends Control

@onready var game = get_node("/root/Game")
var l_id:int
var id:int
var energy_cost:float = 0.0

func _ready() -> void:
	var total_enemy_stats = 0.0
	var total_ship_stats = 0.0
	var money_earned = 0.0
	var XP_earned = 0.0
	var HX_data:Array
	var negotiated_text = tr("NEGOTIATED_NORMAL")
	if id == -1:
		$Label.text = tr("CONQUER_THIS_SYSTEM")
		var conquer_all_data:Dictionary = Helper.get_conquer_all_data()
		HX_data = conquer_all_data.HX_data
		$EnemyNumber.show()
		$EnemyNumber/Label.text = "x %d" % len(HX_data)
		Helper.add_text_to_RTL($EnergyCost, "[center][font_size=13]" + tr("BOTH_ACTIONS_ALSO_COST_ENERGY").format({"energy": Helper.format_num(conquer_all_data.energy_cost, true)}), [Data.energy_icon])
	else:
		HX_data = game.planet_data[l_id].HX_data
	for i in len(HX_data):
		var total_stats = HX_data[i].HP * 0.25 + HX_data[i].attack + HX_data[i].defense + HX_data[i].accuracy + HX_data[i].agility
		total_enemy_stats += total_stats
		money_earned += HX_data[i].money
		XP_earned += HX_data[i].XP
	for i in len(game.ship_data):
		var total_stats = game.ship_data[i].HP * 0.25 + game.ship_data[i].attack + game.ship_data[i].defense + game.ship_data[i].accuracy + game.ship_data[i].agility
		total_ship_stats += total_stats
	total_ship_stats *= log(max(game.u_i.speed_of_light, game.u_i.planck) - 1.0 + exp(1.0))
	if id == -1:
		if total_enemy_stats / total_ship_stats < 0.5:
			negotiated_text = tr("NEGOTIATED_ALL_EASY")
		elif total_enemy_stats / total_ship_stats > 5.0:
			negotiated_text = tr("NEGOTIATED_ALL_HARD")
		else:
			negotiated_text = tr("NEGOTIATED_ALL_NORMAL")
	else:
		if total_enemy_stats / total_ship_stats < 0.5:
			negotiated_text = tr("NEGOTIATED_EASY")
		elif total_enemy_stats / total_ship_stats > 5.0:
			negotiated_text = tr("NEGOTIATED_HARD")
	var money_to_negotiate = money_earned * game.system_data[game.c_s].diff * pow(max(0.2, total_enemy_stats * 1.2 / total_ship_stats), 5)
	Helper.add_text_to_RTL($FightDesc, "[center][font_size=13]" + tr("FIGHT_DESC").format({"money": Helper.format_num(money_earned, true), "XP": Helper.format_num(XP_earned, true)}), [Data.money_icon])
	Helper.add_text_to_RTL($NegotiateDesc, "[center][font_size=13]" + tr("NEGOTIATE_DESC").format({"money": Helper.format_num(money_to_negotiate, true)}), [Data.money_icon])
	$Fight.pressed.connect(initiate_battle)
	$Negotiate.pressed.connect(negotiate.bind(money_to_negotiate, negotiated_text))
	$CloseButton.pressed.connect(queue_free)

func initiate_battle():
	if l_id == -1:
		game.c_p = game.ships_travel_data.c_coords.p
		game.is_conquering_all = true
	else:
		game.c_p = l_id
		game.c_p_g = id
		game.is_conquering_all = false
	game.switch_view("battle")
	queue_free()

func negotiate(money_to_negotiate:float, negotiated_text:String):
	if game.money >= money_to_negotiate:
		if id == -1:
			if game.energy >= energy_cost:
				game.energy -= energy_cost
				game.conquer_all_planets()
			else:
				game.popup(tr("NOT_ENOUGH_ENERGY"), 1.5)
				return
		else:
			Helper.conquer_planet(l_id)
		game.popup_window(negotiated_text)
		game.view.obj.refresh_planets()
		game.money -= money_to_negotiate
		queue_free()
	else:
		game.popup(tr("NOT_ENOUGH_MONEY"), 1.5)
