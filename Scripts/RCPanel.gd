extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var HP:float = 20.0
var atk:float = 5.0
var def:float = 5.0
var weight_cap:float = 8000.0
var inventory = [{"name":"attack", "cooldown":0.2, "damage":2.0}, {"name":"mining", "speed":1.0}, {"name":""}, {"name":""}, {"name":""}]
var tile

func _ready():
	tween = Tween.new()
	add_child(tween)

func _on_Slot_mouse_entered(txt:String):
	game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	game.hide_tooltip()

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
	Helper.put_rsrc($VBoxContainer, 36, Data.costs.rover, true, true)
	inventory[0].display_name = tr("LASER")
	inventory[1].display_name = tr("MINING_LASER")
	var hbox = $Inventory/HBoxContainer
	for node in hbox.get_children():
		hbox.remove_child(node)
	for inv in inventory:
		var slot = slot_scene.instance()
		if inv.name == "attack":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/InventoryItems/attack.png")
			slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["%s\n%s\n%s\n%s\n%s" % [inv.display_name, tr("LASER_WEAPON_DESC"), "%s: %s" % [tr("DAMAGE"), inv.damage], "%s: %s%s" % [tr("COOLDOWN"), inv.cooldown, tr("S_SECOND")], tr("CLICK_TO_REMOVE")]])
		elif inv.name == "mining":
			slot.get_node("TextureRect").texture = load("res://Graphics/Cave/InventoryItems/mining.png")
			slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", ["%s\n%s\n%s\n%s" % [inv.display_name, tr("MINING_LASER_DESC"), "%s: %s" % [tr("MINING_SPEED"), inv.speed], tr("CLICK_TO_REMOVE")]])
		else:
			slot.get_node("Button").connect("mouse_entered", self, "_on_Slot_mouse_entered", [tr("CLICK_TO_ADD_COMP")])
		slot.get_node("Button").connect("mouse_exited", self, "_on_Slot_mouse_exited")
		hbox.add_child(slot)
	$Stats/Label2.text = "%s\n%s\n%s\n%s kg" % [HP, atk, def, weight_cap]
	tile = game.tile_data[game.c_t]
