extends Control

@onready var game = get_node("/root/Game")
@onready var hbox = $ScrollContainer2/HBox
var component_type:int
var component_name:int
var is_inventory
var index:int = -1
@onready var option_btn = $VBoxContainer/OptionButton
@onready var desc_txt = $VBoxContainer/Desc

func _ready():
	$Select.text = tr("SELECT") + " (S)"
	option_btn.add_item(tr("WEAPONS"))
	option_btn.add_item(tr("MINING_TOOLS"))
	option_btn.selected = 0

func refresh(type:int, _curr_cmp:int, _is_inventory:bool = false, _index:int = -1):
	is_inventory = _is_inventory
	index = _index
	option_btn.visible = is_inventory
	for node in hbox.get_children():
		node.queue_free()
	var dir:String = ""
	if type == -1:
		type = Item.Type.ROVER_WEAPON
	if type == Item.Type.ROVER_ARMOR:
		dir = "Armor"
		desc_txt.text = tr("ARMOR_DESC")
	elif type == Item.Type.ROVER_WHEELS:
		dir = "Wheels"
		desc_txt.text = tr("WHEELS_DESC")
	elif type == Item.Type.ROVER_CC:
		dir = "CargoContainer"
		desc_txt.text = tr("CC_DESC")
	elif type == Item.Type.ROVER_WEAPON:
		dir = "Weapons"
		desc_txt.text = tr("LASER_WEAPON_DESC")
		option_btn.selected = 0
	elif type == Item.Type.ROVER_MINING:
		dir = "Mining"
		desc_txt.text = tr("MINING_LASER_DESC")
		option_btn.selected = 1
	component_type = type
	component_name = _curr_cmp
	Helper.put_rsrc($ScrollContainer/Cost, 36, {})
	for cmp in Item.data:
		if Item.data[cmp].type != type:
			continue
		if type in [Item.Type.ROVER_WEAPON, Item.Type.ROVER_MINING]:
			if cmp in [Item.ORANGE_LASER, Item.ORANGE_MINING_LASER] and not game.science_unlocked.has("OL"):
				continue
			if cmp in [Item.YELLOW_LASER, Item.YELLOW_MINING_LASER] and not game.science_unlocked.has("YL"):
				continue
			if cmp in [Item.GREEN_LASER, Item.GREEN_MINING_LASER] and not game.science_unlocked.has("GL"):
				continue
			if cmp in [Item.BLUE_LASER, Item.BLUE_MINING_LASER] and not game.science_unlocked.has("BL"):
				continue
			if cmp in [Item.PURPLE_LASER, Item.PURPLE_MINING_LASER] and not game.science_unlocked.has("PL"):
				continue
			if cmp in [Item.UV_LASER, Item.UV_MINING_LASER] and not game.science_unlocked.has("UVL"):
				continue
			if cmp in [Item.XRAY_LASER, Item.XRAY_MINING_LASER] and not game.science_unlocked.has("XRL"):
				continue
			if cmp in [Item.GAMMARAY_LASER, Item.GAMMARAY_MINING_LASER] and not game.science_unlocked.has("GRL"):
				continue
			if cmp in [Item.ULTRAGAMMARAY_LASER, Item.ULTRAGAMMARAY_MINING_LASER] and not game.science_unlocked.has("UGRL"):
				continue
		else:
			var metal:String = Item.data[cmp].metal
			if metal != "stone" and not game.show.has(metal):
				continue
		var slot = preload("res://Scenes/InventorySlot.tscn").instantiate()
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/%s/%s.png" % [dir, Item.data[cmp].item_name])
		slot.get_node("Button").mouse_entered.connect(_on_Slot_mouse_entered.bind(type, cmp))
		slot.get_node("Button").mouse_exited.connect(_on_Slot_mouse_exited)
		slot.get_node("Button").pressed.connect(_on_Slot_pressed.bind(type, cmp, slot))
		hbox.add_child(slot)
		if cmp == component_name:
			_on_Slot_pressed(type, cmp, slot)
			$Select.visible = true
			$ScrollContainer.visible = true

