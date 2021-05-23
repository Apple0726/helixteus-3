extends Control

onready var game = get_node("/root/Game")
onready var p_i = game.planet_data[game.c_p]
onready var id:int = game.c_t
onready var tile = game.tile_data[id]
onready var tile_texture = load("res://Graphics/Tiles/" + String(p_i["type"]) + ".jpg")
var progress = 0#Mining tile progress
var contents:Dictionary
var tween:Tween
var BG_tween:Tween
var layer:String
onready var met_info = game.met_info
var metal_sprites = []
var circ_vel:Vector2 = Vector2.ONE
var points:float#Points for minigame
onready var circ = $CanvasLayer/Circle
onready var spd_mult_node = $Mults/SpdMult
var circ_disabled = false#Useful if pickaxe breaks and auto buy isn't on
var mouse_pos:Vector2
var speed_mult:float = 1.0
var aurora_mult:float = 1.0

func _ready():
	if p_i.temperature > 1000:
		$Tile/TextureRect.texture = load("res://Resources/Lava.tres")
	else:
		$Tile/TextureRect.texture = tile_texture
	if not tile:
		game.tile_data[id] = {}
		tile = game.tile_data[id]
	if tile.has("aurora"):
		refresh_aurora_bonus()
	if not tile.has("mining_progress"):
		tile.mining_progress = 0.0
	if not tile.has("depth"):
		tile.depth = 0
	progress = tile.mining_progress
	if game.pickaxe.has("name"):
		$Pickaxe/Sprite.texture = load("res://Graphics/Items/Pickaxes/" + game.pickaxe.name + ".png")
		update_pickaxe()
	update_info(true)
	generate_rock(false)
	$Help.visible = game.help.mining
	circ.visible = not game.help.mining
	$Help/Label.text = tr("MINE_HELP")
	$LayerInfo.visible = game.show.mining_layer
	if $LayerInfo.visible:
		$LayerAnim.play("Layer fade")
		$LayerAnim.seek(1, true)
	$AutoReplace.pressed = game.auto_replace
	BG_tween = Tween.new()
	add_child(BG_tween)

func refresh_aurora_bonus():
	$Mults/AuroraMult.visible = true
	aurora_mult = Helper.clever_round(Helper.get_au_mult(tile))
	$Mults/AuroraMult.text = "%s: x %s" % [tr("AURORA_MULTIPLIER"), aurora_mult]
	
