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
		if sc.available:
			if not sc.infinite_research and sc.sc_lv >= sc.num_levels:
				sc.get_node("Highlight").show()
				sc.get_node("Highlight")["theme_override_styles/panel"].border_color = Color.PURPLE
			elif game.SP >= sc.sc_cost:
				sc.get_node("Highlight").show()
				sc.get_node("Highlight")["theme_override_styles/panel"].border_color = Color(1.0, 1.0, 1.0, 0.5)
			else:
				sc.get_node("Highlight").hide()
