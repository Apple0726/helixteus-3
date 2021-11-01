extends "Panel.gd"

var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var select_comp_scene = preload("res://Scenes/Panels/SelectCompPanel.tscn")
var select_comp
var HP:float = 20.0
var atk:float = 5.0
var def:float = 2.0
var weight_cap:float = 3000.0
var inventory = [{"type":"rover_weapons", "name":"red_laser"}, {"type":"rover_mining", "name":"red_mining_laser"}, {"type":""}, {"type":""}, {"type":""}, {"type":""}]
var tile
var rover_costs:Dictionary
var slot_over:int = -1
var cmp_over:String = ""
var mult:float
var engi_mult:float

onready var armor_slot = $Stats/HBoxContainer/Armor
onready var wheels_slot = $Stats/HBoxContainer/Wheels
onready var CC_slot = $Stats/HBoxContainer/CC#CC: Cargo Container
var armor:String = "stone_armor"
var HP_bonus:int
var def_bonus:int
var wheels:String = "stone_wheels"
var spd_bonus:float
var CC:String = "stone_CC"
var cargo_bonus:int

func _ready():
	set_polygon(rect_size)
	select_comp = select_comp_scene.instance()
	select_comp.visible = false
	add_child(select_comp)
	
	armor_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_armor"])
	armor_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	armor_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_armor"])
	wheels_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_wheels"])
	wheels_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	wheels_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_wheels"])
	CC_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_CC"])
	CC_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	CC_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_CC"])
	if game.science_unlocked.has("RMK2"):
		inventory.append({"type":""})
	if game.science_unlocked.has("RMK3"):
		inventory.append({"type":""})

func _on_Slot_mouse_entered(type:String):
	var txt:String = ""
	var metal:String = tr(self[type.split("_")[1]].split("_")[0].to_upper())
	var comp:String = tr(type.split("_")[1].to_upper())
	var metal_comp:String = tr("METAL_COMP").format({"metal":metal, "comp":comp})
	cmp_over = type
	if type == "rover_armor" and armor != "":
		txt = "%s\n+%s %s\n+%s %s" % [metal_comp, Data.rover_armor[armor].HP, tr("HEALTH_POINTS"), Data.rover_armor[armor].defense, tr("DEFENSE")]
	elif type == "rover_wheels":
		txt = "%s\n+%s %s" % [metal_comp, Data.rover_wheels[wheels].speed, tr("MOVEMENT_SPEED")]
	elif type == "rover_CC" and CC != "":
		txt = "%s\n+%s kg %s" % [metal_comp, round(Data.rover_CC[CC].capacity * game.u_i.planck), tr("CARGO_CAPACITY")]
	if txt != "":
		if game.help.rover_inventory_shortcuts:
			game.help_str = "rover_inventory_shortcuts"
			txt += "\n%s\n%s\n%s" % [tr("CLICK_TO_CHANGE"), tr("X_TO_REMOVE"), tr("HIDE_SHORTCUTS")]
		game.show_tooltip(txt)

func _on_InvSlot_mouse_entered(txt:String, index:int):
	slot_over = index
	if game.help.rover_inventory_shortcuts:
		game.help_str = "rover_inventory_shortcuts"
		if txt != "":
			game.show_tooltip(txt + "\n%s\n%s\n%s" % [tr("CLICK_TO_CHANGE"), tr("X_TO_REMOVE"), tr("HIDE_SHORTCUTS")])
		else:
			game.show_tooltip(txt + "%s\n%s" % [tr("CLICK_TO_CHANGE"), tr("HIDE_SHORTCUTS")])
	else:
		if txt != "":
			game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	slot_over = -1
	cmp_over = ""
	game.hide_tooltip()

func _on_InvSlot_pressed(index:int):
	select_comp.visible = true
	game.sub_panel = select_comp
	select_comp.refresh(inventory[index].type, inventory[index].name if inventory[index].has("name") else "", true, index)

func _on_Slot_pressed(type:String):
	select_comp.visible = true
	game.sub_panel = select_comp
	if type == "rover_armor":
		select_comp.refresh(type, armor)
	elif type == "rover_wheels":
		select_comp.refresh(type, wheels)
	elif type == "rover_CC":
		select_comp.refresh(type, CC)

