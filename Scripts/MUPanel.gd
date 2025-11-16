extends "Panel.gd"

func _ready():
	set_polygon($GUI.size, $GUI.position)
	for MU in game.MUs:
		var hbox = HBoxContainer.new()
		var title = preload("res://Scenes/HelpText.tscn").instantiate()
		title.name = "Label"
		title.label_text = "%s_NAME" % MU
		title.help_text = "%s_DESC" % MU
		title.custom_minimum_size.x = 450
		title.custom_minimum_size.y = 30
		title.size_flags_vertical = Label.SIZE_SHRINK_CENTER
		title.mouse_filter = Label.MOUSE_FILTER_PASS
		hbox.add_child(title)
		var lv = Label.new()
		lv.name = "Lv"
		lv.custom_minimum_size.x = 170
		hbox.add_child(lv)
		var effects
		if MU == "MV":
			effects = RichTextLabel.new()
			effects.size_flags_vertical = Label.SIZE_SHRINK_CENTER
			effects.fit_content = true
		else:
			effects = Label.new()
		effects.name = "Effects"
		effects.custom_minimum_size.x = 160
		hbox.add_child(effects)
		var btn = Button.new()
		btn.name = "Upgrade"
		btn.connect("mouse_entered",Callable(self,"_on_Upgrade_mouse_entered").bind(MU))
		btn.connect("mouse_exited",Callable(self,"_on_Upgrade_mouse_exited").bind(MU))
		btn.connect("pressed",Callable(self,"_on_Upgrade_pressed").bind(MU))
		btn.custom_minimum_size.x = 190
		btn.expand_icon = true
		btn.icon = Data.minerals_icon
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		hbox.name = MU
		hbox.add_child(btn)
		var spacer = Control.new()
		hbox.add_child(spacer)
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if game.achievement_data.progression.has("new_universe"):
			var btn_max = Button.new()
			btn_max.connect("pressed",Callable(self,"_on_UpgradeMax_pressed").bind(MU))
			btn_max.custom_minimum_size.x = 32
			btn_max.name = "UpgradeMax"
			btn_max.expand_icon = true
			btn_max.icon = preload("res://Graphics/Science/UP2.png")
			hbox.add_child(btn_max)
		$PanelContainer/VBox.add_child(hbox)

func refresh():
	$PanelContainer/VBox/MSMB.visible = game.show.has("mining")
	$PanelContainer/VBox/STMB.visible = game.STM_lv >= 1
	$PanelContainer/VBox/SHSR.visible = game.stats_univ.planets_conquered >= 2
	$PanelContainer/VBox/CHR.visible = game.stats_univ.planets_conquered >= 2
	if game.MUs.SHSR >= 51:
		var upgrade_btn = $PanelContainer/VBox/SHSR/Upgrade
		upgrade_btn.modulate.a = 0.0
		if upgrade_btn.is_connected("pressed",Callable(self,"_on_Upgrade_pressed")):
			upgrade_btn.disconnect("mouse_entered",Callable(self,"_on_Upgrade_mouse_entered"))
			upgrade_btn.disconnect("mouse_exited",Callable(self,"_on_Upgrade_mouse_exited"))
			upgrade_btn.disconnect("pressed",Callable(self,"_on_Upgrade_pressed"))
	if game.achievement_data.progression.has("new_universe"):
		if game.MUs.SHSR >= 51:
			var upgrade_max_btn = $PanelContainer/VBox/SHSR/UpgradeMax
			upgrade_max_btn.modulate.a = 0.0
			if upgrade_max_btn.is_connected("pressed",Callable(self,"_on_UpgradeMax_pressed")):
				upgrade_max_btn.disconnect("pressed",Callable(self,"_on_UpgradeMax_pressed"))
		$PanelContainer/VBox/CHR/UpgradeMax.visible = game.MUs.CHR < 90
	$PanelContainer/VBox/CHR/Upgrade.visible = game.MUs.CHR < 90
	for hbox in $PanelContainer/VBox.get_children():
		if hbox.name != "Titles":
			hbox.get_node("Lv").text = str(game.MUs[hbox.name])
			hbox.get_node("Upgrade").text = "  %s" % [Helper.format_num(get_min_cost(hbox.name))]
			set_upg_text(hbox.name)

func set_upg_text(MU:String, next_lv:int = 0):
	match MU:
		"MV":
			Helper.add_text_to_RTL($PanelContainer/VBox/MV/Effects, "@i 1 = @i %s" % [game.MUs.MV + next_lv + 4], [Data.minerals_icon, Data.money_icon], 15)
		"MSMB":
			$PanelContainer/VBox/MSMB/Effects.text = "+ %s %%" % ((game.MUs.MSMB + next_lv - 1) * 10)
		"IS":
			$PanelContainer/VBox/IS/Effects.text = tr("X_SLOTS") % [game.MUs.IS + next_lv + 9]
		"STMB":
			$PanelContainer/VBox/STMB/Effects.text = "+ %s %%" % ((game.MUs.STMB + next_lv - 1) * 15)
		"SHSR":
			$PanelContainer/VBox/SHSR/Effects.text = "- %s %%" % (game.MUs.SHSR + next_lv - 1)
		"CHR":
			$PanelContainer/VBox/CHR/Effects.text = "%s %%" % (10 + game.MUs.CHR + next_lv - 1)
	if next_lv == 0:
		get_node("PanelContainer/VBox/%s/Effects" % [MU])["theme_override_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.WHITE
	else:
		get_node("PanelContainer/VBox/%s/Effects" % [MU])["theme_override_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.GREEN
			
func get_min_cost(upg:String):
	return round(Data.MUs[upg].base_cost * pow(Data.MUs[upg].pw, game.MUs[upg] - 1))

func _on_UpgradeMax_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	while game.minerals >= min_cost:
		if MU == "SHSR" and game.MUs.SHSR >= 51 or MU == "CHR" and game.MUs.CHR >= 90:
			break
		game.minerals -= min_cost
		game.MUs[MU] += 1
		min_cost = get_min_cost(MU)
		if MU == "IS":
			game.items.append(null)
	refresh()
	game.HUD.refresh()

func _on_Upgrade_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	if game.minerals >= min_cost:
		game.minerals -= min_cost
		game.MUs[MU] += 1
		refresh()
		#if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.MINERAL_UPG:
			#game.objective.current += 1
		game.HUD.refresh()
		if MU == "IS":
			game.items.append(null)
	else:
		game.popup(tr("NOT_ENOUGH_MINERALS"), 1.5)

func _on_Upgrade_mouse_entered(MU:String):
	set_upg_text(MU, 1) 

func _on_Upgrade_mouse_exited(MU:String):
	set_upg_text(MU, 0)
