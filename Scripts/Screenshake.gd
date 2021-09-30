extends Node

const TRANS = Tween.TRANS_SINE
const EASE = Tween.EASE_IN_OUT

var amplitude = 0
var priority = 0
var progress:float = 0.0
var frequency:float = 0.0
var window_start_pos:Vector2

onready var camera = get_parent()

func start(duration = 0.2, frequency = 15, amplitude = 16, priority = 0):
	if (priority >= self.priority):
		progress = 0.0
		window_start_pos = OS.window_position
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
	rand.x = rand_range(-amplitude, amplitude) * (1.0 - progress)
	rand.y = rand_range(-amplitude, amplitude) * (1.0 - progress)
	OS.window_position = window_start_pos + rand
	$ShakeTween.interpolate_property(camera, "offset", camera.offset, rand, $Frequency.wait_time, TRANS, EASE)
	$ShakeTween.start()

func _reset():
	$ShakeTween.interpolate_property(camera, "offset", camera.offset, Vector2(), $Frequency.wait_time, TRANS, EASE)
	$ShakeTween.start()

	priority = 0


func _on_Frequency_timeout():
	progress += 1 / (frequency * $Duration.wait_time)
	_new_shake()


func _on_Duration_timeout():
	_reset()
	$Frequency.stop()

