extends Node2D

onready var game = get_node('/root/Game')
var sc_over:String = ""

func _ready():
	yield(get_tree().create_timer(0), "timeout")
	refresh()

func refresh():
	for sc in get_children():
		if sc is Line2D:
			continue
		var p_sc:String = Data.science_unlocks[sc.name].parent
		if sc.get_script():#A way of checking whether the node is a button
			sc.main_tree = self
			#parent_science
			if p_sc == "":
				continue
			if not game.science_unlocked[p_sc]:
				sc.modulate = Color(0.5, 0.5, 0.5, 1)
				sc.get_node("Panel/HBox/Texture").modulate = Color.black
				sc.get_node("Panel").mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				sc.modulate = Color.white
				sc.get_node("Panel/HBox/Texture").modulate = Color.white
				sc.get_node("Panel").mouse_filter = Control.MOUSE_FILTER_PASS
			sc.refresh()
		if not sc.name in ["SA", "RC"]:
			var p_n = get_node(p_sc)
			var l_n = get_node("L_%s" % [sc.name])
			l_n.position.x = p_n.rect_position.x + p_n.rect_size.x + 20
			get_node(sc.name).rect_position.x = l_n.position.x + 96 + 20
