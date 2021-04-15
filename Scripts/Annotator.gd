extends Panel

onready var game = get_node("/root/Game")
var mode:String = ""
var shape_color:Color = Color.white
var thickness:int = 10
onready var color_picker = $ColorPicker
var changing_thickness = false
var mouse_in_panel:bool = false

func _ready():
	for node in $HBoxContainer.get_children():
		node.get_node("Button").toggle_mode = true
		node.get_node("Button").connect("pressed", self, "on_%s_pressed" % node.name)
	$HBoxContainer/Line/TextureRect.texture = load("res://Graphics/Icons/Annotator/line.png")
	$HBoxContainer/Rectangle/TextureRect.texture = load("res://Graphics/Icons/Annotator/rectangle.png")
	$HBoxContainer/Circle/TextureRect.texture = load("res://Graphics/Icons/Annotator/circle.png")
	$HBoxContainer/Eraser/TextureRect.texture = load("res://Graphics/Icons/Annotator/eraser.png")
	$HBoxContainer/Icons/TextureRect.texture = load("res://Graphics/Icons/Annotator/check.png")
	$VBoxContainer/Check/TextureRect.texture = load("res://Graphics/Icons/Annotator/check.png")
	$VBoxContainer/Cross/TextureRect.texture = load("res://Graphics/Icons/Annotator/cross.png")
	$VBoxContainer/Money/TextureRect.texture = load("res://Graphics/Icons/money.png")
	$VBoxContainer/Minerals/TextureRect.texture = load("res://Graphics/Icons/minerals.png")
	$VBoxContainer/Energy/TextureRect.texture = load("res://Graphics/Icons/energy.png")
	$VBoxContainer/SP/TextureRect.texture = load("res://Graphics/Icons/SP.png")
	$VBoxContainer/Plant/TextureRect.texture = load("res://Graphics/Science/SA.png")
	$VBoxContainer/Cave/TextureRect.texture = load("res://Graphics/Tiles/cave.png")
	$VBoxContainer/Stone/TextureRect.texture = load("res://Graphics/Icons/stone.png")
	$VBoxContainer/Arrow/TextureRect.texture = load("res://Graphics/Icons/Arrow.png")
	for node in $VBoxContainer.get_children():
		node.get_node("Button").connect("pressed", self, "on_icon_pressed", [node.get_node("TextureRect").texture])

func _input(event):
	if event is InputEventMouseMotion:
		mouse_in_panel = Geometry.is_point_in_polygon(event.position - Vector2(256, 656), $Polygon2D.polygon)
		if $VBoxContainer.visible:
			mouse_in_panel = mouse_in_panel or Geometry.is_point_in_polygon(event.position - Vector2(256, 656), $Polygon2D2.polygon)
		if $ColorPicker.visible:
			mouse_in_panel = mouse_in_panel or Geometry.is_point_in_polygon(event.position - Vector2(256, 656), $Polygon2D3.polygon)

func on_icon_pressed(_texture):
	$HBoxContainer/Icons/TextureRect.texture = _texture
	game.view.annotate_icon.texture = _texture
	
func on_Line_pressed():
	for node in $HBoxContainer.get_children():
		if node.name != "Line":
			node.get_node("Button").pressed = false
	mode = "line"
	game.get_node("UI/Panel").visible = false
	game.view.annotate_icon.texture = null
	$VBoxContainer.visible = false

func on_Rectangle_pressed():
	for node in $HBoxContainer.get_children():
		if node.name != "Rectangle":
			node.get_node("Button").pressed = false
	mode = "rect"
	game.get_node("UI/Panel").visible = false
	game.view.annotate_icon.texture = null
	$VBoxContainer.visible = false

func on_Circle_pressed():
	for node in $HBoxContainer.get_children():
		if node.name != "Circle":
			node.get_node("Button").pressed = false
	mode = "circ"
	game.get_node("UI/Panel").visible = false
	game.view.annotate_icon.texture = null
	$VBoxContainer.visible = false

func on_Eraser_pressed():
	for node in $HBoxContainer.get_children():
		if node.name != "Eraser":
			node.get_node("Button").pressed = false
	mode = "eraser"
	game.get_node("UI/Panel").visible = false
	game.view.annotate_icon.texture = null
	$VBoxContainer.visible = false

func on_Icons_pressed(manual:bool = false):
	for node in $HBoxContainer.get_children():
		if node.name != "Icons":
			node.get_node("Button").pressed = false
	mode = "icon"
	if not manual and not $HBoxContainer/Icons/Button.pressed:
		$VBoxContainer.visible = not $VBoxContainer.visible
	game.get_node("UI/Panel").visible = true
	Helper.put_rsrc(game.get_node("UI/Panel/VBox"), 32, {})
	Helper.add_label(tr("KEYBOARD_SHORTCUTS"))
	Helper.add_label(tr("ANNOTATE_SHORTCUTS"), -1, false)
	game.view.annotate_icon.texture = $HBoxContainer/Icons/TextureRect.texture

func _on_close_button_pressed():
	visible = false

func _on_ColorPickerBtn_mouse_entered():
	game.show_tooltip("%s (C)" % tr("SHAPE_COLOR"))

func _on_mouse_exited():
	game.hide_tooltip()

func _on_ColorPickerBtn_pressed():
	color_picker.visible = not color_picker.visible

func _on_ColorPicker_color_changed(color):
	shape_color = color
	$ColorPickerBtn.modulate = color
	$HBoxContainer/Line/TextureRect.modulate = color
	$HBoxContainer/Rectangle/TextureRect.modulate = color
	$HBoxContainer/Circle/TextureRect.modulate = color
	$HBoxContainer/Icons/TextureRect.modulate = color
	for node in $VBoxContainer.get_children():
		node.get_node("TextureRect").modulate = color

func _on_Thickness_mouse_entered():
	changing_thickness = true
	game.show_tooltip(tr("OUTLINE_THICKNESS"))
	game.view.scroll_view = false

func _on_Thickness_value_changed(value):
	thickness = value
	$ThicknessLabel.text = String(value)

func _on_Thickness_mouse_exited():
	changing_thickness = false
	game.hide_tooltip()
	game.view.scroll_view = true

func _on_Icons_mouse_entered():
	game.show_tooltip(tr("CLICK_TWICE_TO_CHANGE"))


func _on_Annotator_visibility_changed():
	if visible:
		if mode == "icon":
			on_Icons_pressed(true)
	else:
		game.view.annotate_icon.texture = null
		game.get_node("UI/Panel").visible = false