func _on_Slot_mouse_entered(type:int, cmp:int):
	var txt:String
	if type == Item.Type.ROVER_ARMOR:
		txt = "{armor_name}\n+{HP_bonus} {HP_bonus_text}\n+{defense_bonus} {defense_bonus_text}".format({
			"armor_name":tr("METAL_COMP").format({"metal":tr(Item.data[cmp].metal.to_upper()), "comp":tr("ARMOR")}),
			"HP_bonus":Item.data[cmp].HP,
			"HP_bonus_text": tr("HEALTH_POINTS"),
			"defense_bonus":Item.data[cmp].defense,
			"defense_bonus_text": tr("DEFENSE"),
		})
	elif type == Item.Type.ROVER_WHEELS:
		txt = "{wheels_name}\n+{speed_bonus} {speed_bonus_text}".format({
			"wheels_name":tr("METAL_COMP").format({"metal":tr(Item.data[cmp].metal.to_upper()), "comp":tr("WHEELS")}),
			"speed_bonus":Item.data[cmp].speed,
			"speed_bonus_text": tr("MOVEMENT_SPEED"),
		})
	elif type == Item.Type.ROVER_CC:
		txt = "{CC_name}\n+{capacity_bonus} kg {capacity_bonus_text}".format({
			"CC_name":tr("METAL_COMP").format({"metal":tr(Item.data[cmp].metal.to_upper()), "comp":tr("CC")}),
			"capacity_bonus":round(Item.data[cmp].capacity * game.u_i.planck),
			"capacity_bonus_text": tr("CARGO_CAPACITY"),
		})
	elif type == Item.Type.ROVER_WEAPON:
		txt = Helper.get_rover_weapon_text(cmp)
	elif type == Item.Type.ROVER_MINING:
		txt = Helper.get_rover_mining_text(cmp)
	game.show_tooltip(txt)

func _on_Slot_mouse_exited():
	game.hide_tooltip()

func _on_Slot_pressed(type:int, cmp:int, _slot):
	for slot in hbox.get_children():
		if slot == _slot and not slot.has_node("border"):
			var border = TextureRect.new()
			border.texture = preload("res://Graphics/Cave/SlotBorder.png")
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(border)
			border.name = "border"
		elif slot.has_node("border"):
			slot.remove_child(slot.get_node("border"))
	Helper.put_rsrc($ScrollContainer/Cost, 36, Item.data[cmp].costs, true, true)
	component_name = cmp
	$Select.visible = true
	$ScrollContainer.visible = true

func _input(event):
	if Input.is_action_just_released("S") and visible:
		game.hide_tooltip()
		set_cmp()

func set_cmp():
	if component_name != -1:
		if is_inventory:
			if get_parent().right_inv:
				if component_type == Item.Type.ROVER_MINING:
					get_parent().right_inventory[0].type = Item.Type.ROVER_MINING
				elif component_type == Item.Type.ROVER_WEAPON:
					get_parent().right_inventory[0].type = Item.Type.ROVER_WEAPON
				get_parent().right_inventory[0].id = component_name
			else:
				get_parent().inventory[index].type = component_type
				get_parent().inventory[index].id = component_name
			if component_type == Item.Type.ROVER_MINING:
				get_parent().rover_mining = true
			elif component_type == Item.Type.ROVER_WEAPON:
				get_parent().rover_weapons = true
		else:
			if component_type == Item.Type.ROVER_ARMOR:
				get_parent().armor = component_name
			elif component_type == Item.Type.ROVER_CC:
				get_parent().CC = component_name
			elif component_type == Item.Type.ROVER_WHEELS:
				get_parent().wheels = component_name
	get_parent().refresh()
	_on_close_button_pressed()

func _on_Select_pressed():
	set_cmp()


func _on_OptionButton_item_selected(_index):
	$Select.visible = false
	$ScrollContainer.visible = false
	if _index == 0:
		refresh(Item.Type.ROVER_WEAPON, component_name, true, index)
	elif _index == 1:
		refresh(Item.Type.ROVER_MINING, component_name, true, index)


func _on_close_button_pressed():
	visible = false
	game.sub_panel = null
