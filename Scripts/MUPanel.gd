extends "Panel.gd"

func _ready():
	set_polygon(rect_size)
	for MU in game.MUs:
		var hbox = HBoxContainer.new()
		var title = preload("res://Scenes/HelpText.tscn").instance()
		title.name = "Label"
		title.label_text = "%s_NAME" % MU
		title.help_text = "%s_DESC" % MU
		title.rect_min_size.x = 450
		title.rect_min_size.y = 30
		title.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		title.size_flags_vertical = Label.SIZE_SHRINK_CENTER
		title.mouse_filter = Label.MOUSE_FILTER_PASS
		hbox.add_child(title)
		var lv = Label.new()
		lv.name = "Lv"
		lv.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		hbox.add_child(lv)
		var effects
		if MU == "MV":
			effects = RichTextLabel.new()
			effects.size_flags_vertical = Label.SIZE_SHRINK_CENTER
		else:
			effects = Label.new()
		effects.name = "Effects"
		effects.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		hbox.add_child(effects)
		var btn = Button.new()
		btn.name = "Upgrade"
		btn.connect("mouse_entered", self, "_on_Upgrade_mouse_entered", [MU])
		btn.connect("mouse_exited", self, "_on_Upgrade_mouse_exited", [MU])
		btn.connect("pressed", self, "_on_Upgrade_pressed", [MU])
		btn.rect_min_size.x = 178
		btn.expand_icon = true
		btn.icon = Data.minerals_icon
		btn.align = Button.ALIGN_LEFT
		hbox.name = MU
		hbox.add_child(btn)
		if game.achievement_data.progression.has("new_universe"):
			btn.rect_min_size.x = 178 - 45
			var btn_max = Button.new()
			btn_max.connect("pressed", self, "_on_UpgradeMax_pressed", [MU])
			btn_max.rect_min_size.x = 45
			btn_max.name = "UpgradeMax"
			btn_max.expand_icon = true
			btn_max.icon = preload("res://Graphics/Science/UP2.png")
			hbox.add_child(btn_max)
		$Panel/VBox.add_child(hbox)

func refresh():
	$Panel/VBox/AIE.visible = game.show.has("auroras")
	$Panel/VBox/MSMB.visible = game.show.has("mining")
	$Panel/VBox/STMB.visible = game.STM_lv >= 2
	$Panel/VBox/SHSR.visible = game.stats_univ.planets_conquered >= 2
	$Panel/VBox/CHR.visible = game.stats_univ.planets_conquered >= 2
	$Panel/VBox/SHSR/Upgrade.visible = game.MUs.SHSR < 50
	if game.achievement_data.progression.has("new_universe"):
		$Panel/VBox/SHSR/UpgradeMax.visible = game.MUs.SHSR < 50
		$Panel/VBox/CHR/UpgradeMax.visible = game.MUs.CHR < 90
	$Panel/VBox/CHR/Upgrade.visible = game.MUs.CHR < 90
	for hbox in $Panel/VBox.get_children():
		if hbox.name != "Titles":
			hbox.get_node("Lv").text = String(game.MUs[hbox.name])
			hbox.get_node("Upgrade").text = "  %s" % [Helper.format_num(get_min_cost(hbox.name))]
			set_upg_text(hbox.name)

func set_upg_text(MU:String, next_lv:int = 0):
	match MU:
		"MV":
			game.add_text_icons($Panel/VBox/MV/Effects, "@i 1 = @i %s" % [game.MUs.MV + next_lv + 4], [Data.minerals_icon, load("res://Graphics/Icons/money.png")], 15)
		"MSMB":
			$Panel/VBox/MSMB/Effects.text = "+ %s %%" % ((game.MUs.MSMB + next_lv - 1) * 10)
		"IS":
			$Panel/VBox/IS/Effects.text = tr("X_SLOTS") % [game.MUs.IS + next_lv + 9]
		"AIE":
			$Panel/VBox/AIE/Effects.text = str(Helper.get_AIE(next_lv))
		"STMB":
			$Panel/VBox/STMB/Effects.text = "+ %s %%" % ((game.MUs.STMB + next_lv - 1) * 15)
		"SHSR":
			$Panel/VBox/SHSR/Effects.text = "- %s %%" % (game.MUs.SHSR + next_lv - 1)
		"CHR":
			$Panel/VBox/CHR/Effects.text = "%s %%" % (10 + game.MUs.CHR + next_lv - 1)
	if next_lv == 0:
		get_node("Panel/VBox/%s/Effects" % [MU])["custom_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.white
	else:
		get_node("Panel/VBox/%s/Effects" % [MU])["custom_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.green
			
func get_min_cost(upg:String):
	return round(Data.MUs[upg].base_cost * pow(Data.MUs[upg].pw, game.MUs[upg] - 1))

func _on_UpgradeMax_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	while game.minerals >= min_cost:
		if MU == "SHSR" and game.MUs.SHSR >= 50 or MU == "CHR" and game.MUs.CHR >= 90:
			break
		game.minerals -= min_cost
		game.MUs[MU] += 1
		min_cost = get_min_cost(MU)
		if MU == "AIE":
			for AI in game.aurora_prod.keys():
				for rsrc in game.aurora_prod[AI].keys():
					var m = pow(1 + AI, 0.02)
					if rsrc == "energy":
						game.autocollect.rsrc.energy += game.aurora_prod[AI].energy * (m - 1.0)
					elif rsrc in game.mat_info.keys():
						game.autocollect.mats[rsrc] += game.aurora_prod[AI][rsrc] * (m - 1.0)
					elif rsrc in game.met_info.keys():
						game.autocollect.mets[rsrc] += game.aurora_prod[AI][rsrc] * (m - 1.0)
					game.aurora_prod[AI][rsrc] *= m
		elif MU == "IS":
			game.items.append(null)
	if MU == "AIE" and game.c_v == "mining" and game.mining_HUD.tile.has("au_int"):
		game.mining_HUD.refresh_aurora_bonus()
	refresh()
	game.HUD.refresh()

func _on_Upgrade_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	if game.minerals >= min_cost:
		game.minerals -= min_cost
		game.MUs[MU] += 1
		refresh()
		if not game.objective.empty() and game.objective.type == game.ObjectiveType.MINERAL_UPG:
			game.objective.current += 1
		game.HUD.refresh()
		if MU == "AIE":
			if game.c_v == "mining" and game.mining_HUD.tile.has("au_int"):
				game.mining_HUD.refresh_aurora_bonus()
			for AI in game.aurora_prod.keys():
				for rsrc in game.aurora_prod[AI].keys():
					var m = pow(1 + AI, 0.02)
					if rsrc == "energy":
						game.autocollect.rsrc.energy += game.aurora_prod[AI].energy * (m - 1.0)
					elif rsrc in game.mat_info.keys():
						game.autocollect.mats[rsrc] += game.aurora_prod[AI][rsrc] * (m - 1.0)
					elif rsrc in game.met_info.keys():
						game.autocollect.mets[rsrc] += game.aurora_prod[AI][rsrc] * (m - 1.0)
					game.aurora_prod[AI][rsrc] *= m
		elif MU == "IS":
			game.items.append(null)
	else:
		game.popup(tr("NOT_ENOUGH_MINERALS"), 1.5)

func _on_Upgrade_mouse_entered(MU:String):
	set_upg_text(MU, 1) 

func _on_Upgrade_mouse_exited(MU:String):
	set_upg_text(MU, 0)
