extends "Panel.gd"

var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var select_comp_scene = preload("res://Scenes/Panels/SelectCompPanel.tscn")
var select_comp
var HP:float = 20.0
var atk:float = 5.0
var def:float = 5.0
var weight_cap:float = 3000.0
var movement_speed:float = 0
var inventory = [{"name":"attack", "cooldown":0.2, "damage":2.0}, {"name":"mining", "speed":1.0}, {"name":""}, {"name":""}, {"name":""}]
var tile

onready var armor_slot = $Stats/HBoxContainer/Armor
onready var wheels_slot = $Stats/HBoxContainer/Wheels
onready var CC_slot = $Stats/HBoxContainer/CC#CC: Cargo Container
var armor:String = "lead_armor"
var HP_bonus:int
var def_bonus:int
var wheels:String = "lead_wheels"
var spd_bonus:float
var CC:String = "lead_CC"
var cargo_bonus:int

func _ready():
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

func _on_Slot_mouse_entered(type:String):
	var txt
	var metal:String = tr(self[type.split("_")[1]].split("_")[0].to_upper())
	var comp:String = tr(type.split("_")[1].to_upper())
	var metal_comp:String = tr("METAL_COMP").format({"metal":metal, "comp":comp})
	if type == "rover_armor":
		txt = "%s\n+%s %s" % [metal_comp, def_bonus, tr("DEFENSE")]
	elif type == "rover_wheels":
		txt = "%s\n+%s %s" % [metal_comp, Data.rover_wheels[wheels].speed, tr("MOVEMENT_SPEED")]
	elif type == "rover_CC":
		txt = "%s\n+%s kg %s" % [metal_comp, Data.rover_CC[CC].capacity, tr("CARGO_CAPACITY")]
	txt += "\n%s" % [tr("CLICK_TO_CHANGE")]
	game.show_tooltip(txt)

func _on_InvSlot_mouse_entered(txt:String):
	game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	game.hide_tooltip()

func _on_Slot_pressed(type:String):
	if not game.panels.has(select_comp):
		game.panels.push_front(select_comp)
	select_comp.visible = true
	if type == "rover_armor":
		select_comp.refresh(type, armor)
	elif type == "rover_wheels":
		select_comp.refresh(type, wheels)
	elif type == "rover_CC":
		select_comp.refresh(type, CC)

func _on_Button_pressed():
	if game.check_enough(Data.costs.rover):
		game.deduct_resources(Data.costs.rover)
		game.popup("ROVER_UNDER_CONSTR", 1.5)
		tile.is_constructing = true
		tile.rover_id = len(game.rover_data)
		tile.construction_date = OS.get_system_time_msecs()
		tile.construction_length = Data.costs.rover.time * 1000
		tile.XP = round(Data.costs.rover.money / 100.0)
		game.rover_data.append({"c_p":game.c_p, "ready":false, "HP":HP, "atk":atk, "def":def, "weight_cap":weight_cap, "inventory":inventory, "i_w_w":{}})
		game.view.obj.add_time_bar(game.c_t, "bldg")
		game.toggle_panel(self)
		if not game.show.vehicles_button:
			game.show.vehicles_button = true
			if game.planet_HUD:
				game.planet_HUD.get_node("VBoxContainer/Vehicles").visible = true
	else:
		game.popup("NOT_ENOUGH_RESOURCES", 1.5)

func refresh():
	var rover_costs:Dictionary = Data.costs.rover.duplicate(true)
	for cost_key in Data.rover_armor[armor].costs.keys():
		var cost = Data.rover_armor[armor].costs[cost_key]
		if rover_costs.has(cost_key):
			rover_costs[cost_key] += cost
		else:
			rover_costs[cost_key] = cost
	for cost_key in Data.rover_wheels[wheels].costs.keys():
		var cost = Data.rover_wheels[wheels].costs[cost_key]
		if rover_costs.has(cost_key):
			rover_costs[cost_key] += cost
		else:
			rover_costs[cost_key] = cost
	for cost_key in Data.rover_CC[CC].costs.keys():
		var cost = Data.rover_CC[CC].costs[cost_key]
		if rover_costs.has(cost_key):
			rover_costs[cost_key] += cost
		else:
			rover_costs[cost_key] = cost
	Helper.put_rsrc($VBoxContainer, 36, rover_costs, true, true)
	inventory[0].display_name = tr("LASER")
	inventory[1].display_name = tr("MINING_LASER")
	var hbox = $Inventory/HBoxContainer
	for node in hbox.get_children():
		hbox.remove_child(node)
	for inv in inventory:
		var slot = slot_scene.instance()
		if inv.name == "attack":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/InventoryItems/attack.png")
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s\n%s\n%s\n%s\n%s" % [inv.display_name, tr("LASER_WEAPON_DESC"), "%s: %s" % [tr("DAMAGE"), inv.damage], "%s: %s%s" % [tr("COOLDOWN"), inv.cooldown, tr("S_SECOND")], tr("CLICK_TO_REMOVE")]])
		elif inv.name == "mining":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/InventoryItems/mining.png")
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", ["%s\n%s\n%s\n%s" % [inv.display_name, tr("MINING_LASER_DESC"), "%s: %s" % [tr("MINING_SPEED"), inv.speed], tr("CLICK_TO_REMOVE")]])
		else:
			slot.get_node("Button").connect("mouse_entered", self, "_on_InvSlot_mouse_entered", [tr("CLICK_TO_ADD_COMP")])
		slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
		hbox.add_child(slot)
	HP_bonus = Data.rover_armor[armor].HP
	def_bonus = Data.rover_armor[armor].defense
	spd_bonus = Data.rover_wheels[wheels].speed
	cargo_bonus = Data.rover_CC[CC].capacity
	$Stats/Label2.text = "%s\n%s\n%s\n%s kg\n%s" % [HP + HP_bonus, atk, def + def_bonus, weight_cap + cargo_bonus, movement_speed + spd_bonus]
	tile = game.tile_data[game.c_t]
	armor_slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Armor/%s.png" % [armor])
	wheels_slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Wheels/%s.png" % [wheels])
	CC_slot.get_node("TextureRect").texture = load("res://Graphics/Cave/CargoContainer/%s.png" % [CC])

func _on_icon_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))

func _on_icon_mouse_exited():
	game.hide_tooltip()
