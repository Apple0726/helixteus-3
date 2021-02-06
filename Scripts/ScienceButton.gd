extends Panel

var main_tree
var is_over:bool = false
export var infinite_research:bool = false
onready var game = get_node("/root/Game")

func _ready():
	var font = theme.default_font
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	$Texture.texture = load("res://Graphics/Science/" + name + ".png")
	refresh()
	if not infinite_research:
		#rect_min_size.x = font.get_string_size(get_science_name(name)).x + 80
		if game.science_unlocked[name]:
			$Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
	else:
		var sc_lv:int = game.infinite_research[name]
		var st:String = tr("%s_X" % name) % sc_lv
		#rect_min_size.x = font.get_string_size(st).x + 80

func refresh():
	if infinite_research:
		var sc_lv:int = game.infinite_research[name]
		var sc:Dictionary = Data.infinite_research_sciences[name]
		$Label.text = tr("%s_X" % name) % [sc_lv + 1]
		$Text.text = Helper.format_num(sc.cost * pow(sc.pw, sc_lv), 6)
	else:
		if modulate == Color.white:
			$Label.text = get_science_name(name)
			$Text.text = Helper.format_num(Data.science_unlocks[name].cost, 6)
		else:
			$Label.text = "?"
			$Text.text = "-"

func get_science_name(sc:String):
	match sc:
		"AM":
			return tr("AUTO_MINING")
		"ATM":
			return tr("ATOM_MANIPULATION")
		"SA":
			return tr("SPACE_AGRICULTURE")
		"EGH":
			return tr("EXTRA_GREENHOUSES")
		"RC":
			return tr("ROVER_CONSTRUCTION")
		"SCT":
			return tr("SHIP_CONTROL")
		"SUP":
			return tr("SHIP_UPGRADE")
		"CD":
			return tr("CHEMICAL_DRIVE")
		"ID":
			return tr("ION_DRIVE")
		"FD":
			return tr("FUSION_DRIVE")
		"PD":
			return tr("PHOTON_DRIVE")
		"OL":
			return tr("ORANGE_LASER").format({"laser":tr("LASER")})
		"YL":
			return tr("YELLOW_LASER").format({"laser":tr("LASER")})
		"GL":
			return tr("GREEN_LASER").format({"laser":tr("LASER")})
		"BL":
			return tr("BLUE_LASER").format({"laser":tr("LASER")})
		"PL":
			return tr("PURPLE_LASER").format({"laser":tr("LASER")})
		"UVL":
			return tr("UV_LASER").format({"laser":tr("LASER")})
		"XRL":
			return tr("XRAY_LASER").format({"laser":tr("LASER")})
		"GRL":
			return tr("GAMMARAY_LASER").format({"laser":tr("LASER")})
		"UGRL":
			return tr("ULTRAGAMMARAY_LASER").format({"laser":tr("LASER")})
		"MAE":
			return tr("MACRO_ENGINEERING")
	if sc.substr(0, 2) == "DS":
		return tr("DYSON_SPHERE_X") % [sc[2]]
	elif sc.substr(0, 2) == "SE":
		return tr("SPACE_ELEVATOR_X") % [sc[2]]

func on_mouse_entered():
	is_over = true
	var tooltip:String = tr(name.to_upper() + "_DESC")
	if infinite_research:
		tooltip += "\n%s: %s" % [tr("CURRENT_MULT"), game.clever_round(pow(Data.infinite_research_sciences[name].value, game.infinite_research[name]), 3)]
	game.show_tooltip(tooltip)

func on_mouse_exited():
	is_over = false
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("left_click") and is_over:
		if infinite_research:
			var sc_lv:int = game.infinite_research[name]
			var sc:Dictionary = Data.infinite_research_sciences[name]
			if game.SP >= sc.cost * pow(sc.pw, sc_lv):
				game.SP -= sc.cost * pow(sc.pw, sc_lv)
				game.infinite_research[name] += 1
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				game.HUD.refresh()
				refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
		elif not game.science_unlocked[name]:
			if game.SP >= Data.science_unlocks[name].cost:
				game.SP -= Data.science_unlocks[name].cost
				game.science_unlocked[name] = true
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				if name == "SA":
					game.craft_panel._on_Agric_pressed()
				game.HUD.refresh()
				$Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
				main_tree.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
