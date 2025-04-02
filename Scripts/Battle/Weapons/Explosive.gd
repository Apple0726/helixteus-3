extends Area2D

signal end_turn

static var amount:int = 0
var speed:float
# Contrary to `speed`, `velocity_process_modifier` does not affect the initial velocity of damage labels
# Only used for `animations_sped_up` variable in Battle.gd
var velocity_process_modifier:float = 1.0
var damage:float
var shooter_attack:int
var weapon_accuracy:float
var entities_inside_explosion_AoE:Array = []
var AoE_radius:float
var battle_GUI
var ending_turn_delay:float

func _ready() -> void:
	$ExplosionAoE/CollisionShape2D.shape.radius = AoE_radius
	area_entered.connect(_on_area_entered)
	tree_exiting.connect(decrement_amount)
	$ExplosionAoE.area_entered.connect(_on_explosionAoE_entered)
	$ExplosionAoE.area_exited.connect(_on_explosionAoE_exited)
	amount += 1

func decrement_amount():
	amount -= 1
	if amount <= 0:
		emit_signal("end_turn", ending_turn_delay)

func _on_explosionAoE_entered(area: Area2D):
	entities_inside_explosion_AoE.append(area)

func _on_explosionAoE_exited(area: Area2D):
	entities_inside_explosion_AoE.erase(area)

func _physics_process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta * velocity_process_modifier
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		ending_turn_delay = 0.0
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"damage":damage,
		"shooter_attack":shooter_attack,
		"weapon_accuracy":weapon_accuracy,
		"orientation":Vector2.from_angle(rotation),
		"damage_label_initial_velocity":0.5 * speed * Vector2.from_angle(rotation),
	}
	if area.damage_entity(weapon_data):
		if area.type == 2:
			ending_turn_delay = 0.0
			queue_free()
			return
		for area_in_AoE in entities_inside_explosion_AoE:
			if area_in_AoE is BattleEntity and area_in_AoE != area:
				var dist_from_point_blank = (area_in_AoE.position - position).length()
				var AoE_weapon_data = {
					"damage":damage * remap(dist_from_point_blank, 0.0, AoE_radius, 1.0, 0.2),
					"shooter_attack":shooter_attack,
					"weapon_accuracy":INF,
					"damage_label_initial_velocity":200.0 * (area_in_AoE.position - position).normalized(),
				}
				area_in_AoE.damage_entity(AoE_weapon_data)
		if Settings.screen_shake:
			get_node("/root/Game/Camera2D/Screenshake").start(0.5,15,4)
		$AnimationPlayer.play("Explode")
		battle_GUI.flash_screen(0.3, 0.2)
		set_physics_process(false)
		$AnimationPlayer.animation_finished.connect(func(anim_name): queue_free())
