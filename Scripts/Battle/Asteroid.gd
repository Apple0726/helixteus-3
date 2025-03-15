extends "BattleEntity.gd"

func take_turn():
	self.monitoring = true
	super()
	self.monitoring = false


func _on_area_entered(area: Area2D) -> void:
	print("collision")

func update_default_tooltip_text():
	default_tooltip_text = "@i \t%s / %s" % [HP, total_HP]


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	game.show_tooltip(default_tooltip_text)


func _on_mouse_exited() -> void:
	game.hide_tooltip()
