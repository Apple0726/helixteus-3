extends Control

signal construct_building_signal
onready var game:Node2D = get_node("/root/Game")

var mouse_in_panel = true
var tab = "Resources"

func _input(event):
	if event is InputEventMouseButton:
		#If panel is right clicked, remove panel
		if mouse_in_panel and event.is_action_released("right_click"):
			remove_panel()
		
func remove_panel():
	#Only remove if the panel is actually there
	if get_node("../construct_panel") != null:
		self.get_parent().remove_construct_panel()

#Check whether mouse is in the panel for right clicking
func _on_Background_mouse_entered():
	mouse_in_panel = true

func _on_Background_mouse_exited():
	mouse_in_panel = false

#Clicking the various tabs
func _on_ResourcesButton_button_pressed():
	toggle_buildings(false)
	tab = "Resources"
	reset_lights()
	toggle_buildings(true)

func _on_ProductionButton_button_pressed():
	toggle_buildings(false)
	tab = "Production"
	reset_lights()
	toggle_buildings(true)

func _on_StorageButton_button_pressed():
	toggle_buildings(false)
	tab = "Storage"
	reset_lights()
	toggle_buildings(true)

#Make buildings in current tab (in)visible
func toggle_buildings(vis:bool):
	for bldg in get_node(tab + "Buildings").get_children():
		bldg.visible = vis

#The light thing under each tab to highlight which tab you're on
func reset_lights():
	for light in $Lights.get_children():
		light.visible = false
	$Lights.get_node(tab + "Light").visible = true
	toggle_icons(false)
	$BuildingInformation/Name.text = ""
	$BuildingInformation/Description.text = ""
	$BuildingInformation/MoneyText.text = ""
	$BuildingInformation/EnergyText.text = ""
	$BuildingInformation/TimeText.text = ""

func update_cost_info(bldg:String):
	var game = self.get_parent()
	var bldg_info = game.bldg_info[bldg]
	$BuildingInformation/Name.text = bldg_info["name"]
	$BuildingInformation/Description.text = bldg_info["desc"]
	$BuildingInformation/MoneyText.text = String(bldg_info["money"])
	$BuildingInformation/EnergyText.text = String(bldg_info["energy"])
	$BuildingInformation/TimeText.text = String(bldg_info["time"])
	game.constr_cost["money"] = bldg_info["money"]
	game.constr_cost["energy"] = bldg_info["energy"]
	game.constr_cost["time"] = bldg_info["time"]

#Make money/energy/etc. icons (in)visible
func toggle_icons(vis:bool):
	$BuildingInformation/Energy.visible = vis
	$BuildingInformation/Time.visible = vis
	$BuildingInformation/Money.visible = vis

func _on_MEButton_button_pressed():
	update_cost_info("ME")
	check_signal()
	connect("construct_building_signal", self.get_parent(), "construct_building", ["ME"])
	toggle_icons(true)

func _on_MEButton_double_click():
	$ResourcesBuildings/MineralExtractor/MEButton.reset_button()
	remove_panel()
	emit_signal("construct_building_signal")

func _on_PPButton_button_pressed():
	update_cost_info("PP")
	check_signal()
	connect("construct_building_signal", self.get_parent(), "construct_building", ["PP"])
	toggle_icons(true)

func check_signal():
	if is_connected("construct_building_signal", self.get_parent(), "construct_building"):
		disconnect("construct_building_signal", self.get_parent(), "construct_building")

func _on_PPButton_double_click():
	if game.has_node("construct_panel"):
		$ResourcesBuildings/PowerPlant/PPButton.reset_button()
		remove_panel()
		emit_signal("construct_building_signal")
