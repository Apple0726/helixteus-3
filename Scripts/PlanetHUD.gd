extends Control
@onready var game = get_node("/root/Game")
@onready var click_sound = game.get_node("click")
var on_button = false

func _ready():
	refresh()

func is_one_element_true(dict:Dictionary):
	var res = false
	for key in dict.keys():
		if dict[key]:
			res = true
			break
	return res

func refresh():
	#$VBoxContainer/Construct/New.visible = not game.new_bldgs.is_empty() and is_one_element_true(game.new_bldgs)
	$VBoxContainer/Terraform.visible = game.science_unlocked.has("TF")
	$VBoxContainer/Mine.visible = game.show.has("mining")

func _input(event):
	refresh()

func _on_Construct_pressed():
	click_sound.play()
	game.planet_HUD.get_node("VBoxContainer/Construct/AnimationPlayer").stop()
	if $ConstructPanel.visible:
		$ConstructPanel.hide_panel()
	else:
		game.hide_tooltip()
		$ConstructPanel/AnimationPlayer.play("Fade")
		$ConstructPanel.visible = true
		game.block_scroll = true
		$ConstructPanel.refresh()


func _on_Mine_pressed():
	click_sound.play()
	game.mine_tile()

func _on_Construct_mouse_entered():
	on_button = true
	game.show_tooltip(tr("CONSTRUCT") + " (C)")

func _on_Mine_mouse_entered():
	on_button = true
	game.show_tooltip(tr("MINE") + " (N)")

func _on_mouse_exited():
	on_button = false
	game.hide_tooltip()

func _on_Terraform_pressed():
	if game.c_p_g == 2:
		game.popup(tr("NO_TF"), 1.5)
	elif game.planet_data[game.c_p].has("MS"):
		game.popup("%s (%s)" % [tr("NO_TF"), tr("MS_EXISTS")], 2.0)
	else:
		game.terraform_panel.pressure = game.planet_data[game.c_p].pressure
		var surface = 4 * PI * pow(game.planet_data[game.c_p].size / 8.0, 2)
		game.terraform_panel.surface = round(surface)
		var lake_num:int = 0
		var ash_mult:float = 0.0
		var SP_feature_mult:float = 0.0
		var energy_feature_mult:float = 0.0
		for tile in game.tile_data:
			ash_mult += 1.0
			SP_feature_mult += 1.0
			energy_feature_mult += 1.0
			if tile:
				if tile.has("lake"):
					lake_num += 1
				elif tile.has("ash"):
					ash_mult += tile.ash.richness - 1.0
				if tile.has("resource_production_bonus"):
					if tile.resource_production_bonus.has("SP"):
						SP_feature_mult += tile.resource_production_bonus.SP - 1.0
					if tile.resource_production_bonus.has("energy"):
						energy_feature_mult += tile.resource_production_bonus.energy - 1.0
		ash_mult /= len(game.tile_data)
		SP_feature_mult /= len(game.tile_data)
		energy_feature_mult /= len(game.tile_data)
		game.terraform_panel.lake_num = lake_num
		game.terraform_panel.tile_num = len(game.tile_data)
		game.terraform_panel.ash_mult = ash_mult
		game.terraform_panel.SP_feature_mult = SP_feature_mult
		game.terraform_panel.energy_feature_mult = energy_feature_mult
		game.toggle_panel(game.terraform_panel)

func _on_Terraform_mouse_entered():
	game.show_tooltip(tr("TERRAFORM"))