func update_info(first_time:bool = false):
	var upper_depth
	var lower_depth 
	var unit:String = "m"
	if tile.has("crater"):
		layer = "crater"
		upper_depth = tile.crater.init_depth
		lower_depth = 3 * tile.crater.init_depth
	elif tile.depth <= p_i.crust_start_depth:
		layer = "surface"
		upper_depth = 0
		lower_depth = p_i.crust_start_depth
	elif tile.depth <= p_i.mantle_start_depth:
		if layer != "crust":
			if first_time:
				$SurfaceBG.modulate.a = 0
				$CrustBG.modulate.a = 0.25
			else:
				BG_tween.interpolate_property($SurfaceBG, "modulate", null, Color(1, 1, 1, 0), 3)
				BG_tween.interpolate_property($CrustBG, "modulate", null, Color(1, 1, 1, 0.25), 3)
				BG_tween.start()
		layer = "crust"
		upper_depth = p_i.crust_start_depth + 1
		lower_depth = p_i.mantle_start_depth
	elif tile.depth <= p_i.core_start_depth:
		if tile.has("ship_part"):
			tile.erase("ship_part")
			if not game.objective.empty():
				game.objective.current += 1
			game.popup(tr("SHIP_PART_FOUND"), 2.5)
			game.third_ship_hints.parts[4] = true
		if layer != "mantle":
			if first_time:
				$SurfaceBG.modulate.a = 0
				$CrustBG.modulate.a = 0
				$MantleBG.modulate.a = 0.25
			else:
				BG_tween.interpolate_property($CrustBG, "modulate", null, Color(1, 1, 1, 0), 3)
				BG_tween.interpolate_property($MantleBG, "modulate", null, Color(1, 1, 1, 0.25), 3)
				BG_tween.start()
		layer = "mantle"
		upper_depth = floor(p_i.mantle_start_depth / 1000.0)
		lower_depth = floor(p_i.core_start_depth / 1000.0)
		unit = "km"
	else:
		if tile.has("ship_part"):
			tile.erase("ship_part")
			if not game.objective.empty():
				game.objective.current += 1
			game.popup(tr("SHIP_PART_FOUND"), 2.5)
			game.third_ship_hints.parts[4] = true
		layer = "core"
		upper_depth = floor(p_i.core_start_depth / 1000.0)
		lower_depth = floor(p_i.size / 2.0)
		unit = "km"
	$LayerInfo/Upper.text = "%s %s" % [upper_depth, unit]
	$LayerInfo/Lower.text = "%s %s" % [lower_depth, unit]
	$LayerInfo/Layer.text = tr("LAYER") + ": " + tr(layer.to_upper())
	if unit == "m":
		$LayerInfo/Depth.position.y = range_lerp(tile.depth, upper_depth, lower_depth, 172, 628)
		$LayerInfo/Depth/Label.text = "%s %s" % [tile.depth, unit]
	else:
		$LayerInfo/Depth.position.y = range_lerp(floor(tile.depth / 1000.0), upper_depth, lower_depth, 172, 628)
		$LayerInfo/Depth/Label.text = "%s %s" % [floor(tile.depth / 1000.0), unit]
	$Tile/SquareBar.set_progress(progress)
	$Tile/Cracks.frame = min(floor(progress / 20), 4)

func update_pickaxe():
	$HBox/Durability/Numbers.text = "%s / %s" % [game.pickaxe.durability, game.pickaxes_info[game.pickaxe.name].durability]
	if game.pickaxe.has("liquid_name"):
		$HBox/Liquid.visible = true
		$HBox/Liquid/Numbers.text = "%s / %s" % [game.pickaxe.liquid_dur, game.craft_mining_info[game.pickaxe.liquid_name].durability]
		$HBox/Liquid/Bar.value = game.pickaxe.liquid_dur / float(game.craft_mining_info[game.pickaxe.liquid_name].durability) * 100
	else:
		$HBox/Liquid.visible = false
	$HBox/Durability/Bar.value = game.pickaxe.durability / float(game.pickaxes_info[game.pickaxe.name].durability) * 100

