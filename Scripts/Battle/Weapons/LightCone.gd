extends Node2D

var damage:float
var shooter_attack:int
var target_angle_deviation:float
var targets = {}
var light_anim

func _ready() -> void:
	$RayCast2D.add_exception(get_parent())
	tree_exiting.connect(unhighlight_targets)
	update_cone()

func update_cone():
	unhighlight_targets()
	targets.clear()
	var light_polygon:PackedVector2Array = [Vector2.ZERO]
	var raycast_res = int(target_angle_deviation * 100.0)
	var mouse_pos = to_local(get_parent().battle_scene.mouse_position_global)
	for i in range(-raycast_res, raycast_res):
		var angle = atan2(mouse_pos.y, mouse_pos.x) + i / 100.0
		$RayCast2D.target_position = 5000.0 * Vector2.from_angle(angle)
		$RayCast2D.force_raycast_update()
		var hit_point = to_local($RayCast2D.get_collision_point())
		light_polygon.append(hit_point)
		var hit_target = $RayCast2D.get_collider()
		if hit_target not in targets and hit_target is BattleEntity:
			var weapon_data = {
				"damage":damage,
				"shooter_attack":shooter_attack,
				"weapon_accuracy":INF,
				"damage_label_initial_velocity":50.0 * Vector2.from_angle(angle),
			}
			if hit_target.has_node("Sprite2D") and hit_target.get_node("Sprite2D").material:
				hit_target.get_node("Sprite2D").material.set_shader_parameter("flash_color", Color.WHITE)
				hit_target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.8)
			targets[hit_target] = weapon_data
	light_polygon.append(Vector2.ZERO)
	$Polygon2D.polygon = light_polygon

func _input(event: InputEvent) -> void:
	if not light_anim and event is InputEventMouseMotion:
		update_cone()

func fire_light():
	for target in targets:
		target.damage_entity(targets[target])
	light_anim = create_tween()
	$Polygon2D.color.a = 1.0
	light_anim.tween_property($Polygon2D, "modulate:a", 0.0, 1.0)
	light_anim.tween_callback(queue_free)

func unhighlight_targets():
	for target in targets:
		if target.has_node("Sprite2D") and target.get_node("Sprite2D").material:
			target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.0)
