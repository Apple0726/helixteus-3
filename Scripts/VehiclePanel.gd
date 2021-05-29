extends "Panel.gd"

var HP_icon = load("res://Graphics/Icons/HP.png")
var atk_icon = load("res://Graphics/Icons/atk.png")
var def_icon = load("res://Graphics/Icons/def.png")
var inv_icon = load("res://Graphics/Icons/Inventory.png")
var spd_icon = load("res://Graphics/Icons/eva.png")
var tile_id:int = -1
var rover_has_items = false
var rover_over_id:int = -1
var probe_time_bars:Array = []

func _ready():
	set_polygon($Background.rect_size)

func _input(event):
	if modulate.a == 1 and Input.is_action_just_released("X") and rover_over_id != -1:
		game.rover_data[rover_over_id] = null
		rover_over_id = -1
		game.hide_adv_tooltip()
		refresh()

func refresh():
	var hbox = $HBox/VBox1/Rovers/HBox
	var hbox2 = $HBox/VBox1/GridContainer
	var hbox3 = $HBox/VBox2/Probes/GridContainer
	for rov in hbox.get_children():
		hbox.remove_child(rov)
		rov.free()
	for fgh in hbox2.get_children():
		hbox2.remove_child(fgh)
		fgh.free()
	for probe in hbox3.get_children():
		hbox3.remove_child(probe)
		probe.free()
	probe_time_bars.clear()
	for i in len(game.rover_data):
		var rov = game.rover_data[i]
		if not rov:
			continue
		#if rov.c_p == game.c_p or rov.ready:
		if rov.ready:
			var rover = TextureButton.new()
			rover.texture_normal = load("res://Graphics/Cave/Rover.png")
			rover.set_anchors_and_margins_preset(Control.PRESET_CENTER)
			hbox.add_child(rover)
			rover.connect("mouse_entered", self, "on_rover_enter", [rov, i])
			rover.connect("mouse_exited", self, "on_rover_exit")
			rover.connect("pressed", self, "on_rover_press", [rov, i])
	for i in len(game.fighter_data):
		var fighter_info = game.fighter_data[i]
		var fighter = TextureButton.new()
		var fighter_num = Label.new()
		fighter_num.text = "x %s" % [fighter_info.number]
		fighter_num.align = Label.ALIGN_CENTER
		fighter_num.rect_position = Vector2(40, 70)
		fighter.texture_normal = load("res://Graphics/Ships/Fighter.png")
		fighter.expand = true
		fighter.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		fighter.rect_min_size = Vector2(80, 80)
		fighter.add_child(fighter_num)
		hbox2.add_child(fighter)
		fighter.connect("mouse_entered", self, "on_fighter_enter", [fighter_info])
		fighter.connect("mouse_exited", self, "on_fighter_exit")
		fighter.connect("pressed", self, "on_fighter_press", [i])
	for i in len(game.probe_data):
		var probe_info:Dictionary = game.probe_data[i]
		var probe = TextureButton.new()
		probe.texture_normal = load("res://Graphics/Ships/Probe%s.png" % probe_info.tier)
		probe.expand = true
		probe.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		probe.rect_min_size = Vector2(80, 80)
		hbox3.add_child(probe)
		probe.connect("mouse_entered", self, "on_probe_enter")
		probe.connect("mouse_exited", self, "on_fighter_exit")
		probe.connect("pressed", self, "on_probe_press", [probe_info.tier])
		if probe_info.has("start_date"):
			var time_bar:Control = game.time_scene.instance()
			time_bar.rect_scale *= 0.5
			time_bar.rect_position = Vector2(30, 0)
			probe.add_child(time_bar)
			probe_time_bars.append({"node":time_bar, "i":i})
	$HBox/VBox1.visible = hbox.get_child_count() != 0
	$HBox/VBox1/Fighters.visible = hbox2.get_child_count() != 0
	$HBox/VBox1/GridContainer.visible = hbox2.get_child_count() != 0
	$HBox/VBox2.visible = hbox3.get_child_count() != 0
	set_process(false)
	for probe in game.probe_data:
		if probe.has("start_date"):
			set_process(true)
			break

