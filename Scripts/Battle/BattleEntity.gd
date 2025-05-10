class_name BattleEntity
extends Node2D

signal next_turn

@onready var game = get_node("/root/Game")

@export var type:int

var METERS_PER_AGILITY:float
var PIXELS_PER_METER:float

var battle_scene:Node2D
var battle_GUI:BattleGUI
var turn_order_box:Button
var turn_number = 0

var lv:int
var HP:int
var total_HP:int
var attack:float
var defense:float
var accuracy:float
var agility:float:
	get:
		return agility
	set(value):
		agility = value
		agility_updated_callback()
var initiative:int
var go_through_movement_cost:float # in meters
var velocity:Vector2 = Vector2.ZERO:
	get:
		return velocity
	set(value):
		velocity = value
		update_velocity_arrow()
var movement_remaining:float # in meters
var total_movement_base:float # in meters. Includes permanent/static modifications from passive abilities, but does not include temporary modifications from (de)buffs
var total_movement:float # in meters, after all modifications

var moving_from_velocity = false # Used to determine whether to deal damage to an entity when this entity collides with it
var velocity_process_mult = 1.0
var collision_shape_radius:float
var draw_collision_shape = 0: # 0 = false, 1 = draw but no highlight, 2 = draw & highlight
	set(value):
		draw_collision_shape = value
		queue_redraw()

var attack_buff:float = 0.0
var defense_buff:float = 0.0
var accuracy_buff:float = 0.0
var agility_buff:float = 0.0:
	get:
		return agility_buff
	set(value):
		agility_buff = value
		agility_updated_callback()
var status_effects = {}
var status_effect_resistances = {}
var passive_abilities = []
var mass_mult:float = 1.0
var regen_per_turn = 0
var buff_decay_rate = 1.0
var debuff_decay_rate = 1.0
var status_effects_decay_rate = 1.0
var random_buff_timer_initial = INF
var random_buff_timer = INF
var aim_mult = 1.0
var physical_damage_mult = 1.0
var extra_attacks = 0

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
	default_tooltip_text += "\n@i \t%.1f" % (attack)
	if attack_buff > 0:
		default_tooltip_text += " + %.1f = %.1f" % [attack_buff, attack + attack_buff]
	elif attack_buff < 0:
		default_tooltip_text += " - %.1f = %.1f" % [abs(attack_buff), attack + attack_buff]
	default_tooltip_text += "\n@i \t%.1f" % (defense)
	if defense_buff > 0:
		default_tooltip_text += " + %.1f = %.1f" % [defense_buff, defense + defense_buff]
	elif defense_buff < 0:
		default_tooltip_text += " - %.1f = %.1f" % [abs(defense_buff), defense + defense_buff]
	default_tooltip_text += "\n@i \t%.1f" % (accuracy)
	if accuracy_buff > 0:
		default_tooltip_text += " + %.1f = %.1f" % [accuracy_buff, accuracy + accuracy_buff]
	elif accuracy_buff < 0:
		default_tooltip_text += " - %.1f = %.1f" % [abs(accuracy_buff), accuracy + accuracy_buff]
	default_tooltip_text += "\n@i \t%.1f" % (agility)
	if agility_buff > 0:
		default_tooltip_text += " + %.1f = %.1f" % [agility_buff, agility + agility_buff]
	elif agility_buff < 0:
		default_tooltip_text += " - %.1f = %.1f" % [abs(agility_buff), agility + agility_buff]
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
	if Battle.PassiveAbility.MORE_MASS in passive_abilities:
		mass_mult *= 2.0
	if Battle.PassiveAbility.FASTER_DEBUFF_STATUS_DISAPPEAR in passive_abilities:
		debuff_decay_rate = 2.0
		status_effects_decay_rate = 2.0
	if Battle.PassiveAbility.SLOWER_BUFF_DISAPPEAR in passive_abilities:
		buff_decay_rate = 0.5
	if Battle.PassiveAbility.HEAL_EVERY_TURN in passive_abilities:
		regen_per_turn = ceil(total_HP * 0.1)
	if Battle.PassiveAbility.EXTRA_MOVEMENT in passive_abilities:
		total_movement_base *= 1.5
	if Battle.PassiveAbility.RANDOM_3_BUFF in passive_abilities:
		random_buff_timer = 3
		random_buff_timer_initial = 3
	if Battle.PassiveAbility.INCREASED_AIM in passive_abilities:
		aim_mult *= 2.0
	if Battle.PassiveAbility.PHYSICAL_DAMAGE_RESISTANT in passive_abilities:
		physical_damage_mult = 0.75
	if Battle.PassiveAbility.STUN_FREEZE_IMMUNE:
		status_effect_resistances[Battle.StatusEffect.STUN] = 1.0
		status_effect_resistances[Battle.StatusEffect.FREEZE] = 1.0
	if Battle.PassiveAbility.BURN_CORRODING_IMMUNE:
		status_effect_resistances[Battle.StatusEffect.BURN] = 1.0
		status_effect_resistances[Battle.StatusEffect.CORRODING] = 1.0
	if Battle.PassiveAbility.WET_EXPOSED_IMMUNE:
		status_effect_resistances[Battle.StatusEffect.WET] = 1.0
		status_effect_resistances[Battle.StatusEffect.EXPOSED] = 1.0
	if Battle.PassiveAbility.RADIOACTIVE_IMMUNE:
		status_effect_resistances[Battle.StatusEffect.RADIOACTIVE] = 1.0

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
	turn_number += 1
	if is_instance_valid(turn_order_box):
		turn_order_box.get_node("AnimationPlayer").play("ChangeSize")
		turn_order_box.modulate.a = 1.0
	if regen_per_turn > 0:
		heal_entity(regen_per_turn)
	var burn_turns = status_effects[Battle.StatusEffect.BURN]
	if burn_turns > 0:
		damage_entity_status_effect(int(ceil(burn_turns * 0.05 * total_HP)))
		if HP <= 0:
			await get_tree().create_timer(0.5).timeout
			emit_signal("next_turn")
			return
	var energetic_turns = status_effects[Battle.StatusEffect.ENERGETIC]
	if energetic_turns > 0:
		extra_attacks = 1
		total_movement = total_movement_base * 1.25
	else:
		extra_attacks = 0
		total_movement = total_movement_base
	movement_remaining = total_movement
	random_buff_timer -= 1
	if Battle.PassiveAbility.BUFFS_AT_LOW_HP in passive_abilities and HP < 0.4:
		var buff_amount:int = remap(float(HP) / total_HP, 0.0, 0.4, 4.8 + lv / 5.0, 0)
		attack_buff = min(attack_buff + buff_amount, max(attack_buff, buff_amount))
		defense_buff = min(defense_buff + buff_amount, max(defense_buff, buff_amount))
		accuracy_buff = min(accuracy_buff + buff_amount, max(accuracy_buff, buff_amount))
		agility_buff = min(agility_buff + buff_amount, max(agility_buff, buff_amount))
		update_info_labels()
	if random_buff_timer <= 0:
		match randi() % 4:
			0:
				attack_buff += random_buff_timer_initial
			1:
				defense_buff += random_buff_timer_initial
			2:
				accuracy_buff += random_buff_timer_initial
			3:
				agility_buff += random_buff_timer_initial
		random_buff_timer = random_buff_timer_initial
		update_info_labels()
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
		status_effects[effect] = max(0, status_effects[effect] - status_effects_decay_rate)
	if attack_buff > 0:
		attack_buff = max(attack_buff - buff_decay_rate, 0.0)
	elif attack_buff < 0:
		attack_buff = min(attack_buff + debuff_decay_rate, 0.0)
	if defense_buff > 0:
		defense_buff = max(defense_buff - buff_decay_rate, 0.0)
	elif defense_buff < 0:
		defense_buff = min(defense_buff + debuff_decay_rate, 0.0)
	if accuracy_buff > 0:
		accuracy_buff = max(accuracy_buff - buff_decay_rate, 0.0)
	elif accuracy_buff < 0:
		accuracy_buff = min(accuracy_buff + debuff_decay_rate, 0.0)
	if agility_buff > 0:
		agility_buff = max(agility_buff - buff_decay_rate, 0.0)
	elif agility_buff < 0:
		agility_buff = min(agility_buff + debuff_decay_rate, 0.0)
	update_info_labels()

