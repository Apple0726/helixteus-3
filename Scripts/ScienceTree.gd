extends Node2D

@onready var game = get_node('/root/Game')

var available_sciences = []

func _ready():
	for sc in $Control.get_children():
		sc.main_tree = self
	refresh()

func refresh():
	available_sciences.clear()
	for sc in $Control.get_children():
		sc.refresh()
		if sc.available:
			available_sciences.append(sc)

func _process(delta: float) -> void:
	for sc in available_sciences:
		if sc.available and sc.infinite_research or sc.sc_lv < sc.num_levels:
			if game.SP >= sc.sc_cost:
				sc.get_node("Highlight").show()
				sc.get_node("Highlight")["theme_override_styles/panel"].border_color = Color(1.0, 1.0, 1.0, 0.5)
				sc.get_node("CostLabel")["theme_override_colors/default_color"] = Color.GREEN
			else:
				sc.get_node("Highlight").hide()
				sc.get_node("CostLabel")["theme_override_colors/default_color"] = Color.RED
