extends Node

const TRANS = Tween.TRANS_SINE
const EASE = Tween.EASE_IN_OUT

var amplitude = 0
var priority = 0
var progress:float = 0.0
var frequency:float = 0.0
var window_start_pos:Vector2

@onready var camera = get_parent()

func start(duration = 0.2, frequency = 15, amplitude = 16, priority = 0):
	if (priority >= self.priority):
		progress = 0.0
		window_start_pos = get_window().position
		self.priority = priority
		self.amplitude = amplitude
		self.frequency = float(frequency)

		$Duration.wait_time = duration
		$Frequency.wait_time = 1 / float(frequency)
		$Duration.start()
		$Frequency.start()

		_new_shake()

func _new_shake():
	var rand = Vector2()
	rand.x = randf_range(-amplitude, amplitude) * (1.0 - progress)
	rand.y = randf_range(-amplitude, amplitude) * (1.0 - progress)
	get_window().position = window_start_pos + rand
	var tween = create_tween()
	tween.tween_property(camera, "offset", rand, $Frequency.wait_time).set_trans(TRANS).set_ease(EASE)

func _reset():
	var tween = create_tween()
	tween.tween_property(camera, "offset", Vector2.ZERO, $Frequency.wait_time).set_trans(TRANS).set_ease(EASE)

	priority = 0


func _on_Frequency_timeout():
	progress += 1 / (frequency * $Duration.wait_time)
	_new_shake()


func _on_Duration_timeout():
	_reset()
	$Frequency.stop()
