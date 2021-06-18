extends "Panel.gd"

func _ready():
	set_polygon($Background.rect_size)
	for MU in game.MUs:
		var hbox = HBoxContainer.new()
		var title = Label.new()
		title.name = "Label"
		title.text = tr("%s_NAME" % MU)
		title["custom_colors/font_color"] = Color.yellow
		title.rect_min_size.x = 450
		title.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		title.mouse_filter = Label.MOUSE_FILTER_PASS
		title.connect("mouse_entered", self, "_on_Label_mouse_entered", [MU])
		title.connect("mouse_exited", self, "_on_Label_mouse_exited")
		hbox.add_child(title)
		var lv = Label.new()
		lv.name = "Lv"
		lv.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		hbox.add_child(lv)
		var effects
		if MU == "MV":
			effects = RichTextLabel.new()
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
		$VBoxContainer.add_child(hbox)
	
func refresh():
	$VBoxContainer/AIE.visible = game.show.auroras
	$VBoxContainer/MSMB.visible = game.show.mining
	$VBoxContainer/STMB.visible = game.STM_lv >= 2
	$VBoxContainer/SHSR.visible = game.stats.planets_conquered >= 2
	$VBoxContainer/CHR.visible = game.stats.planets_conquered >= 2
	for hbox in $VBoxContainer.get_children():
		if hbox.name != "Titles":
			hbox.get_node("Lv").text = String(game.MUs[hbox.name])
			hbox.get_node("Upgrade").text = "  %s" % [Helper.format_num(get_min_cost(hbox.name), 6)]
			set_upg_text(hbox.name)

func set_upg_text(MU:String, next_lv:int = 0):
	match MU:
		"MV":
			game.add_text_icons($VBoxContainer/MV/Effects, "@i 1 = @i %s" % [game.MUs.MV + next_lv + 4], [Data.minerals_icon, load("res://Graphics/Icons/money.png")], 15)
		"MSMB":
			$VBoxContainer/MSMB/Effects.text = "+ %s %%" % ((game.MUs.MSMB + next_lv - 1) * 10)
		"IS":
			$VBoxContainer/IS/Effects.text = tr("X_SLOTS") % [game.MUs.IS + next_lv + 9]
		"AIE":
			$VBoxContainer/AIE/Effects.text = String(Helper.get_AIE(next_lv))
		"STMB":
			$VBoxContainer/STMB/Effects.text = "+ %s %%" % ((game.MUs.STMB + next_lv - 1) * 15)
		"SHSR":
			$VBoxContainer/SHSR/Effects.text = "- %s %%" % (game.MUs.SHSR + next_lv - 1)
		"CHR":
			$VBoxContainer/CHR/Effects.text = "%s %%" % (10 + (game.MUs.CHR + next_lv - 1) * 2.5)
	if next_lv == 0:
		get_node("VBoxContainer/%s/Effects" % [MU])["custom_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.white
	else:
		get_node("VBoxContainer/%s/Effects" % [MU])["custom_colors/%s" % ["default_color" if MU == "MV" else "font_color"]] = Color.green
			
func get_min_cost(upg:String):
	return round(Data.MUs[upg].base_cost * pow(Data.MUs[upg].pw, game.MUs[upg] - 1))

func _on_Upgrade_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	if game.minerals >= min_cost:
		game.minerals -= min_cost
		game.MUs[MU] += 1
		refresh()
		if not game.objective.empty() and game.objective.type == game.ObjectiveType.MINERAL_UPG:
			game.objective.current += 1
		game.HUD.refresh()
		if MU == "AIE" and game.c_v == "mining" and game.mining_HUD.tile.has("au_int"):
			game.mining_HUD.refresh_aurora_bonus()
		if MU == "IS":
			game.items.append(null)
	else:
		game.popup(tr("NOT_ENOUGH_MINERALS"), 1.5)


func _on_Label_mouse_entered(MU:String):
	game.show_tooltip(tr("%s_DESC" % [MU]))


func _on_Label_mouse_exited():
	game.hide_tooltip()

func _on_Upgrade_mouse_entered(MU:String):
	set_upg_text(MU, 1) 

func _on_Upgrade_mouse_exited(MU:String):
	set_upg_text(MU, 0)
