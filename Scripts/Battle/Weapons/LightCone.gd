extends Node2D

var damage:float
var shooter_attack:int
var target_angle_deviation:float
var target_angle_deviation_visual:float
var targets = {}
var light_anim

func _ready() -> void:
	$RayCast2D.add_exception(get_parent())
	tree_exiting.connect(unhighlight_targets)
	update_cone(target_angle_deviation)

var cone_tween
func update_cone_animate():
	if cone_tween and cone_tween.is_running():
		cone_tween.kill()
	cone_tween = create_tween()
	cone_tween.tween_method(update_cone, target_angle_deviation_visual, target_angle_deviation, 0.15)
	
func update_cone(_target_angle_deviation_visual: float):
	target_angle_deviation_visual = _target_angle_deviation_visual
	unhighlight_targets()
	targets.clear()
	var light_polygon:PackedVector2Array = [Vector2.ZERO]
	var mouse_pos = to_local(get_parent().battle_scene.mouse_position_global)
	$Polygon2D.color.a = remap(target_angle_deviation_visual, 0.3 * PI, PI / 64.0, 0.1, 0.7)
	for i in range(-100, 100):
		var angle = atan2(mouse_pos.y, mouse_pos.x) + i * target_angle_deviation_visual / 100.0
		$RayCast2D.target_position = 5000.0 * Vector2.from_angle(angle)
		$RayCast2D.force_raycast_update()
		var hit_point = to_local($RayCast2D.get_collision_point())
		light_polygon.append(hit_point)
		var hit_target = $RayCast2D.get_collider()
		if hit_target is BattleEntity:
			var has_shader = hit_target.has_node("Sprite2D") and hit_target.get_node("Sprite2D").material
			if hit_target in targets:
				targets[hit_target].damage += damage / 200.0
				targets[hit_target].light_rays += 1
				targets[hit_target].damage_label_initial_velocity += 1.5 * Vector2.from_angle(angle)
				hit_target.override_tooltip_dict.light_intensity_mult = " * " + str(targets[hit_target].light_rays / 200.0)
				if has_shader:
					hit_target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.5 + targets[hit_target].light_rays / 400.0)
			else:
				var weapon_data = {
					"damage":damage / 200.0,
					"light_rays":1,
					"shooter_attack":shooter_attack,
					"weapon_accuracy":INF,
					"damage_label_initial_velocity":1.5 * Vector2.from_angle(angle),
					"crit_hit_chance":0.0,
				}
				targets[hit_target] = weapon_data
				hit_target.override_tooltip_dict.light_intensity_mult = " * " + str(1 / 200.0)
				hit_target.override_tooltip_dict.light_intensity_mult_info = " (" + tr("LIGHT_INTENSITY") + ")"
				if has_shader:
					hit_target.get_node("Sprite2D").material.set_shader_parameter("flash_color", Color.WHITE)
					hit_target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.5)
	light_polygon.append(Vector2.ZERO)
	$Polygon2D.polygon = light_polygon

func _input(event: InputEvent) -> void:
	if not light_anim and event is InputEventMouseMotion:
		update_cone(target_angle_deviation)

func fire_light(fade_delay: float):
	for target in targets:
		target.damage_entity(targets[target])
	light_anim = create_tween()
	$Polygon2D.color.a = 1.0
	light_anim.tween_property($Polygon2D, "modulate:a", 0.0, fade_delay)
	light_anim.tween_callback(queue_free)

func unhighlight_targets():
	for target in targets:
		if target.has_node("Sprite2D") and target.get_node("Sprite2D").material:
			target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.0)
