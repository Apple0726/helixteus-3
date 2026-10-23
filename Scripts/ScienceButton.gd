extends Panel

var main_tree
@export var icon_texture:Texture2D
@onready var game = get_node("/root/Game")

func _ready():
	$Texture2D.texture = icon_texture
	refresh()

func refresh():
	var sc_id = Science.names.find(name)
	var infinite_research = Data.science_unlocks[sc_id].has("infinite_research")
	var sc_lv:int = game.science_level[sc_id]
	#if infinite_research:
		#var sc_lv:int = game.infinite_research[name]
		#var sc:Dictionary = Data.infinite_research_sciences[name]
		#$Label.text = tr("%s_X" % name) % [sc_lv + 1]
		#$Text.text = Helper.format_num(round(sc.cost * pow(sc.pw, sc_lv)))
		#if round(sc.cost * pow(sc.pw, sc_lv)) > game.SP:
			#$Text["theme_override_colors/font_color"] = Color.RED
		#else:
			#$Text["theme_override_colors/font_color"] = Color.GREEN
	#else:
		#if modulate == Color.WHITE:
			#$Label.text = get_science_name(name)
			#$Text.text = Helper.format_num(Data.science_unlocks[name].cost)
			#if game.science_level.has(name):
				#$Text["theme_override_colors/font_color"] = Color.WHITE
			#elif Data.science_unlocks[name].cost > game.SP:
				#$Text["theme_override_colors/font_color"] = Color.RED
			#else:
				#$Text["theme_override_colors/font_color"] = Color.GREEN
		#else:
			#$Label.text = "?"
			#$Text.text = "-"

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

func show_tooltip():
	var tooltip:String = ""
	#if infinite_research:
		#tooltip = "%s\n%s: %s" % [tr(name.to_upper() + "_DESC") % game.maths_bonus.IRM, tr("CURRENT_MULT"), Helper.clever_round(pow(game.maths_bonus.IRM, game.infinite_research[name]))]
	#else:
		#tooltip = tr(name.to_upper() + "_DESC")
	game.show_tooltip(tooltip)

func on_research():
	pass
	#if infinite_research:
		#var sc_lv:int = game.infinite_research[name]
		#var sc:Dictionary = Data.infinite_research_sciences[name]
		#if game.SP >= round(sc.cost * pow(sc.pw, sc_lv)):
			#game.SP -= round(sc.cost * pow(sc.pw, sc_lv))
			#game.infinite_research[name] += 1
			#game.popup(tr("RESEARCH_SUCCESS"), 1.5)
			#game.HUD.refresh()
			#main_tree.refresh()
		#else:
			#game.popup(tr("NOT_ENOUGH_SP"), 1.5)
	#elif not game.science_level.has(name):
		#if game.SP >= Data.science_unlocks[name].cost:
			#game.SP -= Data.science_unlocks[name].cost
			#game.science_level[name] = true
			#game.popup(tr("RESEARCH_SUCCESS"), 1.5)
			#if name == "RC":
				#Helper.show_bldg_unlocked_popup(Building.ROVER_CONSTRUCTION_CENTER)
				#game.show.vehicles_button = true
				#game.HUD.get_node("Buttons/Vehicles").visible = true
			#elif name == "SA":
				#Helper.show_bldg_unlocked_popup(Building.GREENHOUSE)
			#elif name == "ATM":
				#game.show.atoms = true
				#Helper.show_bldg_unlocked_popup(Building.ATMOSPHERE_EXTRACTOR)
				#Helper.show_bldg_unlocked_popup(Building.ATOM_MANIPULATOR)
			#elif name == "SAP":
				#game.show.particles = true
				#Helper.show_bldg_unlocked_popup(Building.SUBATOMIC_PARTICLE_REACTOR)
			#elif name == "CI":
				#game.stack_size = 32
			#elif name == "CI2":
				#game.stack_size = 64
			#elif name == "CI3":
				#game.stack_size = 128
			#elif name == "AM":
				#Helper.show_bldg_unlocked_popup(Building.BORING_MACHINE)
			#elif name == "FG":
				#Helper.show_bldg_unlocked_popup(Building.SHIPYARD)
			#game.HUD.refresh()
			#$Label["theme_override_colors/font_color"] = Color(0.4, 0.9, 1, 1)
			#self_modulate = Color(0.24, 0.0, 1.0, 1.0)
			#$Text["theme_override_colors/font_color"] = Color.WHITE
			#main_tree.refresh()
		#else:
			#game.popup(tr("NOT_ENOUGH_SP"), 1.5)
