extends "Panel.gd"

var tab:String
var buy_sell_scene = preload("res://Scenes/Panels/BuySellPanel.tscn")
var buy_sell
@onready var inventory_grid = $Control/VBox/Inventory
@onready var grid = $Control/VBox/GridContainer
@onready var particles_hbox = $Control/ParticlesHBox
@onready var info = $Control/VBox/Info
var item_hovered:String = ""
var item_stack:int = 0
var item_slot:int = 0
var hbox_data:Array = []

func _ready():
	set_polygon(size)
	buy_sell = buy_sell_scene.instantiate()
	buy_sell.visible = false
	add_child(buy_sell)
	_on_Items_pressed()
	$TabBar/Items._on_Button_pressed()

func refresh():
	if tab == "items":
		_on_Items_pressed()
	elif tab == "materials":
		_on_Materials_pressed()
	elif tab == "metals":
		_on_Metals_pressed()
	elif tab == "atoms":
		_on_Atoms_pressed()
	elif tab == "particles":
		_on_Particles_pressed()
	$TabBar/Materials.visible = game.show.has("materials")
	$TabBar/Metals.visible = game.show.has("metals")
	$TabBar/Atoms.visible = game.show.has("atoms")
	$TabBar/Particles.visible = game.show.has("particles")

func _on_Items_pressed():
	set_process(false)
	tab = "items"
	info.text = tr("INV_ITEMS_DESC")
	inventory_grid.visible = true
	grid.visible = false
	particles_hbox.visible = false
	for item in inventory_grid.get_children():
		inventory_grid.remove_child(item)
		item.free()
	var i:int = 0
	for item in game.items:
		var slot = game.slot_scene.instantiate()
		if item != null:
			slot.get_node("Label").text = str(item.num)
			slot.get_node("TextureRect").texture = load("res://Graphics/" + Helper.get_dir_from_name(item.name)  + "/" + item.name + ".png")
			slot.get_node("Button").connect("mouse_entered",Callable(self,"on_slot_over").bind(item.name, item.num, i))
			slot.get_node("Button").connect("mouse_exited",Callable(self,"on_slot_out"))
			slot.get_node("Button").connect("pressed",Callable(self,"on_slot_press").bind(item.name))
		inventory_grid.add_child(slot)
		i += 1
	$Control/VBox/BuySell.visible = false

func on_slot_over (_name:String, num:int, slot:int):
	var st:String = Helper.get_item_name(_name)
	if game.other_items_info.has(_name):
		if _name.substr(0, 7) == "hx_core":
			st += "\n%s" % [tr("HX_CORE_DESC") % Helper.format_num(game.other_items_info[_name].XP)]
	item_slot = slot
	item_hovered = _name
	item_stack = num
	game.help_str = "inventory_shortcuts"
	if game.help.has("inventory_shortcuts"):
		st += "\n%s\n%s\n%s\n%s\n%s" % [tr("CLICK_TO_USE"), tr("SHIFT_CLICK_TO_USE_ALL"), tr("X_TO_THROW_ONE"), tr("SHIFT_X_TO_THROW_STACK"), tr("H_FOR_HOTBAR")] + "\n" + tr("HIDE_SHORTCUTS")
	game.show_tooltip(st)

func on_slot_out():
	item_hovered = ""
	game.hide_tooltip()

func on_slot_press(_name:String):
	game.hide_tooltip()
	var num:int
	if Input.is_action_pressed("shift"):
		num = game.get_item_num(_name)
	else:
		num = 1
	if game.get_node("UI/BottomInfo").visible:
		game._on_BottomInfo_close_button_pressed(true)
	game.item_to_use.name = _name
	game.item_to_use.num = num
	var texture
	var type:String = Helper.get_type_from_name(_name)
	if type == "craft_mining_info":
		game.remove_items(_name)
		game.pickaxe.speed_mult = game.craft_mining_info[_name].speed_mult
		game.pickaxe.liquid_dur = game.craft_mining_info[_name].durability
		game.pickaxe.liquid_name = _name
		if game.active_panel == self:
			game.toggle_panel(self)
		game.popup("SUCCESSFULLY_APPLIED", 1.5)
		return
	elif type == "craft_cave_info":
		game.put_bottom_info(tr("CLICK_ON_ROVER_TO_GIVE"), "give_rover_items", "hide_item_cursor")
		game.item_to_use.type = "cave"
		game.toggle_panel(game.vehicle_panel)
	elif type == "speedups_info":
		if game.c_v == "system" and game.science_unlocked.has("MAE"):
			game.put_bottom_info(tr("USE_SPEEDUP_MS") % 5, "use_speedup", "hide_item_cursor")
		else:
			game.put_bottom_info(tr("USE_SPEEDUP_INFO"), "use_speedup", "hide_item_cursor")
		game.item_to_use.type = "speedup"
	elif type == "overclocks_info":
		game.put_bottom_info(tr("USE_OVERCLOCK_INFO"), "use_overclock", "hide_item_cursor")
		game.item_to_use.type = "overclock"
	elif type == "other_items_info":
		if _name.substr(0, 7) == "hx_core":
			if len(game.ship_data) > 0:
				game.put_bottom_info(tr("CLICK_SHIP_TO_GIVE_XP"), "use_hx_core", "hide_item_cursor")
				game.toggle_panel(game.ship_panel)
				game.ship_panel._on_BackButton_pressed()
			else:
				game.popup(tr("NO_SHIPS_2"), 1.5)
				return
	if game.active_panel == self:
		game.toggle_panel(self)
	texture = load("res://Graphics/" + Helper.get_dir_from_name(_name) + "/" + _name + ".png")
	game.show_item_cursor(texture)

