extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String

func _ready():
	tween = Tween.new()
	add_child(tween)
	_on_Materials_pressed()

func refresh_values():
	if tab == "materials":
		_on_Materials_pressed()

func _on_Materials_pressed():
	tab = "materials"
	remove_everything()
	$Contents/Info.text = tr("INV_MAT_DESC")
	set_btn_color($Tabs/Materials)
	for mat in game.mats:
		var hbox:HBoxContainer = HBoxContainer.new()
		var texture:TextureButton = TextureButton.new()
		var label = Label.new()
		hbox["custom_constants/separation"] = 15
		hbox.set_h_size_flags(hbox.SIZE_EXPAND_FILL)
		texture.texture_normal = load("res://Graphics/Materials/" + mat + ".png")
		texture.expand = true
		texture.connect("mouse_entered", self, "show_mat", [mat])
		texture.connect("mouse_exited", self, "hide_mat")
		texture.rect_min_size = Vector2(48, 48)
		label.text = String(game.mats[mat]) + " kg"
		$Contents/Control/GridContainer.add_child(hbox)
		hbox.add_child(texture)
		hbox.add_child(label)

func show_mat(mat:String):
	game.show_tooltip(get_mat_str(mat))

func hide_mat():
	game.hide_tooltip()

func get_mat_str(mat:String):
	match mat:
		"coal":
			return tr("COAL")
		"glass":
			return tr("GLASS")
		"sand":
			return tr("SAND")
		"clay":
			return tr("CLAY")
		"soil":
			return tr("SOIL")
		"cellulose":
			return tr("CELLULOSE")

func set_btn_color(btn):
	for other_btn in $Tabs.get_children():
		other_btn["custom_colors/font_color"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_hover"] = Color(1, 1, 1, 1)
		other_btn["custom_colors/font_color_pressed"] = Color(1, 1, 1, 1)
	btn["custom_colors/font_color"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_hover"] = Color(0, 1, 1, 1)
	btn["custom_colors/font_color_pressed"] = Color(0, 1, 1, 1)

func remove_everything():
	for thing in $Contents/Control/GridContainer.get_children():
		$Contents/Control/GridContainer.remove_child(thing)
