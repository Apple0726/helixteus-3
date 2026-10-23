extends Node2D

@onready var game = get_node('/root/Game')

func _ready():
	await get_tree().create_timer(0).timeout
	for sc in $Control.get_children():
		sc.get_node("Research").mouse_entered.connect(show_tooltip.bind(sc.name))
		sc.get_node("Research").mouse_exited.connect(game.hide_tooltip)
		sc.get_node("Research").pressed.connect(on_research)
	refresh()

func show_tooltip(sc_name):
	var st = "[font_size=20]{title}[/font_size]\n\n{desc}\n\n{cost_text}: [img height=1em]res://Graphics/Icons/SP.png[/img] {cost}".format({
		"title":tr("%s_SC" % sc_name.to_upper()),
		"desc":tr("%s_SC_DESC" % sc_name.to_upper()),
		"cost_text":tr("COST"),
		"cost":Helper.format_num(Data.science_unlocks[Science.names.find(sc_name)].cost[0], true)
	})
	game.show_tooltip(st)

func on_research():
	pass

func refresh():
	for sc in $Control.get_children():
		sc.main_tree = self
		var sc_id = Science.names.find(sc.name)
		var prereqs:Dictionary = Data.science_unlocks[sc_id].prereqs
		var available:bool = true
		for p_sc in prereqs:
			if game.science_level[p_sc] < prereqs[p_sc]:
				available = false
				break
		if available:
			sc.modulate = Color.WHITE
			sc.get_node("Research").disabled = false
		else:
			sc.modulate = Color(0.5, 0.5, 0.5, 1)
			sc.get_node("Research").disabled = true
		sc.refresh()
