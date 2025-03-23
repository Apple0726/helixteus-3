extends "BattleEntity.gd"


func _ready() -> void:
	$CollisionShape2D.shape.radius = collision_shape_radius
	$Info/HP.position.x = -$Sprite2D.scale.x * 90.0 + 90.0
	$Info/Label.position.y = $Sprite2D.scale.x * 90.0 + 90.0
	$Info/Icon.position.y = $Sprite2D.scale.x * 90.0 + 90.0


func take_turn():
	super()


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	refresh_default_tooltip_text()
	game.show_adv_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()