func _on_Materials_pressed():
	set_process(not game.autocollect.mats.is_empty())
	tab = "materials"
	info.text = tr("INV_MAT_DESC")
	inventory_grid.visible = false
	grid.visible = true
	particles_hbox.visible = false
	hbox_data = Helper.put_rsrc(grid, 48, game.mats, true, false, false)
	for mat in hbox_data:
		if not game.show.has(mat.name):
			mat.rsrc.visible = false
			continue
		var texture = mat.rsrc.get_node("Texture2D")
		texture.connect("mouse_entered",Callable(self,"show_mat").bind(mat.name))
		texture.connect("mouse_exited",Callable(self,"on_mouse_out"))
		texture.connect("pressed",Callable(self,"show_buy_sell").bind("Materials", mat.name))
	$Control/VBox/BuySell.visible = true

func _on_Metals_pressed():
	set_process(not game.autocollect.mets.is_empty())
	tab = "metals"
	info.text = tr("INV_MET_DESC")
	inventory_grid.visible = false
	grid.visible = true
	particles_hbox.visible = false
	hbox_data = Helper.put_rsrc(grid, 48, game.mets, true, false, false)
	for met in hbox_data:
		if not game.show.has(met.name):
			met.rsrc.visible = false
			continue
		var texture = met.rsrc.get_node("Texture2D")
		texture.connect("mouse_entered",Callable(self,"show_met").bind(met.name))
		texture.connect("mouse_exited",Callable(self,"on_mouse_out"))
		texture.connect("pressed",Callable(self,"show_buy_sell").bind("Metals", met.name))
	$Control/VBox/BuySell.visible = true

func _on_Atoms_pressed():
	set_process(not game.autocollect.atoms.is_empty())
	tab = "atoms"
	info.text = tr("INV_ATOMS_DESC")
	inventory_grid.visible = false
	grid.visible = true
	particles_hbox.visible = false
	hbox_data = Helper.put_rsrc(grid, 48, game.atoms, true, false, false)
	for atom in hbox_data:
		if not game.show.has(atom.name):
			atom.rsrc.visible = false
		var texture = atom.rsrc.get_node("Texture2D")
		texture.connect("mouse_entered",Callable(self,"show_atom").bind(atom.name))
		texture.connect("mouse_exited",Callable(self,"on_mouse_out"))
	$Control/VBox/BuySell.visible = false

func _on_Particles_pressed():
	set_process(true)
	tab = "particles"
	info.text = tr("INV_PARTICLES_DESC")
	inventory_grid.visible = false
	grid.visible = false
	particles_hbox.visible = true
	$Control/VBox/BuySell.visible = false

func show_part(_name:String):
	var neutron_cap = game.neutron_cap * Helper.get_IR_mult("NSF")
	var st:String = "%s\n%s" % [tr(_name.to_upper()), tr(_name.to_upper() + "_DESC")]
	if game.autocollect.particles.has(_name):
		var num:float = 0.0
		if _name in ["proton", "electron"]:
			if game.particles.neutron > neutron_cap:
				num = game.autocollect.particles[_name] + (game.particles.neutron - neutron_cap) * (1 - pow(0.5, game.u_i.time_speed / 900.0)) / 2.0
			else:
				num = game.autocollect.particles[_name]
		elif _name == "neutron":
			if game.particles.neutron > neutron_cap:
				num = game.autocollect.particles[_name] - (game.particles.neutron - neutron_cap) * (1 - pow(0.5, game.u_i.time_speed / 900.0))
			else:
				num = game.autocollect.particles[_name]
		st += "\n" + (tr("YOU_PRODUCE") if num >= 0 else tr("YOU_USE")) % ("%s/%s" % [Helper.format_num(abs(num), true), tr("S_SECOND")])
	game.show_tooltip(st)
	
