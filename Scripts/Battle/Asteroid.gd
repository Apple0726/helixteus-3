extends "BattleEntity.gd"

func take_turn():
	super()

func update_default_tooltip_text():
	default_tooltip_text = "@i \t%s / %s" % [HP, total_HP]


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	game.show_adv_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()
