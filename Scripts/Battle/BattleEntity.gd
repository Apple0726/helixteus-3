class_name BattleEntity
extends Node2D

signal next_turn

@onready var game = get_node("/root/Game")

@export var type:int

var METERS_PER_AGILITY:float
var PIXELS_PER_METER:float

var battle_scene:Node2D
var battle_GUI:BattleGUI

var lv:int
var HP:int
var total_HP:int
var attack:int
var defense:int
var accuracy:int
var agility:int:
	get:
		return agility
	set(value):
		agility = value
		agility_updated_callback()
var initiative:int
var turn_index:int = -1
var go_through_movement_cost:float # in meters
var velocity:Vector2 = Vector2.ZERO:
	get:
		return velocity
	set(value):
		velocity = value
		update_velocity_arrow()
var moving_from_velocity = false # Used to determine whether to deal damage to an entity when this entity collides with it
var velocity_process_mult = 1.0
var collision_shape_radius:float
var draw_collision_shape = 0: # 0 = false, 1 = draw but no highlight, 2 = draw & highlight
	set(value):
		draw_collision_shape = value
		queue_redraw()

var attack_buff:int = 0
var defense_buff:int = 0
var accuracy_buff:int = 0
var agility_buff:int = 0:
	get:
		return agility_buff
	set(value):
		agility_buff = value
		agility_updated_callback()
var status_effects = {}
var status_effect_resistances = {}

var default_tooltip_text:String
var override_tooltip_text:String = ""
var default_override_tooltip_dict = {
	"light_intensity_mult": "",
	"light_intensity_mult_info": "",
}
var default_tooltip_icons = [Data.HP_icon, Data.attack_icon, Data.defense_icon, Data.accuracy_icon, Data.agility_icon]
var override_tooltip_dict:Dictionary
var override_tooltip_icons = [Data.attack_icon, Data.defense_icon, Data.accuracy_icon, Data.agility_icon]

func _ready() -> void:
	override_tooltip_dict = default_override_tooltip_dict.duplicate()
	if has_node("Info/Initiative"):
		$Info/Initiative.modulate.a = 0.0
	refresh_default_tooltip_text()
	if type != Battle.EntityType.BOUNDARY:
		self.area_entered.connect(on_collide)
		$Info/StatusEffects/Burn.mouse_entered.connect(game.show_tooltip.bind(tr("BURN_DESC")))
		$Info/StatusEffects/Burn.mouse_exited.connect(game.hide_tooltip)
		$Info/StatusEffects/Stun.mouse_entered.connect(game.show_tooltip.bind(tr("STUN_DESC")))
		$Info/StatusEffects/Stun.mouse_exited.connect(game.hide_tooltip)
		$Info/StatusEffects/Exposed.mouse_entered.connect(game.show_tooltip.bind(tr("EXPOSED_DESC")))
		$Info/StatusEffects/Exposed.mouse_exited.connect(game.hide_tooltip)
		$Info/StatusEffects/Radioactive.mouse_entered.connect(game.show_tooltip.bind(tr("RADIOACTIVE_DESC")))
		$Info/StatusEffects/Radioactive.mouse_exited.connect(game.hide_tooltip)
		for effect in Battle.StatusEffect.N:
			status_effects[effect] = 0
			status_effect_resistances[effect] = 0.0

func _draw() -> void:
	if is_instance_valid(battle_scene) and type != Battle.EntityType.BOUNDARY:
		if draw_collision_shape == 1:
			draw_circle(Vector2.ZERO, collision_shape_radius + battle_GUI.ship_node.collision_shape_radius + 2.0, Color(1.0, 0.6, 0.0, 0.2), true, -1.0)
		elif draw_collision_shape == 2:
			draw_circle(Vector2.ZERO, collision_shape_radius + battle_GUI.ship_node.collision_shape_radius + 2.0, Color(1.0, 0.6, 0.0, 0.8), true, -1.0)

