extends RichTextLabel

@onready var game = get_node("/root/Game")

var tooltip_display_position_x = 0
var tooltip_display_position_y = 0
var imgs:Array
var imgs_size:int
var orig_text:String

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	if game.mouse_pos.x > 1250 - size.x:
		tooltip_display_position_x = 1
	else:
		tooltip_display_position_x = 0
	if game.mouse_pos.y > 690 - size.y:
		tooltip_display_position_y = 1
	else:
		tooltip_display_position_y = 0
	set_tooltip_position()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.0).set_delay(0.05)


func set_tooltip_position():
	if Settings.op_cursor:
		position.x = max(game.mouse_pos.x - size.x - 5, 0)
		position.y = max(game.mouse_pos.y - size.y - 5, 0)
	else:
		if tooltip_display_position_x == 0:
			position.x = min(game.mouse_pos.x + 9, (1278 if game.get_node("UI/Panel").modulate.a == 0.0 else 900) - size.x)
		elif tooltip_display_position_x == 1:
			position.x = max(game.mouse_pos.x - size.x - 9, 0)
		if tooltip_display_position_y == 0:
			position.y = min(game.mouse_pos.y + 9, 720 - size.y)
		elif tooltip_display_position_y == 1:
			position.y = max(game.mouse_pos.y - size.y - 9, 0)


func show_additional_text(txt: String, delay: float = 1.0, different_orig_text: String = ""):
	await get_tree().create_timer(delay).timeout
	size.x = 500.0
	if different_orig_text == "":
		Helper.add_text_to_RTL(self, orig_text + "\n\n" + txt, imgs, imgs_size, true)
	else:
		Helper.add_text_to_RTL(self, different_orig_text + "\n\n" + txt, imgs, imgs_size, true)
	set_tooltip_position()