func _physics_process(delta: float) -> void:
	if moving_from_velocity:
		position += velocity * delta * velocity_process_mult


func end_turn():
	if extra_attacks > 0:
		extra_attacks -= 1
	else:
		if is_instance_valid(turn_order_box):
			turn_order_box.get_node("AnimationPlayer").play_backwards("ChangeSize")
		emit_signal("next_turn")

func agility_updated_callback():
	if has_node("CollisionShapeFinder/CollisionShape2D"):
		$CollisionShapeFinder/CollisionShape2D.shape.radius = (agility + agility_buff) * METERS_PER_AGILITY * PIXELS_PER_METER

func damage_entity_status_effect(damage: int):
	battle_scene.add_damage_text(false, position + Vector2.UP * 80.0, damage, false, Vector2.UP * 150.0)
	HP = max(HP - damage, 0)
	update_entity_HP()
	
func heal_entity(amount: int):
	battle_scene.add_damage_text(false, position + Vector2.UP * 80.0, -amount)
	HP = min(HP + amount, total_HP)
	update_entity_HP(Vector2.ZERO, true)
	
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
		var critical = randf() < weapon_data.get("crit_hit_chance", 0.02) * (10.0 if weapon_data.has("status_effects") and weapon_data.status_effects.has(Battle.StatusEffect.EXPOSED) else 1.0)
		if critical:
			actual_damage *= 2
		if Battle.PassiveAbility.PHYSICAL_DAMAGE_RESISTANT in passive_abilities and weapon_data.type == Battle.DamageType.PHYSICAL:
			actual_damage = ceil(actual_damage * 0.75)
		if weapon_data.has("nullify_damage_chance") and randf() < weapon_data.nullify_damage_chance:
			if float(actual_damage) / total_HP > 0.5:
				agility_buff -= 4
				status_effects[Battle.StatusEffect.STUN] += 2
			elif float(actual_damage) / total_HP > 0.35:
				agility_buff -= 3
			elif float(actual_damage) / total_HP > 0.2:
				agility_buff -= 2
			actual_damage = 0
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

