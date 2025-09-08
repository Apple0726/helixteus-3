extends Node2D

@onready var game = get_node("/root/Game")
var W:int
var H:int
var LOD:int
var whites:Array = []
var coefficients = []
var wid_p:int
var wid_p2:int
var hv2:float
var h_start:float
var whites_p_target:PackedFloat32Array = []
var whites_p:PackedFloat32Array = []
var whites_p_error:PackedFloat32Array = []
var whites_p_delta_error:PackedFloat32Array = []
var whites_p_total_error:PackedFloat32Array = []
var segments_to_draw = []
var frame = 0
var frames:Array
var phase = 0
var BG_alpha = 0.0
var pixel_color:Color
var music:AudioStreamOggVorbis
var spectrum:AudioEffectSpectrumAnalyzerInstance
var show_delta = false
var feedback_Kp = 1.0
var feedback_Ki = 0.0
var feedback_Kd = 0.0
#var PID_calc: BadApplePIDCalculator

func _ready():
	hide()
	$Panel.modulate.a = 0.0
	set_process(false)
	
func load_data(_LOD, _show_delta):
	if is_processing():
		return
	show()
	$Panel/Label.text = """You found the bad apple easter egg!
Here is some more fun stuff you can try:
- Add exclamation marks at the end of "bad apple" to increase resolution
- Add an apostrophe (') at the end to show only the "differential" between each frame
- Modify the animation "smoothness" factor below:"""
	create_tween().tween_property($Panel, "modulate:a", 1.0, 0.3).set_delay(3.0)
	LOD = _LOD
	show_delta = _show_delta