func refresh_default_tooltip_text():
	default_tooltip_text = "@i \t%s / %s" % [HP, total_HP]
	default_tooltip_text += "\n@i \t%s" % attack
	if attack_buff > 0:
		default_tooltip_text += " + " + str(attack_buff) + " = " + str(attack + attack_buff)
	elif attack_buff < 0:
		default_tooltip_text += " - " + str(abs(attack_buff)) + " = " + str(attack + attack_buff)
	default_tooltip_text += "\n@i \t%s" % defense
	if defense_buff > 0:
		default_tooltip_text += " + " + str(defense_buff) + " = " + str(defense + defense_buff)
	elif defense_buff < 0:
		default_tooltip_text += " - " + str(abs(defense_buff)) + " = " + str(defense + defense_buff)
	default_tooltip_text += "\n@i \t%s" % accuracy
	if accuracy_buff > 0:
		default_tooltip_text += " + " + str(accuracy_buff) + " = " + str(accuracy + accuracy_buff)
	elif accuracy_buff < 0:
		default_tooltip_text += " - " + str(abs(accuracy_buff)) + " = " + str(accuracy + accuracy_buff)
	default_tooltip_text += "\n@i \t%s" % agility
	if agility_buff > 0:
		default_tooltip_text += " + " + str(agility_buff) + " = " + str(agility + agility_buff)
	elif agility_buff < 0:
		default_tooltip_text += " - " + str(abs(agility_buff)) + " = " + str(agility + agility_buff)
	if velocity != Vector2.ZERO:
		default_tooltip_text += "\nv = " + ("(%.1f, %.1f) m/s\n|v| = %.1f m/s" % [velocity.x, velocity.y, velocity.length()])
	
func initialize_stats(data:Dictionary):
	lv = data.lv
	HP = data.HP
	total_HP = data.HP
	attack = data.attack
	defense = data.defense
	accuracy = data.accuracy
	agility = data.agility

func roll_initiative():
	var range:int = 2 + log(randf()) / log(0.2)
	initiative = randi_range(agility - range, agility + range)

