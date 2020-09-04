extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String
var buy_sell_scene = preload("res://Scenes/BuySellPanel.tscn")
var buy_sell

func _ready():
	buy_sell = buy_sell_scene.instance()
	buy_sell.visible = false
	add_child(buy_sell)
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
		texture.connect("pressed", self, "show_buy_sell", ["Materials", mat])
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
		texture.connect("pressed", self, "show_buy_sell", ["Metals", met])
		rsrc.get_node("Text").text = String(game.clever_round(game.mets[met], 3)) + " kg"
		$Contents/Control/GridContainer.add_child(rsrc)

func show_buy_sell(type:String, obj:String):
	if type == "Materials" and game.mats[obj] == 0:
		return
	if type == "Metals" and game.mets[obj] == 0:
		return
	buy_sell.visible = true
	buy_sell.refresh(type, obj)
	if not game.panels.has("buy_sell"):
		game.panels.push_front("buy_sell")

func show_mat(mat:String):
	game.show_tooltip(get_mat_str(mat) + "\n" + get_mat_str(mat, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_mat():
	game.hide_tooltip()

func show_met(met:String):
	game.show_tooltip(get_met_str(met) + "\n" + get_met_str(met, "_DESC") + "\n" + tr("CLICK_TO_BUY_SELL"))

func hide_met():
	game.hide_tooltip()

func get_mat_str(mat:String, desc:String = ""):
	match mat:
		"coal":
			return tr("COAL" + desc)
		"glass":
			return tr("GLASS" + desc)
		"sand":
			return tr("SAND" + desc)
		"clay":
			return tr("CLAY" + desc)
		"soil":
			return tr("SOIL" + desc)
		"cellulose":
			return tr("CELLULOSE" + desc)

func get_met_str(met:String, desc:String = ""):
	match met:
		"lead":
			return tr("LEAD" + desc)
		"copper":
			return tr("COPPER" + desc)
		"iron":
			return tr("IRON" + desc)
		"aluminium":
			return tr("ALUMINIUM" + desc)
		"silver":
			return tr("SILVER" + desc)
		"gold":
			return tr("GOLD" + desc)
		"amethyst":
			return tr("AMETHYST" + desc)
		"emerald":
			return tr("EMERALD" + desc)
		"quartz":
			return tr("QUARTZ" + desc)
		"topaz":
			return tr("TOPAZ" + desc)
		"ruby":
			return tr("RUBY" + desc)
		"sapphire":
			return tr("SAPPHIRE" + desc)

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
