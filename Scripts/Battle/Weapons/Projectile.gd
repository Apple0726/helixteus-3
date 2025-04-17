extends Area2D

signal end_turn

var battle_GUI
static var amount:int = 0
var speed:float
# Contrary to `speed`, `velocity_process_modifier` does not affect the initial velocity of damage labels
# Only used for `animations_sped_up` variable in Battle.gd
var velocity_process_modifier:float = 1.0
var damage:float
var shooter:BattleEntity
var weapon_accuracy:float
var ending_turn_delay:float
var end_turn_ready = false
var mass:float # For now only used to determine knockback when something is defeated by this projectile (so purely aesthetic)

func _ready() -> void:
	tree_exiting.connect(decrement_amount)
	amount += 1

func decrement_amount():
	amount -= 1
	if amount <= 0 and end_turn_ready:
		emit_signal("end_turn", ending_turn_delay)

func _physics_process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta * velocity_process_modifier
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		ending_turn_delay = 0.0
		queue_free()
