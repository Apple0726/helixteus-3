extends "Panel.gd"

enum {
	ROVERS,
	FIGHTERS,
	PROBES,
}
var tab = ROVERS

var HP_icon = preload("res://Graphics/Icons/HP.png")
var atk_icon = preload("res://Graphics/Icons/atk.png")
var def_icon = preload("res://Graphics/Icons/def.png")
var inv_icon = preload("res://Graphics/Icons/Inventory.png")
var spd_icon = preload("res://Graphics/Icons/eva.png")
var tile_id:int = -1
var rover_has_items = false
var probe_time_bars:Array = []

func _ready():
	set_polygon(size)
	$HBoxContainer/Rovers._on_Button_pressed()
	_on_rovers_pressed()

func _input(event):
	super(event)

func refresh():
	$HBoxContainer/Fighters.visible = game.science_unlocked.has("FG")
	$HBoxContainer/Probes.visible = game.u_i.lv >= 60
	if tab == ROVERS:
		_on_rovers_pressed()
	elif tab == FIGHTERS:
		_on_fighters_pressed()
	elif tab == PROBES:
		_on_probes_pressed()

func _on_Timer_timeout():
	if not visible:
		return
	var curr_time = Time.get_unix_time_from_system()
	var refresh:bool = false
	for dict in probe_time_bars:
		var i = dict.i
		var probe = game.probe_data[i]
		var bar = dict.node
		if not probe.has("start_date"):
			continue
		var start_date = probe.start_date
		var length = probe.explore_length
		var progress = (curr_time - start_date) / float(length)
		bar.get_node("TimeString").text = Helper.time_to_str(length - curr_time + start_date)
		bar.get_node("Bar").value = progress
		if progress >= 1:
			if probe.tier == 0:
				game.u_i.cluster_data[probe.obj_to_discover].visible = true
				game.popup(tr("CLUSTER_DISCOVERED_BY_PROBE"), 3)
				refresh = true
			game.probe_data[i] = null
	if refresh:
		refresh()
	await get_tree().process_frame
	$Timer.start()


func _on_rovers_pressed():
	tab = ROVERS
	for vehicle in $ScrollContainer/VBoxContainer.get_children():
		vehicle.queue_free()
	for i in len(game.rover_data):
		var rover = game.rover_data[i]
		if rover == null:
			continue
		if rover.ready:
			var rover_info = preload("res://Scenes/RoverInfo.tscn").instantiate()
			$ScrollContainer/VBoxContainer.add_child(rover_info)
			if rover.get("MK", 1) == 2:
				rover_info.get_node("RoverIcon").texture = preload("res://Graphics/Cave/Rover2.png")
			elif rover.get("MK", 1) == 3:
				rover_info.get_node("RoverIcon").texture = preload("res://Graphics/Cave/Rover3.png")
			else:
				rover_info.get_node("RoverIcon").texture = preload("res://Graphics/Cave/Rover.png")
			rover_info.get_node("HPLabel").text = Helper.format_num(rover.HP)
			rover_info.get_node("InventoryLabel").text = Helper.format_num(rover.weight_cap) + " kg"
			var rover_has_items = false
			var rover_has_space_for_items = false
			for inv in rover.inventory:
				if not inv.is_empty() and inv.type not in ["rover_weapons", "rover_mining", ""]:
					rover_has_items = true
				if inv.is_empty():
					rover_has_space_for_items = true
			if rover_has_items:
				rover_info.get_node("HBox/TakeAll").pressed.connect(rover_take_all.bind(i))
			else:
				rover_info.get_node("HBox/TakeAll").disabled = true
			if rover_has_space_for_items:
				rover_info.get_node("HBox/SendItems").pressed.connect(rover_send_items.bind(i))
			else:
				rover_info.get_node("HBox/SendItems").disabled = true
			rover_info.get_node("RoverIcon").mouse_entered.connect(rover_show_details.bind(i))
			rover_info.get_node("RoverIcon").mouse_exited.connect(game.hide_tooltip)
			rover_info.get_node("HBox/Explore").pressed.connect(rover_explore.bind(i))
			rover_info.get_node("HBox/Destroy").pressed.connect(rover_destroy.bind(i, rover_info))

func rover_show_details(rover_id:int):
	var rover = game.rover_data[rover_id]
	var tooltip_txt = "@i %s\n@i %s\n@i %s\n@i %s kg\n@i %s" % [
		Helper.format_num(rover.HP),
		Helper.format_num(rover.atk),
		Helper.format_num(rover.def),
		Helper.format_num(rover.weight_cap),
		Helper.clever_round(rover.spd),
	]
	game.show_adv_tooltip(tooltip_txt, [HP_icon, atk_icon, def_icon, inv_icon, spd_icon], 19)


func rover_take_all(rover_id:int):
	var remaining:bool = false
	var rover:Dictionary = game.rover_data[rover_id]
	for i in len(rover.inventory):
		if rover.inventory[i].is_empty() or rover.inventory[i].type in ["rover_weapons", "rover_mining"]:
			continue
		if rover.inventory[i].id is int:
			var remainder:int = game.add_items(rover.inventory[i].id, rover.inventory[i].num)
			if remainder > 0:
				remaining = true
				rover.inventory[i].num = remainder
			else:
				rover.inventory[i].clear()
		elif rover.inventory[i].id == "minerals":
			rover.inventory[i].num = Helper.add_minerals(rover.inventory[i].num).remainder
			if rover.inventory[i].num <= 0:
				rover.inventory[i].clear()
			else:
				remaining = true
		elif rover.inventory[i].id == "money":
			game.money += rover.inventory[i].num
			rover.inventory[i].clear()
	if remaining:
		game.popup(tr("NOT_ENOUGH_INV_SPACE_COLLECT"), 2)
	else:
		game.popup(tr("ITEMS_COLLECTED"), 1.5)
	_on_rovers_pressed()
	game.HUD.refresh()

