extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var polygon:PoolVector2Array = [Vector2(106.5, 70), Vector2(106.5 + 1067, 70), Vector2(106.5 + 1067, 70 + 600), Vector2(106.5, 70 + 600)]
var HP_icon = load("res://Graphics/Icons/HP.png")
var atk_icon = load("res://Graphics/Icons/atk.png")
var def_icon = load("res://Graphics/Icons/def.png")
var inv_icon = load("res://Graphics/Icons/Inventory.png")
var tile_id:int = -1

func _ready():
	tween = Tween.new()
	add_child(tween)

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
	if hbox.get_child_count() == 0:
		$HBox/VBox1/Rovers.visible = false
	else:
		$HBox/VBox1/Rovers.visible = true

func on_rover_enter(rov:Dictionary):
	var st = "@i %s\n@i %s\n@i %s\n@i %s / %s kg" % [rov.HP, rov.atk, rov.def, Helper.get_sum_of_dict(rov.i_w_w), rov.weight_cap]
	var show_shortcut = false
	if game.help.rover_shortcuts:
		st += "\n%s" % [tr("CLICK_TO_USE_ROVER")]
		for inv in rov.inventory:
			if inv.type != "rover_weapons" and inv.type != "rover_mining" and inv.type != "":
				show_shortcut = true
		show_shortcut = show_shortcut or not rov.i_w_w.empty()
		if show_shortcut:
			game.help_str = "rover_shortcuts"
			st += "\n%s\n%s" % [tr("SHIFT_CLICK_TO_LOOT_ROVER"), tr("HIDE_SHORTCUTS")]
	game.show_adv_tooltip(st, [HP_icon, atk_icon, def_icon, inv_icon], 19)

func on_rover_exit():
	game.hide_adv_tooltip()

func on_rover_press(rov:Dictionary):
	if Input.is_action_pressed("shift"):
		for i in len(rov.inventory):
			if rov.inventory[i].name == "money":
				game.money += rov.inventory[i].num
				rov.inventory[i] = {"name":""}
			elif rov.inventory[i].name == "minerals":
				game.minerals += rov.inventory[i].num
				rov.inventory[i] = {"name":""}
			elif rov.inventory[i].type != "rover_weapons" and rov.inventory[i].type != "rover_mining" and rov.inventory[i].has("name"):
				game.add_items(rov.inventory[i].name, rov.inventory[i].num)
				rov.inventory[i] = {"name":""}
		game.add_resources(rov.i_w_w)
		rov.i_w_w = {}
		game.popup(tr("ITEMS_COLLECTED"), 1.5)
	elif game.c_v == "planet":
		if tile_id == -1:
			game.view.obj.rover_selected = rov
			game.put_bottom_info(tr("CLICK_A_CAVE_TO_EXPLORE"))
			game.toggle_panel(self)
		else:
			game.c_t = tile_id
			tile_id = -1
			game.switch_view("cave")
			game.cave.rover_data = rov
			game.cave.set_rover_data()
			game.toggle_panel(self)
