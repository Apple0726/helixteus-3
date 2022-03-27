extends "Panel.gd"

var slot_scene = preload("res://Scenes/RoverSlot.tscn")
var select_comp_scene = preload("res://Scenes/Panels/SelectCompPanel.tscn")
var RE_scene = preload("res://Scenes/Panels/RoverEnhancements.tscn")
var select_comp
var RE_panel
var HP:float = 20.0
var atk:float = 5.0
var def:float = 2.0
var weight_cap:float = 3000.0
var inventory = [{"type":"rover_weapons", "name":"red_laser"}, {}, {}, {}, {}]
var right_inventory = [{"type":"rover_mining", "name":"red_mining_laser"}]
var right_inv:bool = false
var tile
var rover_costs:Dictionary
var slot_over:int = -1
var cmp_over:String = ""
var mult:float
var engi_mult:float
var REPs:int = 0
var REPs_used:int = 0
var enhancements:Dictionary = {}
var ability:String = ""
var rover_weapons:bool = true
var rover_mining:bool = true

onready var armor_slot = $Stats/Armor
onready var wheels_slot = $Stats/Wheels
onready var CC_slot = $Stats/CC#CC: Cargo Container
onready var right_slot = $Inventory/RightSlot
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
	RE_panel = RE_scene.instance()
	RE_panel.visible = false
	add_child(RE_panel)
	armor_slot.get_node("REP").connect("mouse_entered", self, "_on_REP_mouse_entered")
	armor_slot.get_node("REP").connect("mouse_exited", self, "_on_mouse_exited")
	armor_slot.get_node("REP").connect("pressed", self, "_on_REP_pressed", ["Armor"])
	armor_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_armor"])
	armor_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	armor_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_armor"])
	wheels_slot.get_node("REP").connect("mouse_entered", self, "_on_REP_mouse_entered")
	wheels_slot.get_node("REP").connect("mouse_exited", self, "_on_mouse_exited")
	wheels_slot.get_node("REP").connect("pressed", self, "_on_REP_pressed", ["Wheels"])
	wheels_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_wheels"])
	wheels_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	wheels_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_wheels"])
	CC_slot.get_node("REP").connect("mouse_entered", self, "_on_REP_mouse_entered")
	CC_slot.get_node("REP").connect("mouse_exited", self, "_on_mouse_exited")
	CC_slot.get_node("REP").connect("pressed", self, "_on_REP_pressed", ["CC"])
	CC_slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["rover_CC"])
	CC_slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
	CC_slot.get_node("Button").connect("pressed", self, "_on_Slot_pressed", ["rover_CC"])
	if game.science_unlocked.has("RMK2"):
		inventory.append({})
	if game.science_unlocked.has("RMK3"):
		inventory.append({})

