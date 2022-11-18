extends Control
class_name ResourceStored

func set_current_bar_value(value):
	$VBox/Panel2/CurrentBar.value = value

func set_current_bar_visibility(value):
	$VBox/Panel2.visible = value

func set_capacity_bar_value(value):
	$VBox/Panel3/CapacityBar.value = value

func set_text(text):
	$VBox/Panel3/Label.text = text

func set_icon_texture(texture):
	$Panel/Icon.texture = texture

func set_modulate(mod):
	$VBox.modulate = mod
	$Panel.self_modulate = mod
