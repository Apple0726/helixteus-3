extends Panel

var main_tree
var is_over:bool = false
@export var infinite_research:bool = false
var game

func _ready():
	game = get_node("/root/Game") if not Engine.is_editor_hint() else null
	var font = theme.default_font
	connect("mouse_entered",Callable(self,"on_mouse_entered"))
	connect("mouse_exited",Callable(self,"on_mouse_exited"))
	$Texture2D.texture = load("res://Graphics/Science/" + name + ".png")
	refresh()
	if game and not infinite_research:
		if game.science_unlocked.has(name):
			$Label["theme_override_colors/font_color"] = Color(0.4, 0.9, 1, 1)
			self_modulate = Color(0.24, 0.0, 1.0, 1.0)
		else:
			self_modulate = Color.GREEN
	$Label.size.x = size.x - $Texture2D.size.x - 10

func refresh():
	if infinite_research:
		var sc_lv:int = game.infinite_research[name] if game else 1
		var sc:Dictionary = Data.infinite_research_sciences[name]
		$Label.text = tr("%s_X" % name) % [sc_lv + 1]
		$Text.text = Helper.format_num(round(sc.cost * pow(sc.pw, sc_lv)))
		if round(sc.cost * pow(sc.pw, sc_lv)) > game.SP:
			$Text["theme_override_colors/font_color"] = Color.RED
		else:
			$Text["theme_override_colors/font_color"] = Color.GREEN
	else:
		if modulate == Color.WHITE:
			$Label.text = get_science_name(name)
			$Text.text = Helper.format_num(Data.science_unlocks[name].cost)
			if game.science_unlocked.has(name):
				$Text["theme_override_colors/font_color"] = Color.WHITE
			elif Data.science_unlocks[name].cost > game.SP:
				$Text["theme_override_colors/font_color"] = Color.RED
			else:
				$Text["theme_override_colors/font_color"] = Color.GREEN
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
				main_tree.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
		elif not game.science_unlocked.has(name):
			if game.SP >= Data.science_unlocks[name].cost:
				game.SP -= Data.science_unlocks[name].cost
				game.science_unlocked[name] = true
				game.popup(tr("RESEARCH_SUCCESS"), 1.5)
				if name == "RC":
					game.new_bldgs.RCC = true
					game.show.vehicles_button = true
					game.HUD.get_node("Buttons/Vehicles").visible = true
				elif name == "SA":
					game.new_bldgs.GH = true
				elif name == "ATM":
					game.show.atoms = true
					game.new_bldgs.AE = true
					game.new_bldgs.AMN = true
				elif name == "SAP":
					game.show.particles = true
					game.new_bldgs.SPR = true
					game.new_bldgs.PC = true
					game.new_bldgs.NC = true
					game.new_bldgs.EC = true
					game.new_bldgs.NSF = true
					game.new_bldgs.ESF = true
				elif name == "CI":
					game.stack_size = 32
				elif name == "CI2":
					game.stack_size = 64
				elif name == "CI3":
					game.stack_size = 128
				elif name == "AM":
					game.new_bldgs.MM = true
				elif name == "FG":
					game.new_bldgs.SY = true
				game.HUD.refresh()
				$Label["theme_override_colors/font_color"] = Color(0.4, 0.9, 1, 1)
				self_modulate = Color(0.24, 0.0, 1.0, 1.0)
				$Text["theme_override_colors/font_color"] = Color.WHITE
				main_tree.refresh()
			else:
				game.popup(tr("NOT_ENOUGH_SP"), 1.5)