func _process(delta):
	var curr_time = OS.get_system_time_msecs()
	for dict in probe_time_bars:
		var i = dict.i
		var probe = game.probe_data[i]
		var bar = dict.node
		var start_date = probe.start_date
		var length = probe.explore_length
		var progress = (curr_time - start_date) / float(length)
		bar.get_node("TimeString").text = Helper.time_to_str(length - curr_time + start_date)
		bar.get_node("Bar").value = progress
		if progress >= 1:
			if probe.tier == 0:
				var cluster_data:Array
				if game.c_v == "supercluster" and game.c_sc == 0:
					cluster_data = game.cluster_data
				else:
					cluster_data = game.open_obj("Superclusters", 0)
				cluster_data[probe.obj_to_discover].visible = true
				Helper.save_obj("Superclusters", 0, cluster_data)
				game.popup(tr("CLUSTER_DISCOVERED_BY_PROBE"), 3)
			elif probe.tier == 1:
				var supercluster_data:Array
				if game.c_v == "universe":
					supercluster_data = game.supercluster_data
					supercluster_data[probe.obj_to_discover].visible = true
				else:
					var save_sc = File.new()
					save_sc.open("user://Save1/supercluster_data.hx3", File.READ_WRITE)
					supercluster_data = save_sc.get_var()
					supercluster_data[probe.obj_to_discover].visible = true
					save_sc.seek(0)
					save_sc.store_var(supercluster_data)
					save_sc.close()
				game.popup(tr("CLUSTER_DISCOVERED_BY_PROBE"), 3)
			game.probe_data.remove(i)
			refresh()

func on_rover_enter(rov:Dictionary, rov_id:int):
	rover_over_id = rov_id
	var st = "@i %s\n@i %s\n@i %s\n@i %s kg\n@i %s" % [rov.HP, rov.atk, rov.def, rov.weight_cap, Helper.clever_round(rov.spd, 3)]
	if game.help.rover_shortcuts:
		rover_has_items = false
		st += "\n%s\n%s" % [tr("CLICK_TO_USE_ROVER"), tr("PRESS_X_TO_DESTROY")]
		for inv in rov.inventory:
			if inv.type != "rover_weapons" and inv.type != "rover_mining" and inv.type != "":
				rover_has_items = true
				break
		if rover_has_items:
			game.help_str = "rover_shortcuts"
			st += "\n%s\n%s" % [tr("SHIFT_CLICK_TO_LOOT_ROVER"), tr("HIDE_SHORTCUTS")]
	game.show_adv_tooltip(st, [HP_icon, atk_icon, def_icon, inv_icon, spd_icon], 19)

func on_fighter_enter(fighter_info:Dictionary):
	game.show_tooltip("%s: %s\n%s" % [tr("FLEET_STRENGTH"), fighter_info.strength, tr("CLICK_TO_VIEW_GALAXY")])

func on_probe_enter():
	game.show_tooltip(tr("CLICK_TO_VIEW_SC"))

func on_fighter_exit():
	game.hide_tooltip()

func on_fighter_press(i:int):
	_on_close_button_pressed()
	game.switch_view("galaxy", false, "set_to_fighter_coords", [i])

func on_probe_press(tier:int):
	_on_close_button_pressed()
	if tier == 0:
		game.switch_view("supercluster", false, "set_to_probe_coords", [0])
	elif tier == 1:
		game.switch_view("universe")

func on_rover_exit():
	rover_over_id = -1
	rover_has_items = false
	game.hide_adv_tooltip()

func on_rover_press(rov:Dictionary, rov_id:int):
	if Input.is_action_pressed("shift"):
		if rover_has_items:
			var remaining:bool = false
			for i in len(rov.inventory):
				if rov.inventory[i].type != "rover_weapons" and rov.inventory[i].type != "rover_mining" and rov.inventory[i].has("name"):
					if rov.inventory[i].name == "minerals":
						rov.inventory[i].num = Helper.add_minerals(rov.inventory[i].num).remainder
						if rov.inventory[i].num <= 0:
							rov.inventory[i] = {"type":""}
						else:
							remaining = true
					else:
						var remainder:int = game.add_items(rov.inventory[i].name, rov.inventory[i].num)
						if remainder > 0:
							remaining = true
							rov.inventory[i].num = remainder
						else:
							rov.inventory[i] = {"type":""}
			if remaining:
				game.popup(tr("NOT_ENOUGH_INV_SPACE_COLLECT"), 2)
			else:
				game.popup(tr("ITEMS_COLLECTED"), 1.5)
			game.HUD.refresh()
	elif game.c_v == "planet":
		if tile_id == -1:
			game.view.obj.rover_selected = rov_id
			game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"), "enter_cave")
			game.toggle_panel(self)
		else:
			game.c_t = tile_id
			tile_id = -1
			game.rover_id = rov_id
			if game.tile_data[game.c_t].has("cave") or game.tile_data[game.c_t].has("diamond_tower"):
				game.switch_view("cave")
			else:
				game.switch_view("ruins")
			game.toggle_panel(self)

func _on_close_button_pressed():
	game.toggle_panel(self)
