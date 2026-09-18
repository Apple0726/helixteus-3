extends HBoxContainer

@onready var game = get_node("/root/Game")

var info_text:String
var on_close_callable = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Text.visible = false
	$Text.text = info_text
	$Text.modulate.a = 0
	$Text.visible = true
	$Text.size.x = 0#This "trick" lets us resize the label to fit the text
	$Text.position.x = -$Text.get_minimum_size().x / 2.0
	$Text.modulate.a = 1
	$CloseButton.pressed.connect(on_close_pressed)

func on_close_pressed():
	if on_close_callable != null:
		on_close_callable.call()
	game.hide_tooltip()
	game.bottom_info_action = ""
	game.HUD.refresh()
	var gray_tiles = get_tree().get_nodes_in_group("gray_tiles")
	if not gray_tiles.is_empty():
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(get_tree().get_first_node_in_group("gray_tiles").material, "shader_parameter/amount", 0.0, 0.2)
		for gray_tile in gray_tiles:
			tween.tween_callback(gray_tile.queue_free).set_delay(0.15)
			gray_tile.remove_from_group("gray_tiles")
		await tween.finished
	queue_free()
