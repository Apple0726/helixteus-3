extends "BattleEntity.gd"


func _ready() -> void:
	super()
	$CollisionShape2D.shape.radius = collision_shape_radius
	$Info/HP.position.x = -$Sprite2D.scale.x * 90.0 + 90.0
	$Info/Label.position.y = $Sprite2D.scale.x * 90.0 + 30.0
	$Info/StatusEffects.position.y = -$Sprite2D.scale.x * 90.0 - 60.0
	$Info/Buffs.position.y = $Sprite2D.scale.x * 90.0 + 60.0
	$Info/Icon.position.y = $Sprite2D.scale.x * 90.0 + 30.0
	status_effect_resistances[Battle.StatusEffect.BURN] = 1.0


func take_turn():
	super()
	decrement_status_effects_buffs()


func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	refresh_default_tooltip_text()
	game.show_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()