func _on_REP_mouse_entered():
	game.show_tooltip(tr("ENHANCE"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_REP_pressed(type:String):
	for panel in ["Armor", "Wheels", "CC", "Laser"]:
		RE_panel.get_node(panel).visible = false
	RE_panel.get_node(type).visible = true
	RE_panel.get_node("Label").text = tr(type.to_upper())
	RE_panel.visible = true

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
		game.help_str = "rover_inventory_shortcuts"
		if game.help.has("rover_inventory_shortcuts"):
			txt += "\n%s\n%s\n%s" % [tr("CLICK_TO_CHANGE"), tr("X_TO_REMOVE"), tr("HIDE_SHORTCUTS")]
		game.show_tooltip(txt)

func _on_InvSlot_mouse_entered(txt:String, index:int, _right_inv:bool = false):
	slot_over = index
	right_inv = _right_inv
	game.help_str = "rover_inventory_shortcuts"
	if game.help.has("rover_inventory_shortcuts"):
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
	var inv:Dictionary = inventory[index]
	if right_inv:
		inv = right_inventory[index]
	select_comp.get_node("OptionButton").clear()
	var default_type:String = inv.type if inv.has("type") else ""
	if not rover_weapons or inv.has("type") and inv.type == "rover_weapons":
		select_comp.get_node("OptionButton").add_item(tr("WEAPONS"))
		if default_type == "":
			default_type = "rover_weapons"
	if not rover_mining or inv.has("type") and inv.type == "rover_mining":
		select_comp.get_node("OptionButton").add_item(tr("MINING_TOOLS"), 1)
		if default_type == "":
			default_type = "rover_mining"
	if select_comp.get_node("OptionButton").get_item_count() == 0:
		return
	select_comp.visible = true
	select_comp.refresh(default_type, inv.name if inv.has("name") else "", true, index)

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
		var rover_data:Dictionary = {
			"c_p":game.c_p,
			"ready":false,
			"HP":round((HP + HP_bonus) * mult * engi_mult),
			"atk":round(atk * mult * engi_mult),
			"def":round(def + def_bonus),
			"weight_cap":round((weight_cap + cargo_bonus) * mult * engi_mult),
			"spd":spd_bonus,
			"inventory":inventory.duplicate(true),
			"right_inventory":right_inventory.duplicate(true),
			"i_w_w":{},
			"enhancements":enhancements,
			"ability":ability
		}
		var append:bool = true
		for i in len(game.rover_data):
			if game.rover_data[i] == null:
				game.rover_data[i] = rover_data
				tile.bldg.rover_id = i
				append = false
				break
		if append:
			game.rover_data.append(rover_data)
		game.view.obj.add_time_bar(game.c_t, "bldg")
		game.toggle_panel(self)
		if not game.show.has("vehicles_button"):
			game.show.vehicles_button = true
			if game.planet_HUD:
				game.planet_HUD.get_node("VBoxContainer/Vehicles").visible = true
		game.HUD.refresh()
	else:
		game.popup("NOT_ENOUGH_RESOURCES", 1.5)

func refresh():
	tile = game.tile_data[game.c_t]
	REPs = tile.bldg.path_1 / 20
	$Stats/REPIcon.visible = REPs != 0
	$Stats/REPText.visible = REPs != 0
	armor_slot.get_node("REP").visible = REPs != 0
	wheels_slot.get_node("REP").visible = REPs != 0
	CC_slot.get_node("REP").visible = REPs != 0
	HP = 20.0
	atk = 5.0
	def = 2.0
	weight_cap = round(3000.0 * game.u_i.planck)
	if game.science_unlocked.has("RMK2"):
		HP = 50.0
		atk = 15.0
		def = 10.0
		weight_cap = round(16000.0 * game.u_i.planck)
		REPs += 1
	if game.science_unlocked.has("RMK3"):
		HP = 750.0
		atk = 70.0
		def = 200.0
		weight_cap = round(200000.0 * game.u_i.planck)
		REPs += 1
	$Stats/Ability.visible = ability != ""
	engi_mult = game.engineering_bonus.RSM
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
	var i:int = 0
	var hbox = $Inventory/HBoxLeft
	for node in hbox.get_children():
		node.queue_free()
	for inv in inventory:
		var slot = slot_scene.instance()
		set_slot(inv, slot, i)
		hbox.add_child(slot)
		i += 1
	right_slot.queue_free()
	right_slot = slot_scene.instance()
	$Inventory.add_child(right_slot)
	right_slot.rect_position = Vector2(32, 84)
	set_slot(right_inventory[0], right_slot, 0, true)
	rover_costs.time /= game.u_i.time_speed
	Helper.put_rsrc($ScrollContainer/Grid, 36, rover_costs, true, true)
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
	$Stats/SpeedText.bbcode_text = str(Helper.clever_round(spd_bonus)) + "  [img]Graphics/Icons/help.png[/img]"
	$Stats/SpeedText.help_text = "%s + %s = %s" % [0, spd_bonus, Helper.clever_round((spd_bonus))]
	$Stats/REPText.bbcode_text = str(REPs - REPs_used) + "  [img]Graphics/Icons/help.png[/img]"
	armor_slot.get_node("TextureRect").texture = null if armor == "" else load("res://Graphics/Cave/Armor/%s.png" % [armor])
	wheels_slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Wheels/%s.png" % [wheels])
	CC_slot.get_node("TextureRect").texture = null if CC == "" else load("res://Graphics/Cave/CargoContainer/%s.png" % [CC])

func set_slot(inv:Dictionary, slot, i:int, _right_inv:bool = false):
	var btn = slot.get_node("Button")
	if inv.empty():
		btn.connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["", i, _right_inv])
	elif inv.type == "rover_weapons":
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Weapons/%s.png" % [inv.name])
		btn.connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s" % [Helper.get_rover_weapon_text(inv.name)], i, _right_inv])
		slot.get_node("REP").visible = REPs != 0
		slot.get_node("REP").connect("mouse_entered", self, "_on_REP_mouse_entered")
		slot.get_node("REP").connect("mouse_exited", self, "_on_mouse_exited")
		slot.get_node("REP").connect("pressed", self, "_on_REP_pressed", ["Laser"])
		for cost_key in Data.rover_weapons[inv.name].costs.keys():
			var cost = Data.rover_weapons[inv.name].costs[cost_key]
			if rover_costs.has(cost_key):
				rover_costs[cost_key] += cost
			else:
				rover_costs[cost_key] = cost
	elif inv.type == "rover_mining":
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Mining/%s.png" % [inv.name])
		btn.connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s" % [Helper.get_rover_mining_text(inv.name)], i, _right_inv])
		for cost_key in Data.rover_mining[inv.name].costs.keys():
			var cost = Data.rover_mining[inv.name].costs[cost_key]
			if rover_costs.has(cost_key):
				rover_costs[cost_key] += cost
			else:
				rover_costs[cost_key] = cost
	btn.connect("mouse_exited", self, "_on_Slot_mouse_exited")
	btn.connect("pressed", self, "_on_InvSlot_pressed", [i])

func _on_icon_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))

func _on_icon_mouse_exited():
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("X"):
		if slot_over != -1:
			var inv = inventory[slot_over]
			if right_inv:
				inv = right_inventory[slot_over]
			if inv.has("type"):
				if inv.type == "rover_weapons":
					rover_weapons = false
				elif inv.type == "rover_mining":
					rover_mining = false
				inv.clear()
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

func _on_Ability_mouse_entered():
	game.show_tooltip(tr("RE_" + ability.to_upper()))


func _on_AbilityInfo_mouse_entered():
	if OS.get_latin_keyboard_variant() == "AZERTY":
		game.show_tooltip(tr("ABILITY_INFO") % "A")
	else:
		game.show_tooltip(tr("ABILITY_INFO") % "Q")
