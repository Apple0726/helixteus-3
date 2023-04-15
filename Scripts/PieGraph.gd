extends VBoxContainer

@onready var game = get_node("/root/Game")
var objects:Array = []

var txts = []
var small_elements = []
var other_str:String#String used to show other information too small to show in pie graph
var other_str_short:String#Shortened version of other_str that is shown on pie

func _ready():
	refresh()

func sort_pie(a, b):
	if a.value < b.value:
		return true
	return false

func refresh():
	objects.sort_custom(Callable(self,"sort_pie"))
	var last_value = 100.0
	var trace_fraction = 0.0
	small_elements = []
	txts = []
	for pie in $Pies.get_children():
		$Pies.remove_child(pie)
	for obj in objects:
		var pie = TextureProgressBar.new()
		#Angle where the text is placed
		var angle = (last_value / 100.0 - obj.value / 2.0) * 2 * PI - PI / 2.0
		pie.value = last_value
		last_value -= obj.value * 100.0
		if obj.value < 0.06:
			pie.connect("mouse_entered",Callable(self,"show_small_elements"))
			pie.connect("mouse_exited",Callable(self,"hide_small_elements"))
			small_elements.append(obj)
			trace_fraction = last_value / 100.0
		else:
			add_pie_text(obj.text, angle)
			pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pie.texture_progress = obj.texture
		pie.modulate = obj.modulate
		pie.set_fill_mode(pie.FILL_CLOCKWISE)
		$Pies.add_child(pie)
	if trace_fraction != 0.0:
		add_pie_text(other_str_short + "\n" + str(Helper.clever_round((1 - trace_fraction) * 100, 2)) + "%", (1 - (1 - trace_fraction) / 2.0) * 2 * PI - PI / 2.0)
	for txt in txts:
		$Pies.move_child(txt, $Pies.get_child_count())
	small_elements.reverse()

func add_pie_text(txt:String, angle:float):
	var text = Label.new()
	$Pies.add_child(text)
	text.align = text.ALIGNMENT_CENTER
	text.text = txt
	text.visible = false
	text.visible = true
	text.position = Vector2.from_angle(angle) * 95 + Vector2(150, 150) - text.size / 2.0
	text["theme_override_colors/font_color_shadow"] = Color(0, 0, 0, 1)
	text["theme_override_constants/shadow_as_outline"] = 1
	txts.append(text)

func show_small_elements():
	var tooltip = other_str + ":\n"
	for small in small_elements:
		tooltip += small.text.replace("\n", ": ") + "\n"
	tooltip = tooltip.substr(0, len(tooltip) - 1)
	game.show_tooltip(tooltip)

func hide_small_elements():
	game.hide_tooltip()
