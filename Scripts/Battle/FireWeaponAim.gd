extends Node2D

var target_angle:float
var target_angle_max_deviation:float
var target_angle_max_deviation_visual:float
var aim_accuracy_transparency:float
var draw_aim_accuracy:bool = false

func _process(delta: float) -> void:
	if draw_aim_accuracy:
		queue_redraw()

func animate(_target_angle: float, _target_angle_max_deviation: float):
	target_angle = _target_angle
	target_angle_max_deviation = _target_angle_max_deviation
	target_angle_max_deviation_visual = target_angle_max_deviation + PI / 16.0
	aim_accuracy_transparency = 0.0
	draw_aim_accuracy = true
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "target_angle_max_deviation_visual", target_angle_max_deviation, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "aim_accuracy_transparency", 0.8, 0.6)
	tween.tween_property(self, "aim_accuracy_transparency", 0.0, 0.4).set_delay(0.9)
	tween.tween_callback(func(): draw_aim_accuracy = false).set_delay(1.3)
	tween.tween_callback(queue_redraw).set_delay(1.3)

func _draw() -> void:
	if draw_aim_accuracy:
		draw_arc(Vector2.ZERO, 200.0, target_angle - target_angle_max_deviation_visual, target_angle + target_angle_max_deviation_visual, 15, Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
		draw_line(Vector2.ZERO, 300.0 * Vector2.from_angle(target_angle - target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
		draw_line(Vector2.ZERO, 300.0 * Vector2.from_angle(target_angle + target_angle_max_deviation_visual), Color(1.0, 1.0, 1.0, aim_accuracy_transparency))