func show_initiative(_initiative: int):
	$Info/Initiative.text = tr("INITIATIVE") + ": " + str(_initiative)
	var tween = create_tween()
	tween.tween_property($Info/Initiative, "modulate:a", 1.0, 0.5)
	tween.tween_property($Info/Initiative, "modulate:a", 0.0, 1.0).set_delay(2.0)
	create_tween().tween_property($Info/Initiative, "position:y", $Info/Initiative.position.y - 15.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

func take_turn():
	if turn_index != -1:
		battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("ChangeSize")
		battle_GUI.turn_order_hbox.get_child(turn_index).modulate.a = 1.0
	var burn_turns = status_effects[Battle.StatusEffect.BURN]
	if burn_turns > 0:
		damage_entity_status_effect(int(ceil(burn_turns * 0.05 * total_HP)))
	if velocity != Vector2.ZERO:
		moving_from_velocity = true
		if battle_scene.animations_sped_up:
			velocity_process_mult = 5.0
			await get_tree().create_timer(0.2).timeout
		else:
			velocity_process_mult = 1.0
			await get_tree().create_timer(1.0).timeout
		moving_from_velocity = false

func decrement_status_effects_buffs():
	for effect in status_effects:
		status_effects[effect] = max(0, status_effects[effect] - 1)
	attack_buff += -signi(attack_buff)
	defense_buff += -signi(defense_buff)
	accuracy_buff += -signi(accuracy_buff)
	agility_buff += -signi(agility_buff)
	update_info_labels()

func _physics_process(delta: float) -> void:
	if moving_from_velocity:
		position += velocity * delta * velocity_process_mult


func end_turn():
	battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play_backwards("ChangeSize")
	emit_signal("next_turn")

func agility_updated_callback():
	if has_node("CollisionShapeFinder/CollisionShape2D"):
		$CollisionShapeFinder/CollisionShape2D.shape.radius = (agility + agility_buff) * METERS_PER_AGILITY * PIXELS_PER_METER

func damage_entity_status_effect(damage: int):
	battle_scene.add_damage_text(false, position + Vector2.UP * 80.0, damage, false, Vector2.UP * 150.0)
	HP = max(HP - damage, 0)
	update_entity_HP()
	
func damage_entity(weapon_data: Dictionary):
	var dodged = 1.0 / (1.0 + exp((weapon_data.weapon_accuracy - agility - agility_buff - abs(0.1 * velocity.rotated(PI / 2.0).dot(weapon_data.get("orientation", Vector2.ZERO))) + 9.2) / 5.8)) > randf()
	if dodged:
		battle_scene.add_damage_text(true, position)
	else:
		var damage_multiplier:float
		var attack_defense_difference:int = weapon_data.shooter_attack - defense - defense_buff
		if attack_defense_difference >= 0:
			damage_multiplier = attack_defense_difference * 0.125 + 1.0
		else:
			damage_multiplier = 1.0 / (1.0 - 0.125 * attack_defense_difference)
		var actual_damage:int = max(1, weapon_data.damage * damage_multiplier)
		var critical = randf() < weapon_data.get("crit_hit_chance", 0.02)
		if critical:
			actual_damage *= 2
		battle_scene.add_damage_text(false, position, actual_damage, critical, 0.3 * weapon_data.get("velocity", Vector2.ZERO) * sqrt(weapon_data.get("mass", 0.0)))
		HP = max(HP - actual_damage, 0)
		var knockback = weapon_data.get("knockback", Vector2.ZERO)
		if knockback != Vector2.ZERO:
			if critical:
				velocity *= 2.0
			velocity += knockback
		var label_knockback = weapon_data.velocity.normalized() * weapon_data.get("mass", 0.0) * 5.0 / total_HP
		if label_knockback.length() > weapon_data.velocity.length():
			label_knockback = label_knockback.normalized() * weapon_data.velocity.length()
		update_entity_HP(label_knockback)
		if HP > 0:
			if weapon_data.has("status_effects"):
				for effect in weapon_data.status_effects:
					if randf() > status_effect_resistances[effect]:
						status_effects[effect] += weapon_data.status_effects[effect]
			if weapon_data.has("buffs"):
				for buff in weapon_data.buffs:
					self["%s_buff" % buff] += weapon_data.buffs[buff]
			update_info_labels()
	return not dodged

func update_entity_HP(label_knockback: Vector2 = Vector2.ZERO):
	$Info/HP.value = HP
	if has_node("Sprite2D"):
		$Sprite2D.material.set_shader_parameter("flash_color", Color.RED)
		$Sprite2D.material.set_shader_parameter("flash", 1.0)
	if HP <= 0:
		self.call_deferred("set_monitoring", false)
		self.call_deferred("set_monitorable", false)
		var label_knockback_tween = create_tween().set_parallel()
		label_knockback_tween.tween_property($Info, "modulate:a", 0.0, 1.0)
		label_knockback_tween.tween_property(self, "position", position + label_knockback, 2.0)
		label_knockback_tween.tween_property($Sprite2D.material, "shader_parameter/alpha", 0.0, 1.0).set_delay(1.0)
		label_knockback_tween.tween_callback(queue_free).set_delay(2.0)
		label_knockback_tween.set_speed_scale(5.0 if battle_scene.animations_sped_up else 1.0)
		entity_defeated_callback()
	else:
		if has_node("Sprite2D"):
			create_tween().tween_property($Sprite2D.material, "shader_parameter/flash", 0.0, 0.4)

func update_info_labels():
	$Info/StatusEffects/Burn.visible = status_effects[Battle.StatusEffect.BURN] > 0
	$Info/StatusEffects/BurnLabel.visible = status_effects[Battle.StatusEffect.BURN] > 0
	$Info/StatusEffects/Stun.visible = status_effects[Battle.StatusEffect.STUN] > 0
	$Info/StatusEffects/StunLabel.visible = status_effects[Battle.StatusEffect.STUN] > 0
	$Info/StatusEffects/Exposed.visible = status_effects[Battle.StatusEffect.EXPOSED] > 0
	$Info/StatusEffects/ExposedLabel.visible = status_effects[Battle.StatusEffect.EXPOSED] > 0
	$Info/StatusEffects/Radioactive.visible = status_effects[Battle.StatusEffect.RADIOACTIVE] > 0
	$Info/StatusEffects/RadioactiveLabel.visible = status_effects[Battle.StatusEffect.RADIOACTIVE] > 0
	$Info/Buffs/Attack.visible = attack_buff != 0
	$Info/Buffs/AttackLabel.visible = attack_buff != 0
	$Info/Buffs/AttackLabel.text = ("+%s" % attack_buff) if attack_buff > 0 else str(attack_buff)
	$Info/Buffs/AttackLabel["theme_override_colors/font_color"] = Color.GREEN if attack_buff > 0 else Color.RED
	$Info/Buffs/Defense.visible = defense_buff != 0
	$Info/Buffs/DefenseLabel.visible = defense_buff != 0
	$Info/Buffs/DefenseLabel.text = ("+%s" % defense_buff) if defense_buff > 0 else str(defense_buff)
	$Info/Buffs/DefenseLabel["theme_override_colors/font_color"] = Color.GREEN if defense_buff > 0 else Color.RED
	$Info/Buffs/Accuracy.visible = accuracy_buff != 0
	$Info/Buffs/AccuracyLabel.visible = accuracy_buff != 0
	$Info/Buffs/AccuracyLabel.text = ("+%s" % accuracy_buff) if accuracy_buff > 0 else str(accuracy_buff)
	$Info/Buffs/AccuracyLabel["theme_override_colors/font_color"] = Color.GREEN if accuracy_buff > 0 else Color.RED
	$Info/Buffs/Agility.visible = agility_buff != 0
	$Info/Buffs/AgilityLabel.visible = agility_buff != 0
	$Info/Buffs/AgilityLabel.text = ("+%s" % agility_buff) if agility_buff > 0 else str(agility_buff)
	$Info/Buffs/AgilityLabel["theme_override_colors/font_color"] = Color.GREEN if agility_buff > 0 else Color.RED
	for effect in status_effects:
		if effect == Battle.StatusEffect.BURN:
			$Info/StatusEffects/BurnLabel.text = str(status_effects[effect])
		elif effect == Battle.StatusEffect.STUN:
			$Info/StatusEffects/StunLabel.text = str(status_effects[effect])
		elif effect == Battle.StatusEffect.EXPOSED:
			$Info/StatusEffects/ExposedLabel.text = str(status_effects[effect])
		elif effect == Battle.StatusEffect.RADIOACTIVE:
			$Info/StatusEffects/RadioactiveLabel.text = str(status_effects[effect])

func entity_defeated_callback():
	if type == Battle.EntityType.ENEMY:
		battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("FadeOutAnim")
		battle_scene.initiative_order.remove_at(turn_index)
		if turn_index < battle_scene.whose_turn_is_it_index:
			battle_scene.whose_turn_is_it_index -= 1
		battle_scene.HX_nodes.erase(self)
	elif type == Battle.EntityType.SHIP:
		battle_GUI.turn_order_hbox.get_child(turn_index).get_node("AnimationPlayer").play("FadeOutAnim")
		battle_scene.initiative_order.remove_at(turn_index)
		if turn_index < battle_scene.whose_turn_is_it_index:
			battle_scene.whose_turn_is_it_index -= 1
		battle_scene.ship_nodes.erase(self)

func update_velocity_arrow(offset: Vector2 = Vector2.ZERO):
	#print(velocity, offset)
	$VelocityArrow.scale = Vector2.ONE * (velocity + offset).length() / 100.0
	$VelocityArrow.rotation = (velocity + offset).angle()


func push_entity_attempt(agility_pusher: int, agility_pushee: int, position_difference: Vector2, velocity_difference: Vector2):
	return 1.0 / (1.0 + exp((agility_pusher - agility_pushee - abs(0.1 * position_difference.rotated(PI / 2.0).dot(velocity_difference)) + 9.2) / 5.8)) > randf()

func collide_with_entity(collider: BattleEntity, collidee: BattleEntity):
	var damage: float = 0.0
	var collider_mass = remap(collider.HP, 0.0, collider.total_HP, collider.total_HP * 0.66, collider.total_HP)
	var collider_weapon_data = {
		"damage": collider_mass * collider.velocity.length_squared() * 0.00001,
		"shooter_attack":collider.attack,
		"weapon_accuracy":collider.accuracy,
		"orientation":collider.velocity.normalized(),
		"velocity":0.3 * collider.velocity,
	}
	var collidee_mass = remap(collidee.HP, 0.0, collidee.total_HP, collidee.total_HP * 0.66, collidee.total_HP)
	if collidee.damage_entity(collider_weapon_data):
		var collider_kinetic_energy = collider_mass * collider.velocity.length_squared()
		var collidee_velocity_gain = min(sqrt(collider_kinetic_energy / collidee_mass), collider.velocity.length())
		if not collidee.moving_from_velocity:
			var collidee_weapon_data = {
				"damage": collidee_mass * collider.velocity.length_squared() * 0.00001,
				"shooter_attack":collidee.attack,
				"weapon_accuracy":INF,
				"orientation":collidee.velocity.normalized(),
				"velocity":Vector2.ZERO,
			}
			collider.damage_entity(collidee_weapon_data)
			if collidee.velocity == Vector2.ZERO:
				collidee.velocity = collider.velocity.normalized() * collidee_velocity_gain
			else:
				collidee.velocity += collidee.velocity.normalized() * collidee_velocity_gain
		var velocity_loss = sqrt(collidee_mass * pow(collidee_velocity_gain, 2) / collider_mass)
		if velocity_loss > collider.velocity.length():
			collider.velocity = Vector2.ZERO
		else:
			collider.velocity -= collider.velocity.normalized() * velocity_loss
	
func on_collide(area):
	if type == Battle.EntityType.BOUNDARY or area.type == Battle.EntityType.BOUNDARY:
		return
	if moving_from_velocity:
		collide_with_entity(self, area)
	elif area.moving_from_velocity:
		collide_with_entity(area, self)
