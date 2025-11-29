extends Node2D

var weapon_type:int
var target_angle:float
var target_angle_max_deviation:float
var target_angle_max_deviation_visual:float
var aim_accuracy_transparency:float
var length:float
var ship_node

func _process(delta: float) -> void:
	queue_redraw()

func animate(disappear: bool):
	target_angle_max_deviation_visual = target_angle_max_deviation + PI / 16.0
	aim_accuracy_transparency = 0.0
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "target_angle_max_deviation_visual", target_angle_max_deviation, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "aim_accuracy_transparency", 0.8, 0.5)
	if disappear:
		tween.tween_callback(fade_out).set_delay(0.9)

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "aim_accuracy_transparency", 0.0, 0.3)
	tween.tween_callback(hide)
	
func _draw() -> void:
	draw_arc(Vector2.ZERO, length, target_angle - target_angle_max_deviation_visual, target_angle + target_angle_max_deviation_visual, 15, Color(1.0, 1.0, 1.0, aim_accuracy_transparency * 0.5))
	draw_line(Vector2.ZERO, length * 1.3 * Vector2.from_angle(target_angle - target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency * 0.5))
	draw_line(Vector2.ZERO, length * 1.3 * Vector2.from_angle(target_angle), Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
	draw_line(Vector2.ZERO, length * 1.3 * Vector2.from_angle(target_angle + target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency * 0.5))
	if is_instance_valid(ship_node) and ship_node.fires_remaining > 1:
		draw_string(SystemFont.new(), length * 1.3 * Vector2.from_angle(target_angle), "x %d" % ship_node.fires_remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
