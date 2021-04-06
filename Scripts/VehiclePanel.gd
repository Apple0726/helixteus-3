extends "Panel.gd"

var HP_icon = load("res://Graphics/Icons/HP.png")
var atk_icon = load("res://Graphics/Icons/atk.png")
var def_icon = load("res://Graphics/Icons/def.png")
var inv_icon = load("res://Graphics/Icons/Inventory.png")
var spd_icon = load("res://Graphics/Icons/eva.png")
var tile_id:int = -1
var rover_has_items = false
var rover_over_id:int = -1

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
	var hbox2 = $HBox/VBox2/GridContainer
	for rov in hbox.get_children():
		hbox.remove_child(rov)
		rov.free()
	for fgh in hbox2.get_children():
		hbox2.remove_child(fgh)
		fgh.free()
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
		if not fighter_info:
			continue
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
	$HBox/VBox1.visible = hbox.get_child_count() != 0
	$HBox/VBox2.visible = hbox2.get_child_count() != 0

func on_rover_enter(rov:Dictionary, rov_id:int):
	rover_over_id = rov_id
	var st = "@i %s\n@i %s\n@i %s\n@i %s kg\n@i %s" % [rov.HP, rov.atk, rov.def, rov.weight_cap, game.clever_round(rov.spd, 3)]
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

func on_fighter_exit():
	game.hide_tooltip()

func on_fighter_press(i:int):
	_on_close_button_pressed()
	game.switch_view("galaxy", false, "set_to_fighter_coords", [i])
	
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
			game.switch_view("cave")
			game.toggle_panel(self)

func _on_close_button_pressed():
	game.toggle_panel(self)
