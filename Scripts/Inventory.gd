extends "Panel.gd"

var tab:String
var buy_sell_scene = preload("res://Scenes/Panels/BuySellPanel.tscn")
var buy_sell
@onready var inventory_grid = $Control/VBox/Inventory
@onready var grid = $Control/VBox/GridContainer
@onready var particles_hbox = $Control/ParticlesHBox
@onready var info = $Information
var item_hovered:int = -1
var hbox_data:Array = []
var send_to_rover:int = -1 # Used when the player sends items to rover and the inventory panel opens

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
		item.queue_free()
	for i in len(game.items):
		var slot = preload("res://Scenes/InventorySlot.tscn").instantiate()
		var item_slot = game.items[i]
		if item_slot != null:
			slot.get_node("Label").text = str(item_slot.num)
			slot.get_node("TextureRect").texture = load("res://Graphics/Items/%s/%s.png" % [Item.icon_directory(Item.data[item_slot.id].type), Item.data[item_slot.id].icon_name])
			slot.get_node("Button").mouse_entered.connect(on_slot_over.bind(i))
			slot.get_node("Button").mouse_exited.connect(on_slot_out)
			slot.get_node("Button").pressed.connect(on_slot_pressed)
		inventory_grid.add_child(slot)
	$Control/VBox/BuySell.visible = false

func on_slot_over(item_slot:int):
	item_hovered = item_slot
	var item_id:int = game.items[item_hovered].id
	var tooltip_txt = Item.name(item_id) + "\n" + Item.description(item_id)
	tooltip_txt += "\n%s\n%s\n" % [tr("CLICK_TO_USE"), tr("RIGHT_CLICK_FOR_MORE_OPTIONS")]
	game.show_tooltip(tooltip_txt)

func on_slot_out():
	item_hovered = -1
	game.hide_tooltip()

func on_slot_pressed():
	var item_id:int = game.items[item_hovered].id
	game.use_item(item_id, send_to_rover)

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
		if Settings.auto_switch_buy_sell:
			buy_sell.is_selling = game.money < amount * value * game.maths_bonus.MMBSVR * 5.0
		else:
			buy_sell.is_selling = true
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
	if item_hovered != -1:
		var item_id:int = game.items[item_hovered].id
		if Input.is_action_just_released("shift X"):
			game.items[item_hovered] = null
			_on_Items_pressed()
			item_hovered = -1
			game.hide_tooltip()
		elif Input.is_action_just_released("X"):
			game.remove_items(item_id)
			_on_Items_pressed()
			if game.items[item_hovered] == null:
				item_hovered = -1
				game.hide_tooltip()
		if Input.is_action_just_released("H"):
			if game.hotbar.find(item_id) == -1:
				game.hotbar.append(item_id)
			else:
				game.hotbar.erase(item_id)
			game.HUD.update_hotbar()

@onready var subatomic_particles_label = $Control/ParticlesHBox/SubatomicParticles

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
		subatomic_particles_label.text = "%s mol" % [Helper.format_num(game.particles.subatomic_particles, true)]


func show_part(_name:String):
	var st:String = "%s\n%s" % [tr(_name.to_upper()), tr(_name.to_upper() + "_DESC")]
	game.show_tooltip(st)
