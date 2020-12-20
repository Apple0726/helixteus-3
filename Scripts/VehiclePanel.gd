extends "Panel.gd"

var HP_icon = load("res://Graphics/Icons/HP.png")
var atk_icon = load("res://Graphics/Icons/atk.png")
var def_icon = load("res://Graphics/Icons/def.png")
var inv_icon = load("res://Graphics/Icons/Inventory.png")
var tile_id:int = -1

func _ready():
	set_polygon($Background.rect_size)

func refresh():
	var hbox = $HBox/VBox1/Rovers/HBox
	for rov in hbox.get_children():
		hbox.remove_child(rov)
	for rov in game.rover_data:
		#if rov.c_p == game.c_p or rov.ready:
		if rov.ready:
			var rover = TextureButton.new()
			rover.texture_normal = load("res://Graphics/Cave/Rover.png")
			rover.set_anchors_and_margins_preset(Control.PRESET_CENTER)
			hbox.add_child(rover)
			rover.connect("mouse_entered", self, "on_rover_enter", [rov])
			rover.connect("mouse_exited", self, "on_rover_exit")
			rover.connect("pressed", self, "on_rover_press", [rov])
	$HBox/VBox1.visible = hbox.get_child_count() != 0
	$HBox/VBox2.visible = false

var rover_has_items = false
func on_rover_enter(rov:Dictionary):
	var st = "@i %s\n@i %s\n@i %s\n@i %s kg" % [rov.HP, rov.atk, rov.def, rov.weight_cap]
	if game.help.rover_shortcuts:
		rover_has_items = false
		st += "\n%s" % [tr("CLICK_TO_USE_ROVER")]
		for inv in rov.inventory:
			if inv.type != "rover_weapons" and inv.type != "rover_mining" and inv.type != "":
				rover_has_items = true
		if rover_has_items:
			game.help_str = "rover_shortcuts"
			st += "\n%s\n%s" % [tr("SHIFT_CLICK_TO_LOOT_ROVER"), tr("HIDE_SHORTCUTS")]
	game.show_adv_tooltip(st, [HP_icon, atk_icon, def_icon, inv_icon], 19)

func on_rover_exit():
	game.hide_adv_tooltip()

func on_rover_press(rov:Dictionary):
	if Input.is_action_pressed("shift"):
		if rover_has_items:
			var remaining:bool = false
			for i in len(rov.inventory):
				if rov.inventory[i].type != "rover_weapons" and rov.inventory[i].type != "rover_mining" and rov.inventory[i].has("name"):
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
	elif game.c_v == "planet":
		if tile_id == -1:
			game.view.obj.rover_selected = rov
			game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"), "enter_cave")
			game.toggle_panel(self)
		else:
			game.c_t = tile_id
			tile_id = -1
			game.switch_view("cave")
			game.cave.rover_data = rov
			game.cave.set_rover_data()
			game.toggle_panel(self)

func _on_close_button_pressed():
	game.toggle_panel(self)
