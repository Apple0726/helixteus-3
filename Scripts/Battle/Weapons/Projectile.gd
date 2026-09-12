extends Area2D

signal end_turn

var battle_scene
var battle_GUI
static var amount:int = 0
static var end_turn_ready = false
var speed:float
# Contrary to `speed`, `velocity_process_modifier` does not affect the initial velocity of damage labels
# Only used for `animations_sped_up` variable in Battle.gd
var velocity_process_modifier:float = 1.0
var damage:float
var shooter:BattleEntity
var weapon_accuracy:float
var ending_turn_delay:float
var mass:float # Used for determining how much projectiles with mass knock entities back
var crit_hit_mult:float = 1.0
var status_effects = {}
var buffs = {}
var trail_color:Color = Color.WHITE

var hit_sound_player:AudioStreamPlayer2D
var spawn_sound_player:AudioStreamPlayer2D

func _ready() -> void:
	amount += 1
	hit_sound_player = AudioStreamPlayer2D.new()
	add_child(hit_sound_player)
	hit_sound_player.bus = "SFX"
	hit_sound_player.max_polyphony = 8
	hit_sound_player.volume_db = -3.0
	spawn_sound_player = AudioStreamPlayer2D.new()
	add_child(spawn_sound_player)
	spawn_sound_player.stream = preload("res://Audio/SFX/projectile_shoot.wav")
	spawn_sound_player.bus = "SFX"
	spawn_sound_player.max_polyphony = 8
	hit_sound_player.volume_db = -9.0

func _physics_process(delta: float) -> void:
	position += speed * Vector2.from_angle(rotation) * delta * velocity_process_modifier
	if (position - Vector2(640, 360)).length_squared() > pow(1280, 2) + pow(720, 2):
		ending_turn_delay = 0.0
		remove_projectile()
		set_physics_process(false)

func check_boundary(area):
	if area.type == Battle.EntityType.BOUNDARY:
		ending_turn_delay = 0.0
		remove_projectile()
		return true
	return false

func remove_projectile():
	if not visible:
		return
	hide()
	amount -= 1
	if amount <= 0 and end_turn_ready:
		emit_signal("end_turn", ending_turn_delay)
		end_turn_ready = false
	if hit_sound_player.playing:
		await hit_sound_player.finished
	queue_free()
