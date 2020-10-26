extends "Panel.gd"

func refresh():
	for hbox in $VBoxContainer.get_children():
		if hbox.name != "Titles":
			hbox.get_node("Lv").text = String(game.MUs[hbox.name])
			hbox.get_node("Upgrade").text = "  %s" % [get_min_cost(hbox.name)]
	game.add_text_icons($VBoxContainer/MV/Effects, "@i 1 = @i %s" % [game.MUs.MV + 4], [load("res://Graphics/Icons/minerals.png"), load("res://Graphics/Icons/money.png")])
	$VBoxContainer/MSMB/Effects.text = "+ %s " % [(game.MUs.MSMB - 1) * 5] + "%"

func get_min_cost(upg:String):
	return round(Data.MUs[upg].base_cost * pow(Data.MUs[upg].pw, game.MUs[upg] - 1))

func _on_Upgrade_pressed(MU:String):
	var min_cost = get_min_cost(MU)
	if game.minerals >= min_cost:
		game.minerals -= min_cost
		game.MUs[MU] += 1
		refresh()
	else:
		game.popup(tr("NOT_ENOUGH_MINERALS"), 1.5)


func _on_Label_mouse_entered(MU:String):
	game.show_tooltip(tr("%s_DESC" % [MU]))


func _on_Label_mouse_exited():
	game.hide_tooltip()