#	var data = FileAccess.open("data100.txt", FileAccess.READ)
	if OS.get_name() == "Web":
		while wid_p * LOD > 120:
			LOD -= 1
	else:
		while wid_p * LOD > 480:
			LOD -= 1
	wid_p2 = wid_p * LOD
	var data
	if wid_p2 > 120:
		W = 480
		H = 360
		data = FileAccess.open_compressed("res://Easter eggs/Bad apple/badappledata100", FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		W = 120
		H = 90
		data = FileAccess.open_compressed("res://Easter eggs/Bad apple/badappledata25", FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	var st = data.get_as_text()
	frames = st.split("\n")
#	var data2 = FileAccess.open_compressed("res://badappledata100", FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
#	data2.store_string(st)
#	data2.close()
	#PID_calc = BadApplePIDCalculator.new()
	#PID_calc.initialize(wid_p2 * wid_p2)
	hv2 = float(H) * wid_p2 / W
	h_start = (wid_p2 - hv2) / 2.0
	whites.resize(W * H)
	whites_p_target.resize(wid_p2 * wid_p2)
	whites_p.resize(wid_p2 * wid_p2)
	whites_p_error.resize(wid_p2 * wid_p2)
	whites_p_delta_error.resize(wid_p2 * wid_p2)
	whites_p_total_error.resize(wid_p2 * wid_p2)
	coefficients.resize(wid_p2 * wid_p2)
	coefficients.fill(0.0)
	for i in len(whites):
		var x = i % W
		var y = i / W
		var x_p = int(x * wid_p2 / float(W))
		var y_p = int(y * hv2 / float(H) + h_start)
		var ind_p = x_p + y_p * wid_p2
		coefficients[ind_p] += 1
	for i in len(coefficients):
		if coefficients[i] > 0.0:
			coefficients[i] = 1.0 / coefficients[i]
	whites.fill(false)
	whites_p_target.fill(0.0)
	whites_p.fill(0.0)
	whites_p_error.fill(NAN)
	whites_p_delta_error.fill(0.0)
	whites_p_total_error.fill(0.0)
	start_time = Time.get_unix_time_from_system()
	curr_time = start_time
	video_time = start_time
	set_process(true)
	var badapple_music_path = OS.get_executable_path().get_base_dir() + "/badapple.ogg"
	if FileAccess.file_exists(badapple_music_path):
		music = AudioStreamOggVorbis.load_from_file(badapple_music_path)
		if music:
			spectrum = AudioServer.get_bus_effect_instance(1, 0)
			game.switch_music(music, game.u_i.time_speed)
	else:
		music = null

func _draw():
	if phase == 0 or phase == 2 or len(segments_to_draw) == 0:
		draw_rect(Rect2(0, 0, wid_p*200, wid_p*200), Color(pixel_color.r, pixel_color.g, pixel_color.b, BG_alpha))
	else:
		var pixel_size = 200.0/LOD
		var row = 0
		for i in len(segments_to_draw):
			var segment = segments_to_draw[i]
			var segment_start = segment[0]
			var segment_length = segment[1] - segment_start + 1
			var shade = segment[2]
			draw_rect(Rect2(pixel_size*segment_start, pixel_size*row, pixel_size*segment_length, pixel_size), Color(pixel_color.r, pixel_color.g, pixel_color.b, 1.0 - shade))
			if segment[3]:
				row += 1


var start_time:float
var curr_time:float
var video_time:float

func _process(delta):
	if phase == 0:
		BG_alpha += delta
		queue_redraw()
		if BG_alpha >= 1.0:
			if music:
				if spectrum.get_magnitude_for_frequency_range(200, 250, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).x > 0.01:
					phase = 1
			else:
				phase = 1
	elif phase == 1:
		if curr_time >= video_time:
			var frames_to_process = int(ceil(game.u_i.time_speed * delta * 30.0))
			draw_frame(frames_to_process)
			video_time += 1/30.0 / game.u_i.time_speed * frames_to_process
		curr_time += delta
		for i in 3:
			LFOs[i].value = LFOs[i].amplitude * sin(2.0 * PI * LFOs[i].frequency * Time.get_ticks_msec() / 1000.0) + LFOs[i].offset
		if $Panel/HSliderP/OptionButton.selected > 0:
			$Panel/HSliderP.value = LFOs[$Panel/HSliderP/OptionButton.selected-1].value
		if $Panel/HSliderI/OptionButton.selected > 0:
			$Panel/HSliderI.value = LFOs[$Panel/HSliderI/OptionButton.selected-1].value
		if $Panel/HSliderD/OptionButton.selected > 0:
			$Panel/HSliderD.value = LFOs[$Panel/HSliderD/OptionButton.selected-1].value
	elif phase == 2:
		BG_alpha -= delta * 4.0
		queue_redraw()
		var tween = create_tween()
		if "rekt" in $Panel/Label.text:
			tween.tween_property($Panel, "modulate:a", 0.0, 0.3).set_delay(5.0)
		else:
			tween.tween_property($Panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(hide)
		if BG_alpha <= 0.0:
			phase = 0
			if music:
				game.switch_music(Data.ambient_music.pick_random(), game.u_i.time_speed)
			set_process(false)
			game.block_scroll = false


func draw_frame(frames_to_process:int):
	if show_delta:
		whites.fill(false)
		whites_p_target.fill(0.0)
		whites_p.fill(0.0)
	for h in frames_to_process:
		var pixelsStr = frames[frame].split(";")#pixelsStr = ["119,41", "119,42", ...]
		if len(pixelsStr) > 1:
			for pixelStr in pixelsStr:
				var pixelCoords = pixelStr.split(",")
				if len(pixelCoords) > 1:
					var y_coord = int(pixelCoords[-1])
					var prev_x = -1
					for i in range(0, len(pixelCoords)-1):
						var x_coord = int(pixelCoords[i])
						if i%2 == 1:
							change_pixels(prev_x, x_coord, y_coord)
							prev_x = -1
						else:
							prev_x = x_coord
					if prev_x != -1:
						change_pixels(prev_x, W, y_coord)
		frame += 1
		if frame >= len(frames):
			phase = 2
			frame = 0
			break
	segments_to_draw.clear()
	#whites_p = PID_calc.calculate(whites_p_target)
	for i in len(whites_p_target):
		if is_nan(whites_p_error[i]):
			whites_p_error[i] = whites_p_target[i]
		whites_p_delta_error[i] = whites_p_error[i] - (whites_p_target[i] - whites_p[i])
		whites_p_error[i] = whites_p_target[i] - whites_p[i]
		whites_p[i] += feedback_Kp * (whites_p_target[i] - whites_p[i]) + feedback_Ki * whites_p_total_error[i] + feedback_Kd * whites_p_delta_error[i]
		whites_p_total_error[i] += whites_p_error[i]
		if abs(whites_p[i]) > 1e20:
			phase = 2
			frame = 0
			$Panel/Label.text = "One of the pixels diverged to infinity! Get rekt system \"engineer\""
			return
	for row in wid_p2:
		# 0: start pos, 1: end pos (inclusive), 2: value, 3: go to next row
		var segment = [0, 0, whites_p[row * wid_p2], true]
		for col in range(1, wid_p2):
			var white_value = whites_p[row * wid_p2 + col]
			if abs(white_value - segment[2]) > 0.005:
				segment[1] = col-1
				segment[3] = false
				segments_to_draw.append(segment)
				segment = [col, col, white_value, true]
		segment[1] = wid_p2-1
		segments_to_draw.append(segment)
	queue_redraw()

func change_pixels(x_from: int, x_to: int, y_coord: int):
	for i in range(x_from, x_to):
		var ind = i + y_coord * W
		if show_delta:
			whites[ind] = true
		else:
			whites[ind] = not whites[ind]
		var x_p = int(i * wid_p2 / float(W))
		var y_p = int(y_coord * hv2 / float(H) + h_start)
		var ind_p = x_p + y_p * wid_p2
		whites_p_target[ind_p] += coefficients[ind_p] if whites[ind] else -coefficients[ind_p]
	
func _on_tree_exiting() -> void:
	if music:
		game.switch_music(Data.ambient_music.pick_random(), game.u_i.time_speed)


func _on_h_slider_p_value_changed(value: float) -> void:
	feedback_Kp = value
	#PID_calc.changeKp(value)
	$Panel/HSliderP/Label.text = str(value)


func _on_h_slider_i_value_changed(value: float) -> void:
	feedback_Ki = value
	#PID_calc.changeKi(value)
	$Panel/HSliderI/Label.text = str(value)


func _on_h_slider_d_value_changed(value: float) -> void:
	feedback_Kd = value
	#PID_calc.changeKd(value)
	$Panel/HSliderD/Label.text = str(value)

func _on_op_button_pressed() -> void:
	$Panel/OPButton.hide()
	$Panel/HSliderD.show()
	$Panel/HSliderI.show()
	$Panel/HSliderP/Label2.show()
	$Panel/OPButton2.show()

var selected_LFO = 0
var LFOs = [
	{
		"frequency":1.0,
		"amplitude":0.5,
		"offset":0.5,
		"value":0.5,
	},
	{
		"frequency":1.0,
		"amplitude":0.5,
		"offset":0.5,
		"value":0.5,
	},
	{
		"frequency":1.0,
		"amplitude":0.5,
		"offset":0.5,
		"value":0.5,
	},
]

func _on_h_slider_f_value_changed(value: float) -> void:
	LFOs[selected_LFO].frequency = value
	$Panel/LFO/LabelF.text = str(value) + " Hz"


func _on_h_slider_a_value_changed(value: float) -> void:
	LFOs[selected_LFO].amplitude = value
	$Panel/LFO/LabelA.text = str(value) + " amplitude"


func _on_h_slider_o_value_changed(value: float) -> void:
	LFOs[selected_LFO].offset = value
	$Panel/LFO/LabelO.text = str(value) + " offset"


func _on_op_button_2_pressed() -> void:
	$Panel/OPButton2.hide()
	$Panel/LFO.show()
	$Panel/HSliderP/OptionButton.show()
	$Panel/HSliderI/OptionButton.show()
	$Panel/HSliderD/OptionButton.show()


func _on_option_button_item_selected(index: int) -> void:
	selected_LFO = index
	$Panel/LFO/LabelF.text = str(LFOs[selected_LFO].frequency) + " Hz"
	$Panel/LFO/LabelA.text = str(LFOs[selected_LFO].amplitude) + " amplitude"
	$Panel/LFO/LabelO.text = str(LFOs[selected_LFO].offset) + " offset"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and phase == 1:
		var rect = [$Panel.position, $Panel.position + Vector2.RIGHT * $Panel.size.x, $Panel.position + $Panel.size, $Panel.position + Vector2.DOWN * $Panel.size.y]
		game.block_scroll = Geometry2D.is_point_in_polygon(to_local(event.position), rect)