func show_buy_sell(type:String, obj:String):
	var amount = 0
	var value = 0
	if type == "Materials":
		amount = game.mats[obj]
		value = game.mat_info[obj].value
	elif type == "Metals":
		amount = game.mets[obj]
		value = game.met_info[obj].value
	var forced = false
	if game.money <= 0:
		if amount <= 0:
			game.popup("PURCHASE_SALE_IMPOSSIBLE", 1.5)
			return
		buy_sell.is_selling = true
		forced = true
	elif amount <= 0:
		buy_sell.is_selling = false
		forced = true
	if not forced:
		buy_sell.is_selling = game.money < amount * value * game.maths_bonus.MMBSVR * 5.0
	buy_sell.visible = true
	game.sub_panel = buy_sell
	buy_sell.refresh(type, obj)

func show_mat(mat:String):
	var st:String = "%s\n%s" % [get_str(mat), get_str(mat, "_DESC")]
	if game.autocollect.mats.has(mat) and not is_zero_approx(game.autocollect.mats[mat]):
		st += "\n" + (tr("YOU_PRODUCE") if game.autocollect.mats[mat] > 0 else tr("YOU_USE")) % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mats[mat]), true), tr("S_SECOND")])
	game.show_tooltip(st)

func show_atom(atom:String):
	var st:String = get_str(atom, "_NAME")
	if game.autocollect.atoms.has(atom) and not is_zero_approx(game.autocollect.atoms[atom]):
		st += "\n" + (tr("YOU_PRODUCE") if game.autocollect.atoms[atom] > 0 else tr("YOU_USE")) % ("%s mol/%s" % [Helper.format_num(abs(game.autocollect.atoms[atom]), true), tr("S_SECOND")])
	game.show_tooltip(st)

func on_mouse_out():
	game.hide_tooltip()

func show_met(met:String):
	var st:String = "%s\n%s" % [get_str(met), get_str(met, "_DESC")]
	if game.autocollect.mets.has(met) and not is_zero_approx(game.autocollect.mets[met]):
		st += "\n" + (tr("YOU_PRODUCE") if game.autocollect.mets[met] > 0 else tr("YOU_USE")) % ("%s/%s" % [Helper.format_num(abs(game.autocollect.mets[met]), true), tr("S_SECOND")])
	game.show_tooltip(st)

func get_str(obj:String, desc:String = ""):
	return tr(obj.to_upper() + desc)

func _input(event):
	super(event)
	if item_hovered != "":
		if Input.is_action_just_released("shift X"):
			game.items[item_slot] = null
			_on_Items_pressed()
			item_hovered = ""
			game.hide_tooltip()
		elif Input.is_action_just_released("X"):
			game.remove_items(item_hovered)
			_on_Items_pressed()
			if game.items[item_slot] == null:
				item_hovered = ""
				game.hide_tooltip()
		if Input.is_action_just_released("H"):
			if game.hotbar.find(item_hovered) == -1:
				game.hotbar.append(item_hovered)
			else:
				game.hotbar.erase(item_hovered)
			game.HUD.update_hotbar()


func _on_close_button_pressed():
	game.toggle_panel(self)

func _process(delta):
	if not visible:
		set_process(false)
	if tab == "materials":
		for hbox in hbox_data:
			hbox.rsrc.get_node("Text").text = "%s kg" % [Helper.format_num(game.mats[hbox.name], true)]
	elif tab == "metals":
		for hbox in hbox_data:
			hbox.rsrc.get_node("Text").text = "%s kg" % [Helper.format_num(game.mets[hbox.name], true)]
	elif tab == "atoms":
		for hbox in hbox_data:
			hbox.rsrc.get_node("Text").text = "%s mol" % [Helper.format_num(game.atoms[hbox.name], true)]
	elif tab == "particles":
		var neutron_cap = game.neutron_cap * Helper.get_IR_mult("NSF")
		var electron_cap = game.electron_cap * Helper.get_IR_mult("ESF")
		$Control/ParticlesHBox/Protons.text = "%s mol" % Helper.format_num(game.particles.proton, true)
		if game.particles.neutron >= neutron_cap:
			$Control/ParticlesHBox/Neutrons["theme_override_colors/font_color"] = Color.ORANGE
		else:
			$Control/ParticlesHBox/Neutrons["theme_override_colors/font_color"] = Color.WHITE
		$Control/ParticlesHBox/Neutrons.text = "%s / %s mol" % [Helper.format_num(game.particles.neutron, true), Helper.format_num(neutron_cap, true)]
		if game.particles.electron >= electron_cap:
			$Control/ParticlesHBox/Electrons["theme_override_colors/font_color"] = Color.RED
		else:
			$Control/ParticlesHBox/Electrons["theme_override_colors/font_color"] = Color.WHITE
		$Control/ParticlesHBox/Electrons.text = "%s / %s mol" % [Helper.format_num(game.particles.electron, true), Helper.format_num(electron_cap, true)]
