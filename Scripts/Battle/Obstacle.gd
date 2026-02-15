extends "BattleEntity.gd"


func _ready() -> void:
	super()
	type = Battle.EntityType.OBSTACLE
	$Info/HP.max_value = total_HP
	$Info/HP.value = HP
	var sprite_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x
	$CollisionShape2D.shape.radius = collision_shape_radius
	$Info/HP.position.x = -sprite_width * 0.5 - 20.0
	$Info/HP.position.y = sprite_width * 0.4
	$Info/HP.size.x = sprite_width * 0.8
	$Info/Label.position.y = sprite_width * 0.5 + 20
	$Info/StatusEffects.position.x = -sprite_width * 0.5 - 11.0
	$Info/StatusEffects.position.y = -sprite_width * 0.5
	$Info/Buffs.position.y = sprite_width * 0.5 + 20
	$Info/Icon.position.y = sprite_width * 0.5 + 20
	$Info/Icon.texture = null
	$Info/Label.text = ""
	status_effect_resistances[Battle.StatusEffect.BURN] = 1.0
	status_effect_resistances[Battle.StatusEffect.STUN] = 1.0
	for effect in Battle.StatusEffect.N:
		if not effect in status_effect_resistances:
			status_effect_resistances[effect] = 0.0
	$Sprite2D.material.set_shader_parameter("starlight_angle", battle_scene.starlight_angle - $Sprite2D.rotation)
	$Sprite2D.material.set_shader_parameter("starlight_color", battle_scene.average_starlight_color)
	$Sprite2D.material.set_shader_parameter("starlight_energy", battle_scene.starlight_energy)

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