func update_entity_HP(label_knockback: Vector2 = Vector2.ZERO, healed: bool = false):
	$Info/HP.value = HP
	if has_node("Sprite2D"):
		if healed:
			$Sprite2D.material.set_shader_parameter("flash_color", Color(0.7, 1.0, 0.7))
		else:
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
	$Info/Buffs/AttackLabel.text = ("+%s" % Helper.format_num(attack_buff)) if attack_buff > 0 else Helper.format_num(attack_buff)
	$Info/Buffs/AttackLabel["theme_override_colors/font_color"] = Color.GREEN if attack_buff > 0 else Color.RED
	$Info/Buffs/Defense.visible = defense_buff != 0
	$Info/Buffs/DefenseLabel.visible = defense_buff != 0
	$Info/Buffs/DefenseLabel.text = ("+%s" % Helper.format_num(defense_buff)) if defense_buff > 0 else Helper.format_num(defense_buff)
	$Info/Buffs/DefenseLabel["theme_override_colors/font_color"] = Color.GREEN if defense_buff > 0 else Color.RED
	$Info/Buffs/Accuracy.visible = accuracy_buff != 0
	$Info/Buffs/AccuracyLabel.visible = accuracy_buff != 0
	$Info/Buffs/AccuracyLabel.text = ("+%s" % Helper.format_num(accuracy_buff)) if accuracy_buff > 0 else Helper.format_num(accuracy_buff)
	$Info/Buffs/AccuracyLabel["theme_override_colors/font_color"] = Color.GREEN if accuracy_buff > 0 else Color.RED
	$Info/Buffs/Agility.visible = agility_buff != 0
	$Info/Buffs/AgilityLabel.visible = agility_buff != 0
	$Info/Buffs/AgilityLabel.text = ("+%s" % Helper.format_num(agility_buff)) if agility_buff > 0 else Helper.format_num(agility_buff)
	$Info/Buffs/AgilityLabel["theme_override_colors/font_color"] = Color.GREEN if agility_buff > 0 else Color.RED
	for effect in status_effects:
		if effect == Battle.StatusEffect.BURN:
			$Info/StatusEffects/BurnLabel.text = Helper.format_num(status_effects[effect])
		elif effect == Battle.StatusEffect.STUN:
			$Info/StatusEffects/StunLabel.text = Helper.format_num(status_effects[effect])
		elif effect == Battle.StatusEffect.EXPOSED:
			$Info/StatusEffects/ExposedLabel.text = Helper.format_num(status_effects[effect])
		elif effect == Battle.StatusEffect.RADIOACTIVE:
			$Info/StatusEffects/RadioactiveLabel.text = Helper.format_num(status_effects[effect])

func entity_defeated_callback():
	if is_instance_valid(turn_order_box):
		turn_order_box.get_node("AnimationPlayer").play("FadeOutAnim")
	if type == Battle.EntityType.ENEMY:
		battle_scene.HX_nodes.erase(self)
	elif type == Battle.EntityType.SHIP:
		battle_scene.ship_nodes.erase(self)

func update_velocity_arrow(offset: Vector2 = Vector2.ZERO):
	$VelocityArrow.scale = Vector2.ONE * (velocity + offset).length() / 100.0
	$VelocityArrow.rotation = (velocity + offset).angle()


func push_entity_attempt(agility_pusher: int, agility_pushee: int, position_difference_normalized: Vector2, velocity_difference: Vector2):
	return 1.0 / (1.0 + exp((agility_pusher - agility_pushee - abs(0.05 * position_difference_normalized.rotated(PI / 2.0).dot(velocity_difference)) + 9.2) / 5.8)) < randf()

func collide_with_entity(collider: BattleEntity, collidee: BattleEntity):
	var damage: float = 0.0
	var collider_mass = collider.get_mass()
	var collider_weapon_data = {
		"type":Battle.DamageType.PHYSICAL,
		"damage": collider_mass * collider.velocity.length_squared() * 0.00001,
		"shooter_attack":collider.attack,
		"weapon_accuracy":collider.accuracy,
		"orientation":collider.velocity.normalized(),
		"velocity":0.3 * collider.velocity,
	}
	var collidee_mass = collidee.get_mass()
	if collidee.damage_entity(collider_weapon_data):
		var collider_kinetic_energy = collider_mass * collider.velocity.length_squared()
		var collidee_velocity_gain = min(sqrt(collider_kinetic_energy / collidee_mass), collider.velocity.length())
		if not collidee.moving_from_velocity:
			var collidee_weapon_data = {
				"type":Battle.DamageType.PHYSICAL,
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

func get_mass():
	return remap(HP, 0.0, total_HP, total_HP * 0.66, total_HP) * mass_mult