func generate_rock(new:bool):
	var tile_sprite = $Tile
	var vbox = $Panel/VBoxContainer
	contents = {}
	if tween:
		remove_child(tween)
		tween.free()
	tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(tile_sprite, "rect_scale", Vector2(0.3, 0.3), Vector2(1, 1), 0.4, Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()
	for met_sprite in metal_sprites:
		tile_sprite.remove_child(met_sprite)
		met_sprite.free()
	metal_sprites = []
	if not tile.has("contents") or new:
		contents = Helper.generate_rock(tile, p_i).duplicate(true)
		tile.contents = contents
	else:
		contents = tile.contents
	if tile.has("current_deposit"):
		var met = tile.current_deposit.met
		var amount = contents[met]
		for i in clamp(round(amount / 2.0), 1, 40):
			var met_sprite = Sprite.new()
			met_sprite.texture = game.metal_textures[met]
			met_sprite.centered = true
			met_sprite.scale *= rand_range(0.15, 0.2)
			var half_size_in_px = met_sprite.scale.x * 128
			met_sprite.rotation = rand_range(0, 2 * PI)
			met_sprite.position.x = rand_range(half_size_in_px + 5, 195 - half_size_in_px)
			met_sprite.position.y = rand_range(half_size_in_px + 5, 195 - half_size_in_px)
			metal_sprites.append(met_sprite)
			tile_sprite.add_child(met_sprite)
	#var contents2 = contents.duplicate(true)
	#contents2.stone = Helper.get_sum_of_dict(contents.stone)
	Helper.put_rsrc(vbox, 42, contents)
	$Panel.visible = false
	$Panel.visible = true#A weird workaround to make sure Panel has the right rekt_size

func _input(event):
	if event is InputEventMouse:
		mouse_pos = event.position
		$Pickaxe.position = mouse_pos - Vector2(512, 576)
	Helper.set_back_btn($Back)

func _on_Back_pressed():
	game.switch_view("planet")
	queue_free()

var crumbles = []

func place_crumbles(num:int, sc:float, v:float):
	for i in num:
		var crumble = Sprite.new()
		if p_i.temperature > 1000:
			crumble.texture = load("res://Resources/Lava.tres")
		else:
			crumble.texture = tile_texture
		crumble.scale *= sc
		crumble.centered = true
		add_child(crumble)
		crumble.position = mouse_pos
		crumbles.append({"sprite":crumble, "velocity":Vector2(rand_range(-2, 2), rand_range(-8, -4)) * v, "angular_velocity":rand_range(-0.08, 0.08)})

func hide_help():
	$Help.visible = false
	game.help.mining = false
	var tween:Tween = Tween.new()
	circ.modulate.a = 0
	circ.visible = true
	tween.interpolate_property(circ, "modulate", null, Color(1, 1, 1, 0.5), 2)
	add_child(tween)
	tween.start()
	yield(tween, "tween_all_completed")
	remove_child(tween)
	tween.queue_free()

var help_counter = 0
func pickaxe_hit():
	if not game.pickaxe.has("name"):
		return
	if tile.has("current_deposit"):
		var amount_multiplier = -abs(2.0/tile.current_deposit.size * (tile.current_deposit.progress - 1) - 1) + 1
		$HitMetalSound.pitch_scale = rand_range(0.8, 1.2)
		$HitMetalSound.volume_db = -3 - (1 - amount_multiplier) * 10
		$HitRockSound.volume_db = -10 - (amount_multiplier) * 10
		$HitMetalSound.play()
		$HitRockSound.play()
	else:
		$HitRockSound.volume_db = -10
		$HitRockSound.pitch_scale = rand_range(0.8, 1.2)
		$HitRockSound.play()
	if $Help.visible:
		help_counter += 1
		if help_counter >= 10:
			$HelpAnim.play("Help fade")
	place_crumbles(5, 0.1, 1)
	progress += 2 * game.pickaxe.speed * speed_mult * pow(Data.infinite_research_sciences.MMS.value, game.infinite_research.MMS) * (game.pickaxe.speed_mult if game.pickaxe.has("speed_mult") else 1.0)
	game.pickaxe.durability -= 1
	if game.pickaxe.has("liquid_dur"):
		game.pickaxe.liquid_dur -= 1
		if game.pickaxe.liquid_dur <= 0:
			game.pickaxe.erase("liquid_dur")
			game.pickaxe.erase("liquid_name")
			game.pickaxe.erase("speed_mult")
	var rock_gen:bool = false
	if progress >= 1000:
		Helper.get_rsrc_from_rock(contents, tile, p_i)
		game.add_resources(Helper.mass_generate_rock(tile, p_i, (progress - 100) / 100))
		tile.depth += int(progress / 100)
		progress = fmod(progress, 100)
		rock_gen = true
		generate_rock(true)
	else:
		while progress >= 100:
			Helper.get_rsrc_from_rock(contents, tile, p_i)
			progress -= 100
			if not game.objective.empty() and game.objective.type == game.ObjectiveType.MINE:
				game.objective.current += 1
			rock_gen = true
			tile.depth += 1
			generate_rock(true)
	tile.mining_progress = progress
	if rock_gen:
		$MiningSound.pitch_scale = rand_range(0.8, 1.2)
		$MiningSound.play()
		game.show.stone = true
		if not $LayerInfo.visible and tile.depth >= 5:
			game.show.mining_layer = true
			$LayerAnim.play("Layer fade")
			$LayerInfo.visible = true
		place_crumbles(15, 0.2, 2)
		game.HUD.refresh()
	update_info()
	update_pickaxe()
	if game.pickaxe.durability == 0:
		var curr_pick_info = game.pickaxes_info[game.pickaxe.name]
		var costs = curr_pick_info.costs
		if $AutoReplace.pressed and game.check_enough(costs):
			game.deduct_resources(costs)
			game.pickaxe.durability = curr_pick_info.durability
			update_pickaxe()
		else:
			game.pickaxe.erase("name")
			game.pickaxe.erase("durability")
			game.pickaxe.erase("speed")
			circ_disabled = true
			game.popup(tr("PICKAXE_BROKE"), 1.5)
			$Pickaxe.visible = false

func _process(delta):
	for cr in crumbles:
		cr.sprite.position += cr.velocity
		cr.velocity.y += 0.6 * delta * 60
		cr.sprite.rotation += cr.angular_velocity * delta * 60
		if cr.sprite.position.y > 1000:
			remove_child(cr.sprite)
			cr.sprite.free()
			crumbles.erase(cr)
	if circ.visible and not circ_disabled:
		circ.position += circ_vel * max(1, pow(points / 60.0, 0.4)) * delta * 60
		if circ.position.x < 284:
			circ_vel.x = -sign(circ_vel.x) * rand_range(1 / 1.2, 1.2)
			circ.position.x = 284
		if circ.position.x > 484 - 100 * circ.scale.x:
			circ_vel.x = -sign(circ_vel.x) * rand_range(1 / 1.2, 1.2)
			circ.position.x = 484 - 100 * circ.scale.x
		if circ.position.y < 284:
			circ_vel.y = -sign(circ_vel.y) * rand_range(1 / 1.2, 1.2)
			circ.position.y = 284
		if circ.position.y > 484 - 100 * circ.scale.x:
			circ_vel.y = -sign(circ_vel.y) * rand_range(1 / 1.2, 1.2)
			circ.position.y = 484 - 100 * circ.scale.x
		if spd_mult_node.visible:
			speed_mult = Helper.clever_round((points * ((game.MUs.MSMB - 1) * 0.1 + 1) / 3000.0 + 1) * (game.pickaxe.speed_mult if game.pickaxe.has("speed_mult") else 1.0))
			spd_mult_node.text = tr("SPEED_MULTIPLIER") + ": x %s" % [speed_mult]
		spd_mult_node.visible = bool(points) or game.pickaxe.has("speed_mult")
		if Input.is_action_pressed("left_click") and Geometry.is_point_in_circle(mouse_pos, circ.position + 50 * circ.scale, 50 * circ.scale.x):
			points += delta * 60.0
			spd_mult_node["custom_colors/font_color"] = Color(0, 1, 0, 1)
		else:
			if points > 0:
				points = max(points - 3, 0)
				spd_mult_node["custom_colors/font_color"] = Color(1, 0, 0, 1)

func _on_Button_button_down():
	if game.pickaxe.has("name"):
		circ_disabled = false
		$PickaxeAnim.get_animation("Pickaxe swing").loop = true
		$PickaxeAnim.play("Pickaxe swing")

func _on_Button_button_up():
	circ_disabled = true
	$PickaxeAnim.get_animation("Pickaxe swing").loop = false

func _on_CheckBox_mouse_entered():
	game.show_tooltip(tr("AUTO_REPLACE_DESC"))

func _on_CheckBox_mouse_exited():
	game.hide_tooltip()

func _on_Layer_mouse_entered():
	game.show_tooltip(tr(layer.to_upper() + "_DESC"))

func _on_Layer_mouse_exited():
	game.hide_tooltip()

func _on_AutoReplace_pressed():
	game.auto_replace = $AutoReplace.pressed


func _on_AuroraMult_mouse_entered():
	game.show_tooltip(tr("AURORA_MULT_INFO") % [aurora_mult, aurora_mult])


func _on_AuroraMult_mouse_exited():
	game.hide_tooltip()
