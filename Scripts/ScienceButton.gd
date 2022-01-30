tool
extends Panel

var main_tree
var is_over:bool = false
export var infinite_research:bool = false
var game

func _ready():
	game = get_node("/root/Game") if not Engine.editor_hint else null
	var font = theme.default_font
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	$Texture.texture = load("res://Graphics/Science/" + name + ".png")
	refresh()
	if game and not infinite_research:
		#rect_min_size.x = font.get_string_size(get_science_name(name)).x + 80
		if game.science_unlocked.has(name):
			$Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
	#else:
		#var sc_lv:int = game.infinite_research[name]
		#var st:String = tr("%s_X" % name) % sc_lv
		#rect_min_size.x = font.get_string_size(st).x + 80
	$Label.rect_size.x = rect_size.x - $Texture.rect_size.x - 10

func refresh():
	if infinite_research:
		var sc_lv:int = game.infinite_research[name] if game else 1
		var sc:Dictionary = Data.infinite_research_sciences[name]
		$Label.text = tr("%s_X" % name) % [sc_lv + 1]
		$Text.text = Helper.format_num(round(sc.cost * pow(sc.pw, sc_lv)))
	else:
		if modulate == Color.white:
			$Label.text = get_science_name(name)
			$Text.text = Helper.format_num(Data.science_unlocks[name].cost)
		else:
			$Label.text = "?"
			$Text.text = "-"

func get_science_name(sc:String):
	match sc:
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
	if sc.substr(0, 2) == "DS":
		return "%s %s" % [tr("M_DS_NAME"), sc[2]]
	elif sc.substr(0, 2) == "SE":
		return "%s %s" % [tr("M_SE_NAME"), sc[2]]
	elif sc.substr(0, 3) == "MME":
		return "%s %s" % [tr("M_MME_NAME"), sc[3]]
	elif sc.substr(0, 3) == "CBS":
		return "%s %s" % [tr("M_CBS_NAME"), sc[3]]
	elif sc.substr(0, 2) == "PK":
		return "%s %s" % [tr("M_PK_NAME"), sc[2]]
	elif sc.substr(0, 2) == "MB":
		return tr("M_MB_NAME")
	elif sc.substr(0, 4) == "MPCC":
		return tr("M_MPCC_NAME")
	return tr("%s_SC" % sc)

func on_mouse_entered():
	is_over = true
	var tooltip:String = ""
	if infinite_research:
		tooltip = "%s\n%s: %s" % [tr(name.to_upper() + "_DESC") % game.maths_bonus.IRM, tr("CURRENT_MULT"), Helper.clever_round(pow(game.maths_bonus.IRM, game.infinite_research[name]))]
	else:
		tooltip = tr(name.to_upper() + "_DESC")
	game.show_tooltip(tooltip)

func on_mouse_exited():
	is_over = false
	game.hide_tooltip()

func _input(event):
	if Input.is_action_just_released("left_click") and is_over:
		if infinite_research:
			var sc_lv:int = game.infinite_research[name]
			var sc:Dictionary = Data.infinite_research_sciences[name]
			if game.SP >= round(sc.cost * pow(sc.pw, sc_lv)):
				game.SP -= round(sc.cost * pow(sc.pw, sc_lv))
				game.infinite_research[name] += 1
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				game.HUD.refresh()
				refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
		elif not game.science_unlocked.has(name):
			if game.SP >= Data.science_unlocks[name].cost:
				game.SP -= Data.science_unlocks[name].cost
				game.science_unlocked[name] = true
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				if name == "RC":
					game.show.vehicles_button = true
				elif name == "SA":
					game.craft_panel._on_btn_pressed("Agriculture")
				elif name == "ATM":
					game.show.atoms = true
				elif name == "SAP":
					game.show.particles = true
				elif name == "CI":
					game.stack_size = 32
				elif name == "CI2":
					game.stack_size = 64
				elif name == "CI3":
					game.stack_size = 128
				elif name == "RMK2":
					game.RC_panel.inventory.append({"type":""})
				elif name == "RMK3":
					game.RC_panel.inventory.append({"type":""})
				game.HUD.refresh()
				$Label["custom_colors/font_color"] = Color(0, 1, 0, 1)
				main_tree.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