func _on_Button_pressed():
	if game.check_enough(rover_costs):
		game.deduct_resources(rover_costs)
		game.popup("ROVER_UNDER_CONSTR", 1.5)
		tile.bldg.is_constructing = true
		tile.bldg.rover_id = len(game.rover_data)
		tile.bldg.construction_date = OS.get_system_time_msecs()
		tile.bldg.construction_length = rover_costs.time * 1000
		tile.bldg.XP = round(rover_costs.money / 100.0)
		var append:bool = true
		for i in len(game.rover_data):
			if game.rover_data[i] == null:
				game.rover_data[i] = {"c_p":game.c_p, "ready":false, "HP":round((HP + HP_bonus) * mult * engi_mult), "atk":round(atk * mult * engi_mult), "def":round(def + def_bonus), "weight_cap":round((weight_cap + cargo_bonus) * mult * engi_mult), "spd":spd_bonus, "inventory":inventory.duplicate(true), "i_w_w":{}}
				tile.bldg.rover_id = i
				append = false
				break
		if append:
			game.rover_data.append({"c_p":game.c_p, "ready":false, "HP":round((HP + HP_bonus) * mult * engi_mult), "atk":round(atk * mult * engi_mult), "def":round(def + def_bonus), "weight_cap":round((weight_cap + cargo_bonus) * mult * engi_mult), "spd":spd_bonus, "inventory":inventory.duplicate(true), "i_w_w":{}})
		game.view.obj.add_time_bar(game.c_t, "bldg")
		game.toggle_panel(self)
		if not game.show.vehicles_button:
			game.show.vehicles_button = true
			if game.planet_HUD:
				game.planet_HUD.get_node("VBoxContainer/Vehicles").visible = true
		game.HUD.refresh()
	else:
		game.popup("NOT_ENOUGH_RESOURCES", 1.5)

