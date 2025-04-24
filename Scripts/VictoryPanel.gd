extends Control

var battle_scene

func _ready():
	Helper.put_rsrc($HBoxContainer, 42, {"money":battle_scene.money_earned})
	for i in 4:
		if i >= len(battle_scene.ship_data):
			get_node("Ship%s" % (i + 1)).visible = false
		else:
			get_node("Ship%s" % (i + 1)).visible = true
			get_node("Ship%s/XP/Label" % (i + 1)).text = "+ %s" % [round(battle_scene.XP_earned)]
			get_node("Ship%s/XP/TextureProgressGained" % (i + 1)).max_value = battle_scene.ship_data[i].XP_to_lv
			get_node("Ship%s/XP/TextureProgressGained" % (i + 1)).value = battle_scene.ship_data[i].XP
			get_node("Ship%s/XP/TextureProgressBar" % (i + 1)).max_value = battle_scene.ship_data[i].XP_to_lv
			get_node("Ship%s/XP/TextureProgressBar" % (i + 1)).value = battle_scene.ship_data[i].XP
			get_node("Ship%s/XP" % (i + 1)).modulate.a = 0.0
			var XP_bar_tween = create_tween()
			XP_bar_tween.tween_property(get_node("Ship%s/XP" % (i + 1)), "modulate:a", 1.0, 0.2).set_delay(i * 0.2 + 0.2)
			XP_bar_tween.tween_property(get_node("Ship%s/XP/TextureProgressGained" % (i + 1)), "value", battle_scene.ship_data[i].XP + battle_scene.XP_earned, 1.0).set_trans(Tween.TRANS_CUBIC)
	$Bonus.text = "%s: %sx %s" % [tr("LOOT_XP_BONUS"), battle_scene.enemy_AI_diff_mult, "[img]Graphics/Icons/help.png[/img]"]
	$Bonus.help_text = "%s: x %s" % [tr("DIFFICULTY"), battle_scene.enemy_AI_diff_mult]
	set_process(false)
	await get_tree().create_timer(0.3 + len(battle_scene.ship_data) * 0.2).timeout
	set_process(true)

func _process(delta):
	for i in len(battle_scene.ship_data):
		var XP_node = get_node("Ship%s/XP/TextureProgressGained" % (i + 1))
		var XP_text_node = get_node("Ship%s/XP/Label2" % (i + 1))
		XP_text_node.text = "%s / %s" % [Helper.format_num(round(XP_node.value)), Helper.format_num(round(battle_scene.ship_data[i].XP_to_lv))]


func _on_close_button_pressed() -> void:
	queue_free()
