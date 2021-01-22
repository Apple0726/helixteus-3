extends Control

onready var click_sound = get_node("../click")
onready var game = get_parent()
onready var money_text = $Resources/Money/Text
onready var minerals_text = $Resources/Minerals/Text
onready var stone_text = $Resources/Stone/Text
onready var soil_text = $Resources/Soil/Text
onready var energy_text = $Resources/Energy/Text
onready var SP_text = $Resources/SP/Text
onready var minerals = $Resources/Minerals
onready var stone = $Resources/Stone
onready var SP = $Resources/SP
onready var ships = $Buttons/Ships
onready var craft = $Buttons/Craft
onready var MU = $Buttons/MineralUpgrades
onready var sc_tree = $Buttons/ScienceTree
onready var lv_txt = $Lv/Label
onready var lv_progress = $Lv/TextureProgress
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var on_button = false
var config = ConfigFile.new()

func _on_Button_pressed():
	click_sound.play()
	game.toggle_panel(game.settings)

func _ready():
	refresh()

func _process(delta):
	$AutosaveLight.modulate.g = lerp(0.3, 1, game.get_node("Autosave").time_left / game.autosave_interval)

func refresh():
	if not game:
		return
	if config.load("user://settings.cfg") == OK:
		var autosave_light = config.get_value("saving", "autosave_light", false)
		if config.get_value("saving", "enable_autosave", true):
			set_process(autosave_light)
		else:
			$AutosaveLight.modulate.g = 0.3
			set_process(false)
		$AutosaveLight.visible = autosave_light
	money_text.text = Helper.format_num(game.money, 6)
	minerals_text.text = "%s / %s" % [Helper.format_num(game.minerals, 6), Helper.format_num(round(game.mineral_capacity), 6)]
	var total_stone:float = round(Helper.get_sum_of_dict(game.stone))
	stone_text.text = Helper.format_num(total_stone, 6) + " kg"
	soil_text.text = String(game.mats.soil) + " kg"
	energy_text.text = Helper.format_num(game.energy, 6)
	SP_text.text = Helper.format_num(game.SP, 6)
	minerals.visible = game.show.minerals
	stone.visible = game.show.stone
	SP.visible = game.show.SP
	sc_tree.visible = game.show.SP
	craft.visible = game.show.materials
	ships.visible = len(game.ship_data) > 0
	MU.visible = game.show.minerals
	$ConvertMinerals.visible = game.show.minerals
	$ShipLocator.visible = len(game.ship_data) == 1 and game.second_ship_hints.ship_locator
	if game.xp >= game.xp_to_lv:
		game.lv += 1
		game.xp -= game.xp_to_lv
		game.xp_to_lv = round(game.xp_to_lv * 1.5)
	lv_txt.text = tr("LV") + " %s" % [game.lv]
	lv_progress.value = game.xp / float(game.xp_to_lv)
	if OS.get_latin_keyboard_variant() == "QWERTZ":
		$Buttons/Ships.shortcut.shortcut.action = "Z"
	else:
		$Buttons/Ships.shortcut.shortcut.action = "Y"
	update_hotbar()

func _on_Shop_pressed():
	click_sound.play()
	game.toggle_panel(game.shop_panel)

func _on_Shop_mouse_entered():
	on_button = true
	game.show_tooltip(tr("SHOP") + " (R)")

func _on_Inventory_mouse_entered():
	on_button = true
	game.show_tooltip(tr("INVENTORY") + " (E)")

func _on_Inventory_pressed():
	click_sound.play()
	game.toggle_panel(game.inventory)

func _on_Craft_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CRAFT") + " (T)")

func _on_Craft_pressed():
	click_sound.play()
	game.toggle_panel(game.craft_panel)

func _on_ScienceTree_pressed():
	click_sound.play()
	if game.c_v != "science_tree":
		game.switch_view("science_tree")

func _on_ScienceTree_mouse_entered():
	game.show_tooltip(tr("SCIENCE_TREE") + " (I)")

