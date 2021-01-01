extends "Panel.gd"

func _ready():
	set_polygon($Background.rect_size)
	
func refresh():
	for hbox in $VBoxContainer.get_children():
		if hbox.name != "Titles":
			hbox.get_node("Lv").text = String(game.MUs[hbox.name])
			hbox.get_node("Upgrade").text = "  %s" % [get_min_cost(hbox.name)]
	set_upg_text("MV")
	set_upg_text("MSMB")
	set_upg_text("IS")
	set_upg_text("AIE")

func set_upg_text(MU:String, next_lv:int = 0):
	match MU:
		"MV":
			game.add_text_icons($VBoxContainer/MV/Effects, "@i 1 = @i %s" % [game.MUs.MV + next_lv + 4], [load("res://Graphics/Icons/minerals.png"), load("res://Graphics/Icons/money.png")])
		"MSMB":
			$VBoxContainer/MSMB/Effects.text = "+ %s " % [(game.MUs.MSMB + next_lv - 1) * 5] + "%"
		"IS":
			$VBoxContainer/IS/Effects.text = tr("X_SLOTS") % [game.MUs.IS + next_lv + 9]
		"AIE":
			$VBoxContainer/AIE/Effects.text = String(Helper.get_AIE(next_lv))
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

func _on_close_button_pressed():
	game.toggle_panel(self)

func _on_Upgrade_mouse_entered(MU:String):
	set_upg_text(MU, 1) 

func _on_Upgrade_mouse_exited(MU:String):
	set_upg_text(MU, 0)