func refresh():
	HP = 20.0
	atk = 5.0
	def = 2.0
	weight_cap = round(3000.0 * game.u_i.planck)
	if game.science_unlocked.has("RMK2"):
		HP = 50
		atk = 15
		def = 8.0
		weight_cap = round(16000.0 * game.u_i.planck)
	if game.science_unlocked.has("RMK3"):
		HP = 450
		atk = 70
		def = 20.0
		weight_cap = round(200000.0 * game.u_i.planck)
	engi_mult = game.engineering_bonus.RSM
	tile = game.tile_data[game.c_t]
	mult = tile.bldg.path_1_value
	rover_costs = Data.costs.rover.duplicate(true)
	if armor != "":
		for cost_key in Data.rover_armor[armor].costs.keys():
			var cost = Data.rover_armor[armor].costs[cost_key]
			if rover_costs.has(cost_key):
				rover_costs[cost_key] += cost
			else:
				rover_costs[cost_key] = cost
		HP_bonus = Data.rover_armor[armor].HP
		def_bonus = Data.rover_armor[armor].defense
	else:
		HP_bonus = 0
		def_bonus = 0
	for cost_key in Data.rover_wheels[wheels].costs.keys():
		var cost = Data.rover_wheels[wheels].costs[cost_key]
		if rover_costs.has(cost_key):
			rover_costs[cost_key] += cost
		else:
			rover_costs[cost_key] = cost
	if CC != "":
		for cost_key in Data.rover_CC[CC].costs.keys():
			var cost = Data.rover_CC[CC].costs[cost_key]
			if rover_costs.has(cost_key):
				rover_costs[cost_key] += cost
			else:
				rover_costs[cost_key] = cost
		cargo_bonus = round(Data.rover_CC[CC].capacity * game.u_i.planck)
	else:
		cargo_bonus = 0
	var hbox = $Inventory/HBoxContainer
	for node in hbox.get_children():
		hbox.remove_child(node)
	var i:int = 0
	for inv in inventory:
		var slot = slot_scene.instance()
		if inv.type == "rover_weapons":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Weapons/%s.png" % [inv.name])
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s" % [Helper.get_rover_weapon_text(inv.name)], i])
			for cost_key in Data.rover_weapons[inv.name].costs.keys():
				var cost = Data.rover_weapons[inv.name].costs[cost_key]
				if rover_costs.has(cost_key):
					rover_costs[cost_key] += cost
				else:
					rover_costs[cost_key] = cost
		elif inv.type == "rover_mining":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Mining/%s.png" % [inv.name])
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s" % [Helper.get_rover_mining_text(inv.name)], i])
			for cost_key in Data.rover_mining[inv.name].costs.keys():
				var cost = Data.rover_mining[inv.name].costs[cost_key]
				if rover_costs.has(cost_key):
					rover_costs[cost_key] += cost
				else:
					rover_costs[cost_key] = cost
		else:
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["", -1])
		slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
		slot.get_node("Button").connect("pressed", self, "_on_InvSlot_pressed", [i])
		hbox.add_child(slot)
		i += 1
	rover_costs.time /= game.u_i.time_speed
	Helper.put_rsrc($ScrollContainer/VBoxContainer, 36, rover_costs, true, true)
	spd_bonus = Data.rover_wheels[wheels].speed
	$Stats/HPText.bbcode_text = Helper.format_num(round((HP + HP_bonus) * mult * engi_mult)) + "  [img]Graphics/Icons/help.png[/img]"
	$Stats/AtkText.bbcode_text = Helper.format_num(round(atk * mult * engi_mult)) + "  [img]Graphics/Icons/help.png[/img]"
	$Stats/DefText.bbcode_text = Helper.format_num(round(def + def_bonus)) + "  [img]Graphics/Icons/help.png[/img]"
	$Stats/CargoText.bbcode_text = "%s kg" % [Helper.format_num((weight_cap + cargo_bonus) * mult * engi_mult)] + "  [img]Graphics/Icons/help.png[/img]"
	if engi_mult == 1.0:
		$Stats/HPText.help_text = "(%s + %s) * %s = %s" % [HP, HP_bonus, mult, round((HP + HP_bonus) * mult * engi_mult)]
		$Stats/AtkText.help_text = "(%s + %s) * %s = %s" % [atk, 0, mult, round(atk * mult * engi_mult)]
		$Stats/CargoText.help_text = "(%s + %s) * %s = %s kg" % [weight_cap, cargo_bonus, mult, Helper.format_num((weight_cap + cargo_bonus) * mult * engi_mult)]
	else:
		$Stats/HPText.help_text = "(%s + %s) * %s * %s = %s" % [HP, HP_bonus, mult, engi_mult, round((HP + HP_bonus) * mult * engi_mult)]
		$Stats/AtkText.help_text = "(%s + %s) * %s * %s = %s" % [atk, 0, mult, engi_mult, round(atk * mult * engi_mult)]
		$Stats/CargoText.help_text = "(%s + %s) * %s * %s = %s kg" % [weight_cap, cargo_bonus, mult, engi_mult, Helper.format_num((weight_cap + cargo_bonus) * mult * engi_mult)]
	$Stats/DefText.help_text = "%s + %s = %s" % [def, def_bonus, round(def + def_bonus)]
	$Stats/SpeedText.bbcode_text = String(Helper.clever_round(spd_bonus)) + "  [img]Graphics/Icons/help.png[/img]"
	$Stats/SpeedText.help_text = "%s + %s = %s" % [0, spd_bonus, Helper.clever_round((spd_bonus))]
	armor_slot.get_node("TextureRect").texture = null if armor == "" else load("res://Graphics/Cave/Armor/%s.png" % [armor])
	wheels_slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Wheels/%s.png" % [wheels])
	CC_slot.get_node("TextureRect").texture = null if CC == "" else load("res://Graphics/Cave/CargoContainer/%s.png" % [CC])

func _on_icon_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))

func _on_icon_mouse_exited():
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("X"):
		if slot_over != -1:
			inventory[slot_over].erase("name")
			inventory[slot_over].type = ""
			refresh()
			game.hide_tooltip()
		if cmp_over != "":
			if cmp_over in ["rover_armor", "rover_CC"]:
				self[cmp_over.split("_")[1]] = ""
				refresh()
				game.hide_tooltip()
			else:
				game.popup(tr("REMOVE_WHEELS_ATTEMPT"), 2.5)

func _on_close_button_pressed():
	game.toggle_panel(self)

func _on_Text_mouse_exited():
	game.hide_tooltip()