func _on_MineralUpgrades_pressed():
	game.toggle_panel(game.MU_panel)

func _on_MineralUpgrades_mouse_entered():
	game.show_tooltip(tr("MINERAL_UPGRADES") + " (U)")

func _on_Texture_mouse_entered(extra_arg_0):
	game.show_tooltip(tr(extra_arg_0))

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()

func update_hotbar():
	for child in $Hotbar.get_children():
		$Hotbar.remove_child(child)
	var i:int = 0
	for item in game.hotbar:
		var slot = slot_scene.instance()
		var num = game.get_item_num(item)
		slot.get_node("Label").text = String(num)
		slot.get_node("TextureRect").texture = load("res://Graphics/" + Helper.get_dir_from_name(item)  + "/" + item + ".png")
		slot.get_node("Button").connect("mouse_entered", self, "on_slot_over", [i])
		slot.get_node("Button").connect("mouse_exited", self, "on_slot_out")
		if num > 0:
			slot.get_node("Button").connect("pressed", self, "on_slot_press", [i])
		$Hotbar.add_child(slot)
		i += 1

var slot_over = -1
func on_slot_over(i:int):
	slot_over = i
	on_button = true
	game.help_str = "hotbar_shortcuts"
	var txt = ("\n" + tr("H_FOR_HOTBAR_REMOVE") + "\n" + tr("HIDE_SHORTCUTS")) if game.help.hotbar_shortcuts else ""
	var num = " (%s)" % [i + 1] if i < 5 else ""
	game.show_tooltip(Helper.get_item_name(game.hotbar[i]) + num + txt)

func on_slot_out():
	slot_over = -1
	on_button = false
	game.hide_tooltip()

func on_slot_press(i:int):
	var name = game.hotbar[i]
	game.inventory.on_slot_press(name)

func _on_Label_mouse_entered():
	on_button = true
	game.show_tooltip((tr("LEVEL") + " %s\nXP: %s / %s") % [game.lv, Helper.format_num(game.xp, 4), Helper.format_num(game.xp_to_lv, 4)])


func _on_Label_mouse_exited():
	on_button = false
	game.hide_tooltip()

func _input(_event):
	if Input.is_action_just_released("H") and slot_over != -1:
		game.hotbar.remove(slot_over)
		game.hide_tooltip()
		slot_over = -1
		update_hotbar()
		refresh()

func _on_CollectAll_mouse_entered():
	on_button = true
	game.show_tooltip(tr("COLLECT_ALL_PLANET") + " (Shift V)")

func _on_CollectAll_pressed():
	game.view.obj.collect_all()

func _on_ConvertMinerals_mouse_entered():
	on_button = true
	game.show_tooltip(tr("SELL_MINERALS") + " (Shift C)")

func _on_ConvertMinerals_pressed():
	game.sell_all_minerals()

func _on_Ships_pressed():
	game.toggle_panel(game.ship_panel)

func _on_Ships_mouse_entered():
	on_button = true
	game.show_tooltip("%s (%s)" % [tr("SHIPS"), $Buttons/Ships.shortcut.shortcut.action])


func _on_AutosaveLight_mouse_entered():
	if game.help.autosave_light_desc:
		game.help_str = "autosave_light_desc"
		game.show_tooltip("%s\n%s" % [tr("AUTOSAVE_LIGHT_DESC"), tr("HIDE_HELP")])

func _on_AutosaveLight_mouse_exited():
	game.hide_tooltip()


func _on_ShipLocator_pressed():
	if game.c_v == "galaxy":
		game.put_bottom_info(tr("LOCATE_SHIP_HELP"), "locating_ship", "hide_ship_locator")
		game.show_ship_locator()


func _on_ShipLocator_mouse_entered():
	if game.c_v == "galaxy":
		game.show_tooltip(tr("LOCATE_SHIP"))
	else:
		game.show_tooltip(tr("SHIP_LOCATOR_ERROR"))
