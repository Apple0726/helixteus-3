extends Node2D

var damage:float
var shooter:BattleEntity
var emission_cone_angle:float
var emission_cone_angle_visual:float
var weapon_datas = {}
var light_anim

func _ready() -> void:
	$RayCast2D.add_exception(get_parent())
	tree_exiting.connect(unhighlight_targets)
	update_cone(emission_cone_angle)

var cone_tween
func update_cone_animate():
	if cone_tween and cone_tween.is_running():
		cone_tween.kill()
	cone_tween = create_tween()
	cone_tween.tween_method(update_cone, emission_cone_angle_visual, emission_cone_angle, 0.15)
	
func update_cone(_emission_cone_angle_visual: float):
	emission_cone_angle_visual = _emission_cone_angle_visual
	unhighlight_targets()
	weapon_datas.clear()
	var light_polygon:PackedVector2Array = [Vector2.ZERO]
	var mouse_pos = to_local(get_parent().battle_scene.mouse_position_global)
	$Polygon2D.color.a = remap(emission_cone_angle_visual, 0.3 * PI, PI / 64.0, 0.1, 0.7)
	for i in range(-100, 100):
		var angle = atan2(mouse_pos.y, mouse_pos.x) + i * emission_cone_angle_visual / 100.0
		$RayCast2D.target_position = 5000.0 * Vector2.from_angle(angle)
		var hit_point:Vector2
		$RayCast2D.clear_exceptions()
		while true:
			$RayCast2D.force_raycast_update()
			hit_point = to_local($RayCast2D.get_collision_point())
			var hit_target = $RayCast2D.get_collider()
			add_weapon_data(hit_target, angle)
			if shooter.light_levels[1] >= 3:
				if hit_target is BattleEntity and hit_target.type == Battle.EntityType.BOUNDARY:
					break
				$RayCast2D.add_exception(hit_target)
			else:
				break
		light_polygon.append(hit_point)
		
	light_polygon.append(Vector2.ZERO)
	$Polygon2D.polygon = light_polygon

func add_weapon_data(hit_target, angle):
	var has_shader = hit_target.has_node("Sprite2D") and hit_target.get_node("Sprite2D").material
	if hit_target in weapon_datas:
		weapon_datas[hit_target].damage += damage / 200.0
		weapon_datas[hit_target].light_rays += 1
		if weapon_datas[hit_target].light_rays > 100: # If more than half of all light rays hit the same target, give stronger debuff/status effects
			weapon_datas[hit_target].buffs.accuracy = -3
			if weapon_datas[hit_target].buffs.has("attack"):
				weapon_datas[hit_target].buffs.attack = -3
			if weapon_datas[hit_target].status_effects.has(Battle.StatusEffect.EXPOSED):
				weapon_datas[hit_target].status_effects[Battle.StatusEffect.EXPOSED] = 3.0
		weapon_datas[hit_target].velocity += 1.5 * Vector2.from_angle(angle)
		hit_target.override_tooltip_dict.light_intensity_mult = " * " + str(weapon_datas[hit_target].light_rays / 200.0)
		if has_shader:
			hit_target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.5 + weapon_datas[hit_target].light_rays / 400.0)
	else:
		var weapon_data = {
			"type":Battle.DamageType.EMG,
			"damage":damage / 200.0,
			"light_rays":1,
			"shooter_attack":shooter.attack + shooter.attack_buff,
			"weapon_accuracy":INF,
			"velocity":1.5 * Vector2.from_angle(angle),
			"crit_hit_chance":0.0,
			"status_effects":{},
			"buffs":{"accuracy":-1},
		}
		if shooter.type == Battle.EntityType.SHIP:
			if shooter.light_levels[0] >= 4:
				weapon_data.status_effects[Battle.StatusEffect.EXPOSED] = 1.0
			if shooter.light_levels[0] >= 2:
				weapon_data.buffs.attack = -1
		weapon_datas[hit_target] = weapon_data
		hit_target.override_tooltip_dict.light_intensity_mult = " * " + str(1 / 200.0)
		hit_target.override_tooltip_dict.light_intensity_mult_info = " (" + tr("LIGHT_INTENSITY") + ")"
		if has_shader:
			hit_target.get_node("Sprite2D").material.set_shader_parameter("flash_color", Color.WHITE)
			hit_target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.5)
	
func _input(event: InputEvent) -> void:
	if not light_anim and event is InputEventMouseMotion:
		update_cone(emission_cone_angle)

func fire_light(fade_delay: float):
	for target in weapon_datas:
		target.damage_entity(weapon_datas[target])
	light_anim = create_tween()
	$Polygon2D.color.a = 1.0
	light_anim.tween_property($Polygon2D, "modulate:a", 0.0, fade_delay)
	light_anim.tween_callback(queue_free)

func unhighlight_targets():
	for target in weapon_datas:
		if target.has_node("Sprite2D") and target.get_node("Sprite2D").material:
			target.get_node("Sprite2D").material.set_shader_parameter("flash", 0.0)
