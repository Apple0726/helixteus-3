extends Control

@onready var game = get_node("/root/Game")
@onready var hbox = $ScrollContainer2/HBox
var g_cmp:String#armor, wheels, CC (g: general)
var s_cmp:String#lead_armor, copper_wheels etc. (s: specific)
var curr_cmp:String
var is_inventory
var index:int = -1
@onready var option_btn = $OptionButton

func _ready():
	$Select.text = tr("SELECT") + " (S)"
	option_btn.add_item(tr("WEAPONS"))
	option_btn.add_item(tr("MINING_TOOLS"))
	option_btn.selected = 0

func refresh(type:String, _curr_cmp:String, _is_inventory:bool = false, _index:int = -1):
	is_inventory = _is_inventory
	index = _index
	$Label.visible = not is_inventory
	option_btn.visible = is_inventory
	if not is_inventory:
		$Label.text = tr("SELECT_X").format({"select":tr("SELECT"), "something":tr(type.split("_")[1].to_upper())})
	for node in hbox.get_children():
		node.queue_free()
	var dir:String = ""
	if type == "":
		type = "rover_weapons"
	if type == "rover_armor":
		dir = "Armor"
		$Desc.text = tr("ARMOR_DESC")
	elif type == "rover_wheels":
		dir = "Wheels"
		$Desc.text = tr("WHEELS_DESC")
	elif type == "rover_CC":
		dir = "CargoContainer"
		$Desc.text = tr("CC_DESC")
	elif type == "rover_weapons":
		dir = "Weapons"
		$Desc.text = tr("LASER_WEAPON_DESC")
		$OptionButton.selected = 0
	elif type == "rover_mining":
		dir = "Mining"
		$Desc.text = tr("MINING_LASER_DESC")
		$OptionButton.selected = 1
	g_cmp = type.split("_")[1]
	curr_cmp = _curr_cmp
	s_cmp = curr_cmp
	Helper.put_rsrc($ScrollContainer/Cost, 36, {})
	for cmp in Data[type]:
		var metal = cmp.split("_")[0].to_upper()
		if type in ["rover_weapons", "rover_mining"]:
			var laser_color = cmp.split("_")[0]
			if laser_color == "orange" and not game.science_unlocked.has("OL"):
				continue
			if laser_color == "yellow" and not game.science_unlocked.has("YL"):
				continue
			if laser_color == "green" and not game.science_unlocked.has("GL"):
				continue
			if laser_color == "blue" and not game.science_unlocked.has("BL"):
				continue
			if laser_color == "purple" and not game.science_unlocked.has("PL"):
				continue
			if laser_color == "UV" and not game.science_unlocked.has("UVL"):
				continue
			if laser_color == "xray" and not game.science_unlocked.has("XRL"):
				continue
			if laser_color == "gammaray" and not game.science_unlocked.has("GRL"):
				continue
			if laser_color == "ultragammaray" and not game.science_unlocked.has("UGRL"):
				continue
		else:
			var l_metal = metal.to_lower()
			if l_metal != "stone" and not l_metal == "gemstone" and not game.show.has(l_metal):
				continue
			if l_metal == "gemstone":
				if not game.show.has("amethyst") and not game.show.has("emerald") and not game.show.has("quartz") and not game.show.has("ruby") and not game.show.has("sapphire") and not game.show.has("topaz"):
					continue
		var slot = preload("res://Scenes/InventorySlot.tscn").instantiate()
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/%s/%s.png" % [dir, cmp])
		slot.get_node("Button").connect("mouse_entered",Callable(self,"_on_Slot_mouse_entered").bind(type, cmp, metal))
		slot.get_node("Button").connect("mouse_exited",Callable(self,"_on_Slot_mouse_exited"))
		slot.get_node("Button").connect("pressed",Callable(self,"_on_Slot_pressed").bind(type, cmp, slot))
		hbox.add_child(slot)
		if cmp == curr_cmp:
			_on_Slot_pressed(type, cmp, slot)
			$Select.visible = true
			$ScrollContainer.visible = true

func _on_Slot_mouse_entered(type:String, cmp:String, metal:String):
	var txt
	var metal_comp:String = tr("METAL_COMP").format({"metal":tr(metal), "comp":tr(g_cmp.to_upper())})
	if type == "rover_armor":
		txt = "%s\n+%s %s\n+%s %s" % [metal_comp, Data.rover_armor[cmp].HP, tr("HEALTH_POINTS"), Data.rover_armor[cmp].defense, tr("DEFENSE")]
	elif type == "rover_wheels":
		txt = "%s\n+%s %s" % [metal_comp, Data.rover_wheels[cmp].speed, tr("MOVEMENT_SPEED")]
	elif type == "rover_CC":
		txt = "%s\n+%s kg %s" % [metal_comp, round(Data.rover_CC[cmp].capacity * game.u_i.planck), tr("CARGO_CAPACITY")]
	elif type == "rover_weapons":
		txt = Helper.get_rover_weapon_text(cmp)
	elif type == "rover_mining":
		txt = Helper.get_rover_mining_text(cmp)
	game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	game.hide_tooltip()

func _on_Slot_pressed(type:String, cmp:String, _slot):
	for slot in hbox.get_children():
		if slot == _slot and not slot.has_node("border"):
			var border = TextureRect.new()
			border.texture = preload("res://Graphics/Cave/SlotBorder.png")
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(border)
			border.name = "border"
		elif slot.has_node("border"):
			slot.remove_child(slot.get_node("border"))
	Helper.put_rsrc($ScrollContainer/Cost, 36, Data[type][cmp].costs, true, true)
	s_cmp = cmp
	$Select.visible = true
	$ScrollContainer.visible = true

func _input(event):
	if Input.is_action_just_released("S") and visible:
		game.hide_tooltip()
		set_cmp()

func set_cmp():
	if s_cmp != "":
		if is_inventory:
			if get_parent().right_inv:
				get_parent().right_inventory[0].type = "rover_" + g_cmp
				get_parent().right_inventory[0].id = s_cmp
			else:
				get_parent().inventory[index].type = "rover_" + g_cmp
				get_parent().inventory[index].id = s_cmp
			get_parent()["rover_" + g_cmp] = true
		else:
			get_parent()[g_cmp] = s_cmp
	get_parent().refresh()
	_on_close_button_pressed()

func _on_Select_pressed():
	set_cmp()


func _on_OptionButton_item_selected(_index):
	$Select.visible = false
	$ScrollContainer.visible = false
	if _index == 0:
		refresh("rover_weapons", curr_cmp, true, index)
	elif _index == 1:
		refresh("rover_mining", curr_cmp, true, index)


func _on_close_button_pressed():
	visible = false
	game.sub_panel = null