func rover_send_items(rover_id:int):
	game.toggle_panel("inventory")
	game.inventory.send_to_rover = rover_id

func rover_explore(rover_id:int):
	if tile_id == -1:
		game.view.obj.rover_selected = rover_id
		game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"), "enter_cave")
		game.toggle_panel("vehicle_panel")
	else:
		game.c_t = tile_id
		tile_id = -1
		game.rover_id = rover_id
		var rover_MK = game.rover_data[rover_id].MK
		if rover_MK == 3:
			game.popup_window("", "", [tr("GO_TO_FLOOR_X") % 16, tr("GO_TO_FLOOR_X") % 8, tr("START_AT_FLOOR_1")], [Callable(game, "switch_view").bind("cave", {"start_floor":16}), Callable(game, "switch_view").bind("cave", {"start_floor":8}), Callable(game, "switch_view").bind("cave")], tr("CANCEL"))
		elif rover_MK == 2:
			game.popup_window("", "", [tr("GO_TO_FLOOR_X") % 8, tr("START_AT_FLOOR_1")], [Callable(game, "switch_view").bind("cave", {"start_floor":8}), Callable(game, "switch_view").bind("cave")], tr("CANCEL"))
		else:
			game.switch_view("cave")
		game.toggle_panel("vehicle_panel")

func rover_destroy(rover_id:int, rover_node):
	game.rover_data[rover_id] = null
	rover_node.queue_free()

func _on_fighters_pressed():
	tab = FIGHTERS
	for vehicle in $ScrollContainer/VBoxContainer.get_children():
		vehicle.queue_free()
	for i in len(game.fighter_data):
		if game.fighter_data[i] == null:
			continue
		var fighter_info = game.fighter_data[i]
		var fighter = preload("res://Scenes/FighterInfo.tscn").instantiate()
		fighter.get_node("NumberLabel").text = "x %s" % [fighter_info.number]
		fighter.get_node("StrengthLabel").text = Helper.format_num(fighter_info.strength)
		fighter.get_node("LocationLabel").text = fighter_info.location_name
		if fighter_info.tier == 0:
			fighter.get_node("FighterIcon").texture_normal = preload("res://Graphics/Ships/Fighter.png")
		elif fighter_info.tier == 1:
			fighter.get_node("FighterIcon").texture_normal = preload("res://Graphics/Ships/Fighter2.png")
		$ScrollContainer/VBoxContainer.add_child(fighter)
		fighter.get_node("GoTo").pressed.connect(fighter_go_to.bind(i))
		fighter.get_node("Disband").pressed.connect(fighter_disband.bind(i, fighter))

func fighter_go_to(fighter_id:int):
	_on_close_button_pressed()
	if game.fighter_data[fighter_id].tier == 0:
		game.switch_view("galaxy", {"fn":"set_to_fighter_coords", "fn_args":[fighter_id]})
	elif game.fighter_data[fighter_id].tier == 1:
		game.switch_view("cluster", {"fn":"set_to_fighter_coords", "fn_args":[fighter_id]})

func fighter_disband(fighter_id:int, fighter_node):
	game.fighter_data[fighter_id] = null
	fighter_node.queue_free()


func _on_probes_pressed():
	tab = PROBES
	for vehicle in $ScrollContainer/VBoxContainer.get_children():
		vehicle.queue_free()
	var probe_num:int = 0
	for i in len(game.probe_data):
		if game.probe_data[i] == null:
			continue
		probe_num += 1
		var probe_info:Dictionary = game.probe_data[i]
		var probe = preload("res://Scenes/ProbeInfo.tscn").instantiate()
		probe.get_node("LocationLabel").text = game.u_i.name
		probe.get_node("ProbeIcon").texture_normal = load("res://Graphics/Ships/Probe%s.png" % probe_info.tier)
		$ScrollContainer/VBoxContainer.add_child(probe)
		probe.get_node("GoTo").pressed.connect(probe_go_to.bind(probe_info.tier))
		probe.get_node("Disband").pressed.connect(probe_disband.bind(i, probe))
		if probe_info.has("start_date"):
			var time_bar:Control = game.time_scene.instantiate()
			time_bar.scale *= 0.5
			time_bar.position = Vector2(30, 0)
			probe.add_child(time_bar)
			probe_time_bars.append({"node":time_bar, "i":i})
	$Probes/Label.text = "%s (%s / %s)" % [tr("PROBES"), probe_num, 500]
	for probe in game.probe_data:
		if probe and probe.has("start_date"):
			$Timer.start()
			_on_Timer_timeout()
			break

func probe_go_to(probe_tier:int):
	_on_close_button_pressed()
	if probe_tier == 0:
		game.switch_view("universe")
	else:
		game.switch_view("dimension")

func probe_disband(probe_id:int, probe_node):
	game.probe_data[probe_id] = null
	probe_node.queue_free()
