extends Control
signal panel_ready

var mouse_in_panel = true
var tab = "Resources"

func _input(event):
	if mouse_in_panel and event is InputEventMouseButton and event.is_action_released("right_click"):
		remove_panel()
		
func remove_panel():
	if get_node("../construct_panel") != null:
		print("remove")
		self.get_parent().remove_construct_panel()

func _on_Background_mouse_entered():
	mouse_in_panel = true


func _on_Background_mouse_exited():
	mouse_in_panel = false


func _on_ResourcesButton_button_pressed():
	tab = "Resources"
	reset_lights()


func _on_ProductionButton_button_pressed():
	tab = "Production"
	reset_lights()

func reset_lights():
	for light in $Lights.get_children():
		light.visible = false
	$Lights.get_node(tab + "Light").visible = true
