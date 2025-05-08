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

func _physics_process(delta: float) -> void:
	super(delta)
	if position.x < -640.0 or position.x > 1920.0 or position.y < -360.0 or position.y > 1080.0:
		if battle_scene.animations_sped_up:
			remove_from_obstacles()
		else:
			var disappear_tween = create_tween().set_parallel(true)
			disappear_tween.tween_property($Sprite2D.material, "shader_parameter/alpha", 0.0, 0.5)
			disappear_tween.tween_property($VelocityArrow, "modulate:a", 0.0, 0.5)
			disappear_tween.tween_callback(remove_from_obstacles).set_delay(0.5)

func take_turn():
	super()
	decrement_status_effects_buffs()

func remove_from_obstacles():
	battle_scene.obstacle_nodes.erase(self)
	queue_free()

func _on_mouse_entered() -> void:
	if battle_GUI.action_selected in [battle_GUI.MOVE, battle_GUI.PUSH]:
		return
	refresh_default_tooltip_text()
	game.show_tooltip(default_tooltip_text, {"imgs": default_tooltip_icons})


func _on_mouse_exited() -> void:
	game.hide_tooltip()
