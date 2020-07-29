extends Control
signal panel_ready

var mouse_in_panel = true
var tab = "Resources"

func _input(event):
	#If panel is right clicked, remove panel
	if mouse_in_panel and event is InputEventMouseButton and event.is_action_released("right_click"):
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

func _on_MEButton_button_pressed():
	$BuildingInformation/Name.text = "Mineral extractor"
	$BuildingInformation/Description.text = "Extracts minerals from the planet surface, giving you a constant supply of minerals."
	$BuildingInformation/MoneyText.text = "100"
	$BuildingInformation/EnergyText.text = "50"
	$BuildingInformation/TimeText.text = "0:20"
	toggle_icons(true)

#Make money/energy/etc. icons (in)visible
func toggle_icons(vis:bool):
	$BuildingInformation/Energy.visible = vis
	$BuildingInformation/Time.visible = vis
	$BuildingInformation/Money.visible = vis
