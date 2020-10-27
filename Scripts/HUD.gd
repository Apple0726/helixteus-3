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
onready var craft = $Buttons/Craft
onready var MU = $Buttons/MineralUpgrades
onready var sc_tree = $Buttons/ScienceTree
onready var lv_txt = $Lv/Label
onready var lv_progress = $Lv/TextureProgress
var slot_scene = preload("res://Scenes/InventorySlot.tscn")
var on_button = false

func _on_Button_pressed():
	click_sound.play()
	game.toggle_panel(game.settings)
#	if AudioServer.is_bus_mute(1) == false:
#		AudioServer.set_bus_mute(1,true)
#	else:
#		AudioServer.set_bus_mute(1,false)
#	var config = ConfigFile.new()
#	var err = config.load("user://settings.cfg")
#	if err == OK:
#		config.set_value("audio", "mute", not config.get_value("audio", "mute"))
#	config.save("user://settings.cfg")

func _ready():
	refresh()

func refresh():
	if not game:
		return
	money_text.text = String(game.money)
	minerals_text.text = String(game.minerals) + " / " + String(game.mineral_capacity)
	var total_stone:float = Helper.get_sum_of_dict(game.stone)
	stone_text.text = String(total_stone) + " kg"
	soil_text.text = String(game.mats.soil) + " kg"
	energy_text.text = String(game.energy)
	SP_text.text = String(game.SP)
	minerals.visible = game.show.minerals
	stone.visible = game.show.stone
	SP.visible = game.show.SP
	sc_tree.visible = game.show.SP
	craft.visible = game.show.materials
	MU.visible = game.show.minerals
	if game.xp >= game.xp_to_lv:
		game.lv += 1
		game.xp -= game.xp_to_lv
		game.xp_to_lv = round(game.xp_to_lv * 1.5)
	lv_txt.text = tr("LV") + " %s" % [game.lv]
	lv_progress.value = game.xp / float(game.xp_to_lv)

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
	game.inventory.on_slot_press(name, Helper.get_type_from_name(name), Helper.get_dir_from_name(name))

func _on_Label_mouse_entered():
	on_button = true
	game.show_tooltip((tr("LEVEL") + " %s\nXP: %s / %s") % [game.lv, game.xp, game.xp_to_lv])


func _on_Label_mouse_exited():
	on_button = false
	game.hide_tooltip()

func _input(_event):
	if Input.is_action_just_released("hotbar") and slot_over != -1:
		game.hotbar.remove(slot_over)
		game.hide_tooltip()
		slot_over = -1
		update_hotbar()
