extends KinematicBody2D

var tween
var tween2
var float_height = 20
var trans_tween = Tween.TRANS_QUAD
var HP
var total_HP
var atk
var def
var MM_icon
var cave_ref
var timer:Timer
var check_distance_timer:Timer
var noticed_player:bool

func _ready():
	tween = Tween.new()
	tween2 = Tween.new()
	add_child(tween)
	add_child(tween2)
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()
	tween.connect("tween_all_completed", self, "on_tween_complete")
	tween2.connect("tween_all_completed", self, "on_tween2_complete")
	$HP.max_value = total_HP
	$HP.value = HP
	timer = Timer.new()
	add_child(timer)
	timer.start(1.0)
	timer.autostart = true
	timer.connect("timeout", self, "on_time_out")
	check_distance_timer = Timer.new()
	add_child(check_distance_timer)
	check_distance_timer.start(0.2)
	check_distance_timer.autostart = true
	check_distance_timer.connect("timeout", self, "check_distance")

func on_time_out():
	if noticed_player:
		var rand_rot = rand_range(0, PI/4)
		for i in range(0, 8):
			var rot = i * PI/4 + rand_rot
			cave_ref.add_proj(true, position, 15.0, rot, load("res://Graphics/Cave/Projectiles/enemy_bullet.png"), atk * 2.0)

func check_distance():
	if position.distance_to(cave_ref.rover.position) < 1250:
		if not noticed_player:
			noticed_player = true
	else:
		noticed_player = false

func on_tween_complete():
	tween2.interpolate_property(self, "position", position, position + Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween2.start()

func on_tween2_complete():
	tween.interpolate_property(self, "position", position, position - Vector2(0, float_height), 0.5, trans_tween, Tween.EASE_IN_OUT)
	tween.start()

func hit(damage:float):
	HP -= damage / def
	$HP.value = HP
	if HP <= 0:
		cave_ref.get_node("UI/Minimap").remove_child(MM_icon)
		get_parent().remove_child(self)
