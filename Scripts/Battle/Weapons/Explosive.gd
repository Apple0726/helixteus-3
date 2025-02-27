extends Area2D

var speed:float
var damage:float
var shooter_attack:int
var weapon_accuracy:float
var entities_inside_explosion_AoE:Array = []
var AoE_radius:float

func _ready() -> void:
	$ExplosionAoE/CollisionShape2D.shape.radius = AoE_radius
	area_entered.connect(_on_area_entered)
	$ExplosionAoE.area_entered.connect(_on_explosionAoE_entered)
	$ExplosionAoE.area_exited.connect(_on_explosionAoE_exited)

func _on_explosionAoE_entered(area: Area2D):
	entities_inside_explosion_AoE.append(area)

func _on_explosionAoE_exited(area: Area2D):
	entities_inside_explosion_AoE.erase(area)

func _process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var weapon_data = {
		"damage":damage,
		"shooter_attack":shooter_attack,
		"weapon_accuracy":weapon_accuracy,
		"damage_label_initial_velocity":0.5 * speed * Vector2.from_angle(rotation),
	}
	if area.damage_entity(weapon_data):
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
		queue_free()
