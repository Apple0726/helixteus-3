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
	elif tab == "metals":
		_on_Metals_pressed()

func _on_Materials_pressed():
	tab = "materials"
	remove_everything()
	$Contents/Info.text = tr("INV_MAT_DESC")
	set_btn_color($Tabs/Materials)
	for mat in game.mats:
		if game.show.has(mat) and not game.show[mat]:
			continue
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		texture.texture_normal = load("res://Graphics/Materials/" + mat + ".png")
		texture.connect("mouse_entered", self, "show_mat", [mat])
		texture.connect("mouse_exited", self, "hide_mat")
		rsrc.get_node("Text").text = String(game.clever_round(game.mats[mat], 3)) + " kg"
		$Contents/Control/GridContainer.add_child(rsrc)

func _on_Metals_pressed():
	tab = "metals"
	remove_everything()
	$Contents/Info.text = tr("INV_MET_DESC")
	set_btn_color($Tabs/Metals)
	for met in game.mets:
		if game.show.has(met) and not game.show[met]:
			continue
		var rsrc = game.rsrc_scene.instance()
		var texture = rsrc.get_node("Texture")
		texture.texture_normal = load("res://Graphics/Metals/" + met + ".png")
		texture.connect("mouse_entered", self, "show_met", [met])
		texture.connect("mouse_exited", self, "hide_met")
		rsrc.get_node("Text").text = String(game.clever_round(game.mets[met], 3)) + " kg"
		$Contents/Control/GridContainer.add_child(rsrc)
#		var hbox:HBoxContainer = HBoxContainer.new()
#		var texture:TextureButton = TextureButton.new()
#		var label = Label.new()
#		hbox["custom_constants/separation"] = 15
#		hbox.set_h_size_flags(hbox.SIZE_EXPAND_FILL)
#		texture.texture_normal = load("res://Graphics/Metals/" + met + ".png")
#		texture.expand = true
#		texture.connect("mouse_entered", self, "show_met", [met])
#		texture.connect("mouse_exited", self, "hide_met")
#		texture.rect_min_size = Vector2(48, 48)
#		label.text = String(game.clever_round(game.mets[met], 3)) + " kg"
#		$Contents/Control/GridContainer.add_child(hbox)
#		hbox.add_child(texture)
#		hbox.add_child(label)

func show_mat(mat:String):
	game.show_tooltip(get_mat_str(mat))

func hide_mat():
	game.hide_tooltip()

func show_met(met:String):
	game.show_tooltip(get_met_str(met) + "\n" + get_met_desc(met))

func hide_met():
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

func get_met_str(met:String):
	match met:
		"lead":
			return tr("LEAD")
		"copper":
			return tr("COPPER")
		"iron":
			return tr("IRON")
		"aluminium":
			return tr("ALUMINIUM")
		"silver":
			return tr("SILVER")
		"gold":
			return tr("GOLD")
		"amethyst":
			return tr("AMETHYST")
		"emerald":
			return tr("EMERALD")
		"quartz":
			return tr("QUARTZ")
		"topaz":
			return tr("TOPAZ")
		"ruby":
			return tr("RUBY")
		"sapphire":
			return tr("SAPPHIRE")

func get_met_desc(met:String):
	match met:
		"lead":
			return tr("LEAD_DESC")
		"copper":
			return tr("COPPER_DESC")
		"iron":
			return tr("IRON_DESC")
		"aluminium":
			return tr("ALUMINIUM_DESC")
		"silver":
			return tr("SILVER_DESC")
		"gold":
			return tr("GOLD_DESC")
		"amethyst":
			return tr("AMETHYST_DESC")
		"emerald":
			return tr("EMERALD_DESC")
		"quartz":
			return tr("QUARTZ_DESC")
		"topaz":
			return tr("TOPAZ_DESC")
		"ruby":
			return tr("RUBY_DESC")
		"sapphire":
			return tr("SAPPHIRE_DESC")

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
