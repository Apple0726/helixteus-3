extends Node2D

onready var game = get_node('/root/Game')
var sc_over:String = ""

func _ready():
	refresh(self)

func refresh(child):
	for sc in child.get_children():
		if sc.get_script():#A way of checking whether the node is a button
			sc.main_tree = self
		if sc.get_index() == 0:
			continue
		if sc is ColorRect:
			var sc_name:String = $HBoxContainer.get_child(sc.get_index() - 1).name
			if not game.science_unlocked[sc_name]:
				sc.modulate = Color(0.5, 0.5, 0.5, 1)
			else:
				sc.modulate = Color.white
		elif sc is HBoxContainer:
			refresh(sc)
		elif sc.get_script():
			var sc_name:String = $HBoxContainer.get_child(sc.get_index() - 2).name
			if not game.science_unlocked[sc_name]:
				sc.modulate = Color(0.5, 0.5, 0.5, 1)
				sc.get_node("Panel/HBox/Texture").modulate = Color.black
				sc.get_node("Panel").mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				sc.modulate = Color.white
				sc.get_node("Panel/HBox/Texture").modulate = Color.white
				sc.get_node("Panel").mouse_filter = Control.MOUSE_FILTER_PASS
			sc.refresh()
