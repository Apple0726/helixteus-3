extends Control

onready var game = get_node("/root/Game")
#Tween for fading in/out panel
var tween:Tween
var tab:String
var buy_sell_scene = preload("res://Scenes/Panels/BuySellPanel.tscn")
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
	$Contents/Info.text = tr("INV_MAT_DESC")
	Helper.set_btn_color($Tabs/Materials)
	var mat_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mats)
	for mat in mat_data:
		if game.show.has(mat.name) and not game.show[mat.name]:
			mat.rsrc.visible = false
			continue
		var texture = mat.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_mat", [mat.name])
		texture.connect("mouse_exited", self, "hide_mat")
		texture.connect("pressed", self, "show_buy_sell", ["Materials", mat.name])

func _on_Metals_pressed():
	tab = "metals"
	$Contents/Info.text = tr("INV_MET_DESC")
	Helper.set_btn_color($Tabs/Metals)
	var met_data = Helper.put_rsrc($Contents/Control/GridContainer, 48, game.mets)
	for met in met_data:
		if game.show.has(met.name) and not game.show[met.name]:
			met.rsrc.visible = false
			continue
		var texture = met.rsrc.get_node("Texture")
		texture.connect("mouse_entered", self, "show_met", [met.name])
		texture.connect("mouse_exited", self, "hide_met")
		texture.connect("pressed", self, "show_buy_sell", ["Metals", met.name])

func show_buy_sell(type:String, obj:String):
	if type == "Materials" and game.mats[obj] == 0:
		game.popup("NONE_TO_SELL", 1.5)
		return
	if type == "Metals" and game.mets[obj] == 0:
		game.popup("NONE_TO_SELL", 1.5)
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
