class_name Cave
extends Node2D

var astar_node = AStar2D.new()

@onready var game = get_node("/root/Game")
@onready var p_i = game.planet_data[game.c_p]
@onready var tile = game.tile_data[game.c_t]
@onready var is_aurora_cave:bool = tile.has("aurora")
@onready var tile_type = p_i.type - 3
var time_speed:float = 1.0
#Aurora intensity
@onready var au_int:float = tile.get("aurora", 0.0)
@onready var aurora_mult:float = Helper.clever_round(pow(1 + au_int, 1.5))
@onready var volcano_mult:float = tile.ash.richness if tile.has("ash") else 1.0
@onready var artificial_volcano = tile.has("ash") and tile.ash.has("artificial")
@onready var difficulty:float = game.system_data[game.c_s].diff * aurora_mult * (pow(volcano_mult, 2.5) if tile.has("ash") and not tile.ash.has("artificial") else 1.0)

var laser_texture = preload("res://Graphics/Cave/Projectiles/laser.png")
var bullet_scene = preload("res://Scenes/Cave/Projectile.tscn")
var bullet_texture = preload("res://Graphics/Cave/Projectiles/enemy_bullet.png")
var bubble_texture = preload("res://Graphics/Cave/Projectiles/bubble.png")
var purple_texture = preload("res://Graphics/Cave/Projectiles/purple_bullet.png")

@onready var cave_BG = $Floor
@onready var cave_wall = $Walls
@onready var minimap_cave = $UI/Minimap/Floor
@onready var minimap_rover = $UI/Rover
@onready var MM_hole = $UI/Minimap/Hole
@onready var MM_exit = $UI/Minimap/Exit
@onready var MM = $UI/Minimap
@onready var rover = $Rover
@onready var rover_light = $Rover/PointLight2D
@onready var camera = $Camera2D
@onready var exit = $Exit
@onready var hole = $Hole
@onready var ray = $Rover/RayCast2D
@onready var RoD = $Rover/RayOfDoom
@onready var RoD_sprite = $Rover/RayOfDoom/Sprite2D
@onready var RoDray = $Rover/RayOfDoom/Ray
@onready var RoD_effects = $RoDEffects
@onready var RoD_coll = $Rover/RayOfDoom/CollisionShape2D
@onready var RoD_coll2 = $Rover/RayOfDoom/CollisionShape2D2
@onready var mining_laser = $Rover/MiningLaser
@onready var mining_p = $MiningParticles
@onready var tile_highlight_left = $TileHighlightLeft
@onready var tile_highlight_right = $TileHighlightRight
@onready var canvas_mod = $CanvasModulate
@onready var aurora_mod = $AuroraModulate
@onready var active_item = $UI2/BottomLeft/VBox/ActiveItem
@onready var inventory_slots = $UI2/BottomLeft/VBox/InventorySlots
@onready var use_item_node = $UI/UseItem
@onready var ability_timer = $UI2/Ability/Timer
@onready var crack_detector = $Rover/CrackDetector
@onready var HX1_scene = preload("res://Scenes/Cave/HX.tscn")
@onready var deposit_scene = preload("res://Scenes/Cave/MetalDeposit.tscn")
@onready var enemy_icon_scene = preload("res://Graphics/Cave/MMIcons/Enemy.png")
@onready var object_scene = preload("res://Scenes/Cave/Object.tscn")
@onready var sq_bar_scene = preload("res://Scenes/SquareBar.tscn")
@onready var filter_btn_scene = preload("res://Scenes/FilterButton.tscn")

var minimap_zoom:float = 0.02
var minimap_center:Vector2 = Vector2(1150, 128)
var curr_slot:int = 0
var floor_seeds = []
var id:int = -1#Cave id
var rover_data:Dictionary = {}
var cave_data:Dictionary
var modifiers:Dictionary = {}
var cave_darkness:float = 0.0
var wormhole
var on_ash:bool = false
var on_lava:bool = false
var input_vector:Vector2 = Vector2.ZERO
var start_at_floor:int

var velocity = Vector2.ZERO
var max_speed = 1000
var acceleration = 200
var friction = 200
var rover_size = 1.0
var speed_penalty:float = 1.0
var dashes_remaining:int = 0

#Rover stats
var atk:float = 5.0
var def:float = 5.0
var HP:float = 20.0
var total_HP:float = 20.0
var speed_mult:float = 1.0
var inventory:Array = []
var right_inventory:Array = []
var inventory_ready:Array = []#For cooldowns
var right_inventory_ready:Array = []#For cooldowns
var i_w_w:Dictionary = {}#inventory_with_weight
var weight:float = 0.0
var weight_cap:float = 1500.0
var status_effects:Dictionary = {}
var enhancements:Dictionary = {}
var laser_name:String = ""
var laser_damage:float = 0.0
var ability:String = ""
var ability_num:int = 0
var travel_distance:float = 0#Only used for unique death message for now
var armor_damage_mult:float = 1.0#For armor enhnacements

var moving_fast:bool = false
var cave_floor:int = 1
var num_floors:int
var cave_size:int
var tiles:PackedVector2Array
var rooms:Array = []
var HX_tiles:Array = []#Tile ids occupied by HX
var deposits:Dictionary = {}#Random metal/material deposits
var chests:Dictionary = {}#Random chests and their contents
var active_chest:String = "-1"#Chest id of currently active chest (rover is touching it)
var active_type:String = ""
var tiles_touched_by_laser:Dictionary = {}
var debris_touched_by_laser:Dictionary = {}

### Cave save data ###

var seeds = []
var tiles_mined:Array = []#Contains data of mined tiles so they don't show up again when regenerating floor
var enemies_rekt:Array = []#idem
var chests_looted:Array = []
var partially_looted_chests:Array = []
var debris_rekt:Array = []
var hole_exits:Array = []#id of hole and exit on each floor

### End cave save data ###

var shaking:Vector2 = Vector2.ZERO
var star_mod:Color = Color.WHITE
var tile_avg_mod:Color = Color.WHITE
var tile_brightness:float
var brightness_mult:float
var light_strength_mult:float

var big_debris:Dictionary = {}

#Modifiers

var enemy_attack_rate:float = 1.0
var enemy_projectile_size:float = 1.0
var treasure_mult:float = 1.0
var debris_amount:float

func _ready():
	if p_i.has("lake"):
		cave_wall.tile_set.get_source(0).texture = preload("res://Graphics/Tiles/frozen_cave_wall_atlas.png")
	$Ash.tile_set = ResourceFiles.ash_tile_set
	camera.make_current()
	$Exit/GPUParticles2D.emitting = true
	$UI2/Controls.center_position = Vector2(640, 160)
	$UI2/Controls.add_key("WASD", "MOVE_ROVER")
	$UI2/Controls.add_key(tr("SCROLL_WHEEL"), "CHANGE_ACTIVE_ITEM")
	$UI2/Controls.add_key(tr("HOLD_LEFT_RIGHT_CLICK"), "USE_ACTIVE_ITEM")
	$UI2/Controls.add_key("M", "TOGGLE_MINIMAP")
	if not game.help.has("sprint_mode"):
		$UI2/Controls.add_key("E", "SPRINT_MODE")
	if enhancements.has("wheels_0"):
		$UI2/Controls.add_key(tr("SPACEBAR"), "DASH")
	if game.help.has("cave_controls"):
		$UI2/Controls.add_key("J", "HIDE_THIS_PANEL")
		$UI2/CaveInfo/Ctrls.visible = false
		$UI2/Controls.visible = true
		game.help_str = "cave_controls"
	$UI2/Controls/Label.text = tr("CONTROLS")
	$UI2/Controls.refresh()
	time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, game.u_i.time_speed * tile.get("time_speed_bonus", 1.0))
	HP = rover_data.HP
	total_HP = rover_data.HP
	atk = rover_data.atk
	def = rover_data.def
	speed_mult = rover_data.spd
	weight_cap = rover_data.weight_cap
	inventory = rover_data.inventory
	right_inventory = rover_data.right_inventory
	i_w_w = rover_data.i_w_w
	enhancements = rover_data.get("enhancements", {})
	if right_inventory[0].get("type") == "rover_weapons":
		laser_name = right_inventory[0].id.split("_")[0]
	else:
		for i in len(inventory):
			if inventory[i].get("type") == "rover_weapons":
				laser_name = inventory[i].id.split("_")[0]
	laser_damage = Data.rover_weapons[laser_name + "_laser"].damage * atk * rover_size * game.u_i.charge
	if rover_data.MK == 2:
		$Rover/Sprite2D.texture = preload("res://Graphics/Cave/Rover top down 2.png")
	elif rover_data.MK == 3:
		$Rover/Sprite2D.texture = preload("res://Graphics/Cave/Rover top down 3.png")
	ability = rover_data.ability
	ability_num = rover_data.ability_num
	if ability != "":
		$UI2/Ability.visible = true
		$UI2/Ability/TextureRect.texture = load("res://Graphics/Cave/RE/%s.png" % rover_data.ability)
		$UI2/Ability/Panel/Num.text = str(ability_num)
	else:
		$UI2/Ability.visible = false
	if enhancements.has("wheels_2"):
		dashes_remaining = 3
	elif enhancements.has("wheels_1"):
		dashes_remaining = 2
	elif enhancements.has("wheels_0"):
		dashes_remaining = 1
	if enhancements.has("laser_5"):
		$Rover/EnergyBallTimer.start(0.5 / time_speed)
	elif enhancements.has("laser_4"):
		$Rover/EnergyBallTimer.start(1.0 / time_speed)
	#$WorldEnvironment.environment.glow_enabled = game.enable_shaders
	if not game.achievement_data.random.has("clear_out_cave_floor"):
		$CheckAchievements.start()
	tile_brightness = game.tile_brightness[p_i.type - 3]
	tile_avg_mod = game.tile_avg_mod[p_i.type - 3]
	var lum:float = 0.0
	for star in game.system_data[game.c_s].stars:
		var sc:float = 0.5 * star.size / (p_i.distance / 500)
		if star.luminosity > lum:
			star_mod = Helper.get_star_modulate(star["class"])
			if star_mod.get_luminance() < 0.2:
				star_mod = star_mod.lightened(0.2 - star_mod.get_luminance())
			#$TileMap.material.set_shader_parameter("saturation", saturation)
			lum = star.luminosity
	cave_BG.material.set_shader_parameter("modulate_color", star_mod)
	light_strength_mult = 1.0
	if p_i.temperature >= 1500:
		light_strength_mult = min(remap(p_i.temperature, 1500, 3000, 1.2, 1.5), 1.5)
	else:
		light_strength_mult = min(remap(p_i.temperature, -273, 1500, 0.3, 1.2), 1.2)
	var brightness:float = remap(tile_brightness, 40000, 90000, 2.5, 1.1) * light_strength_mult
	var contrast:float = sqrt(brightness)
	cave_BG.material.set_shader_parameter("brightness", min(brightness, 1.6))
	cave_BG.material.set_shader_parameter("contrast", 1.5)
	var cave_type:String = ""
	if tile.has("cave"):
		cave_type = "cave"
	elif tile.has("diamond_tower"):
		cave_type = "diamond_tower"
	num_floors = tile[cave_type].num_floors
	cave_size = tile[cave_type].floor_size
	if not tile[cave_type].has("debris"):
		tile[cave_type].debris = randf() + 0.2
	if not tile[cave_type].has("period"):
		tile[cave_type].period = 65
	debris_amount = tile[cave_type].debris
	if tile[cave_type].has("modifiers"):
		$UI2/CaveInfo/Modifiers.visible = true
		modifiers = tile[cave_type].modifiers
		for modifier in modifiers:
			if Data.cave_modifiers[modifier].has("double_treasure_at"):
				var double_treasure_at:float = Data.cave_modifiers[modifier].double_treasure_at
				if modifiers[modifier] > 1.0 and double_treasure_at > 1.0 and not Data.cave_modifiers[modifier].has("no_treasure_mult"):
					treasure_mult *= remap(modifiers[modifier], 1.0, double_treasure_at, 0, 1) + 1.0
				elif modifiers[modifier] < 1.0 and double_treasure_at < 1.0 and not Data.cave_modifiers[modifier].has("no_treasure_mult"):
					treasure_mult *= remap(1.0 / modifiers[modifier], 1.0, 1.0 / double_treasure_at, 0, 1) + 1.0
			elif Data.cave_modifiers[modifier].has("treasure_if_true"):
				treasure_mult *= Data.cave_modifiers[modifier].treasure_if_true
		if modifiers.has("enemy_attack_rate"):
			enemy_attack_rate = modifiers.enemy_attack_rate
		if modifiers.has("enemy_size"):
			enemy_projectile_size = modifiers.enemy_size
		if modifiers.has("rover_size"):
			rover_size = modifiers.rover_size
		if modifiers.has("minimap_disabled"):
			$UI/Error.visible = true
			MM.visible = false
			$UI/MinimapBG.visible = true
	if tile[cave_type].has("id"):
		id = tile.cave.id
		var cave_data_file = FileAccess.open("user://%s/Univ%s/Caves/%s.hx3" % [game.c_sv, game.c_u, id], FileAccess.READ)
		if cave_data_file == null:
			cave_data_file = FileAccess.open("user://%s/Univ%s/Caves/%s.hx3~" % [game.c_sv, game.c_u, id], FileAccess.READ)
		cave_data = cave_data_file.get_var()
		cave_data_file.close()
		seeds = cave_data.seeds
		tiles_mined = cave_data.tiles_mined
		enemies_rekt = cave_data.enemies_rekt
		debris_rekt = cave_data.get("debris_rekt", [[]])
		chests_looted = cave_data.chests_looted
		partially_looted_chests = cave_data.partially_looted_chests
		hole_exits = cave_data.hole_exits
	else:
		id = game.caves_generated
		tile[cave_type].id = id
		game.caves_generated += 1
	minimap_rover.position = minimap_center
	minimap_cave.scale *= minimap_zoom
	minimap_rover.scale *= 0.1
	generate_cave(true, false)
	if start_at_floor > 1:
		for i in int(start_at_floor - 1):
			go_down_cave()
			var avg_dmg:float = 6.0 * difficulty / def / rover_size * armor_damage_mult
			var dmg_to_HP_ratio:float = avg_dmg / total_HP
			if cave_floor == num_floors or dmg_to_HP_ratio > 0.2:
				break
	if is_aurora_cave:
		$AuroraPlayer.play("Aurora", -1, 0.2)
	for rsrc in game.show:
		if game.show[rsrc]:
			add_filter(rsrc)
	$UI2/Filters/Grid/money.connect("pressed",Callable(self,"on_filter_pressed").bind("money", $UI2/Filters/Grid/money))
	$UI2/Filters/Grid/money.set_mod(game.cave_filters.money)
	$UI2/Filters/Grid/minerals.connect("pressed",Callable(self,"on_filter_pressed").bind("minerals", $UI2/Filters/Grid/minerals))
	$UI2/Filters/Grid/minerals.set_mod(game.cave_filters.minerals)
	$UI2/Filters/Grid/stone.connect("pressed",Callable(self,"on_filter_pressed").bind("stone", $UI2/Filters/Grid/stone))
	$UI2/Filters/Grid/stone.set_mod(game.cave_filters.stone)
	
	for w in i_w_w:
		weight += i_w_w[w]
	for i in len(inventory):
		inventory_ready.append(true)
	right_inventory_ready.append(true)
	for i in range(0, len(inventory)):
		var slot = preload("res://Scenes/InventorySlot.tscn").instantiate()
		slot.get_node("Button").modulate = Color.RED
		inventory_slots.add_child(slot)
		slots.append(slot)
		if not inventory[i].is_empty():
			set_slot_info(slot, inventory[i])
	$UI2/RightClickSlot.get_node("Button").modulate = Color.GREEN
	if not right_inventory[0].is_empty():
		set_slot_info($UI2/RightClickSlot, right_inventory[0])
	set_border(curr_slot)
	$UI2/HP/Bar.max_value = total_HP
	$UI2/HP/Bar.value = total_HP
	$Rover/Bar.max_value = total_HP
	$UI2/Inventory/Bar.max_value = weight_cap
	$Rover/InvBar.max_value = weight_cap
	$UI2/Inventory/Bar.value = weight
	$Rover/InvBar.value = weight
	update_health_bar(total_HP)
	$UI2/Inventory/Label.text = "%s / %s kg" % [Helper.format_num(round(weight)), Helper.format_num(weight_cap)]
	if game.help.has("sprint_mode") and speed_mult > 1:
		game.popup_window(tr("PRESS_E_TO_SPRINT"), tr("SPRINT_MODE"))
		game.help.erase("sprint_mode")

func add_filter(rsrc):
	if rsrc in game.mat_info.keys():
		add_filter_slot("Materials", rsrc)
	elif rsrc in game.met_info.keys():
		add_filter_slot("Metals", rsrc)
	elif rsrc in Item.data.keys():
		add_filter_slot("Items", rsrc)
	
func add_filter_slot(type:String, rsrc):
	var filter_slot = filter_btn_scene.instantiate()
	if rsrc is int:
		filter_slot.texture = load("res://Graphics/%s/%s/%s.png" % ["Items", Item.icon_directory(Item.data[rsrc].type), Item.data[rsrc].icon_name])
	else:
		filter_slot.texture = load("res://Graphics/%s/%s.png" % [type, rsrc])
	$UI2/Filters/Grid.add_child(filter_slot)
	if not game.cave_filters.has(rsrc):
		game.cave_filters[rsrc] = false
	filter_slot.set_mod(game.cave_filters[rsrc])
	filter_slot.connect("mouse_entered",Callable(self,"on_filter_mouse_entered").bind(rsrc))
	filter_slot.connect("mouse_exited",Callable(self,"on_filter_mouse_exited"))
	filter_slot.connect("pressed",Callable(self,"on_filter_pressed").bind(rsrc, filter_slot))

func on_filter_mouse_entered(rsrc):
	if rsrc is int:
		game.show_tooltip(Item.name(rsrc))
	else:
		game.show_tooltip(tr(rsrc.to_upper()))

func on_filter_pressed(rsrc:String, filter_slot):
	game.cave_filters[rsrc] = not game.cave_filters[rsrc]
	filter_slot.set_mod(game.cave_filters[rsrc])

func on_filter_mouse_exited():
	game.hide_tooltip()

func set_slot_info(slot, _inv:Dictionary):
	var rsrc = _inv.type
	if rsrc == "":
		return
	if rsrc == "rover_weapons":
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Weapons/" + _inv.id + ".png")
	elif rsrc == "rover_mining":
		var c:Color = get_color(_inv.id.split("_")[0])
		mining_laser.material["shader_parameter/outline_color"] = c
		mining_laser.get_node("PointLight2D").color = c
		if _inv.id.split("_")[0] in ["blue"]:
			mining_laser.get_node("PointLight2D").energy = 3
		else:
			mining_laser.get_node("PointLight2D").energy = 2
		var speed = Data.rover_mining[_inv.id].speed
		mining_p.amount = int(25 * pow(speed, 0.2) * pow(rover_size, 2 * 0.2) * time_speed)
		mining_p.process_material.initial_velocity_min = 300 * pow(speed, 0.3) * pow(rover_size, 2 * 0.3) * time_speed
		mining_p.process_material.initial_velocity_max = 500 * pow(speed, 0.3) * pow(rover_size, 2 * 0.3) * time_speed
		mining_p.lifetime = 0.2 / time_speed
		slot.get_node("TextureRect").texture = load("res://Graphics/Cave/Mining/" + _inv.id + ".png")
	else:
		if _inv.id == "money":
			slot.get_node("TextureRect").texture = Data.money_icon
		elif _inv.id == "minerals":
			slot.get_node("TextureRect").texture = Data.minerals_icon
		else:
			slot.get_node("TextureRect").texture = load("res://Graphics/Items/%s.png" % [Item.icon_directory(_inv.id)])
		if _inv.has("num"):
			slot.get_node("Label").text = Helper.format_num(_inv.num, false, 3)
	
func remove_cave():
	astar_node.clear()
	rooms.clear()
	tiles = []
	HX_tiles.clear()
	active_type = ""
	cave_BG.clear()
	cave_wall.clear()
	minimap_cave.clear()
	big_debris.clear()
	$Ash.clear()
	$Lava.clear()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
		enemy.free()
	for drilled_hole in get_tree().get_nodes_in_group("drilled_holes"):
		drilled_hole.remove_from_group("drilled_holes")
		drilled_hole.free()
	for object in get_tree().get_nodes_in_group("misc_objects"):
		object.remove_from_group("misc_objects")
		object.free()
	for light in get_tree().get_nodes_in_group("lights"):
		light.remove_from_group("lights")
		light.free()
	for debris in get_tree().get_nodes_in_group("debris"):
		debris.remove_from_group("debris")
		debris.free()
	for enemy_icon in get_tree().get_nodes_in_group("enemy_icons"):
		enemy_icon.remove_from_group("enemy_icons")
		enemy_icon.free()
	for proj in get_tree().get_nodes_in_group("enemy_projectiles"):
		proj.remove_from_group("enemy_projectiles")
		if is_ancestor_of(proj):
			proj.free()
	for proj in get_tree().get_nodes_in_group("player_projectiles"):
		proj.remove_from_group("player_projectiles")
		if is_ancestor_of(proj):
			proj.free()
	for deposit in deposits:
		deposits[deposit].free()
	for chest_str in chests:
		chests[chest_str].node.free()
	for tile in tiles_touched_by_laser:
		tiles_touched_by_laser[tile].bar.free()
	tiles_touched_by_laser.clear()
	for tile in debris_touched_by_laser:
		if is_instance_valid(debris_touched_by_laser[tile].bar):
			debris_touched_by_laser[tile].bar.free()
	debris_touched_by_laser.clear()
	chests.clear()
	deposits.clear()

func set_avg_dmg():
	var avg_dmg:float = 6.0 * difficulty / def / rover_size * armor_damage_mult
	var dmg_to_HP_ratio:float = avg_dmg / total_HP
	var gradient:Gradient = preload("res://Resources/IntensityGradient.tres")
	var color:String = gradient.sample(inverse_lerp(0.005, 0.3, dmg_to_HP_ratio)).to_html(false)
	$UI2/CaveInfo/AvgDmg.text = "%s: %s" % [tr("AVERAGE_ENEMY_DAMAGE"), Helper.format_num(avg_dmg, true)]
	$UI2/CaveInfo/AvgDmg["theme_override_colors/font_color"] = color
	
func generate_cave(first_floor:bool, going_up:bool):
	if enhancements.has("armor_12") and HP < total_HP * 0.2:
		HP = total_HP * 0.2
	set_avg_dmg()
	cave_darkness = cave_floor * 0.1
	if rover_data.MK >= 2:
		cave_darkness /= 1.1
	if rover_data.MK >= 3:
		cave_darkness /= 1.1
	var darkness_mod:float = modifiers.get("darkness", 1.0)
	cave_darkness *= darkness_mod
	cave_darkness = clamp(cave_darkness, 0.0, 1.0 - ((0.2 / darkness_mod) if darkness_mod > 1.0 else 0.2))
	#if not game.objective.is_empty() and game.objective.type == game.ObjectiveType.CAVE:
		#game.objective.current += 1
	rover.get_node("AshParticles").modulate = Color.WHITE * (1.0 - cave_darkness)
	rover.get_node("AshParticles").modulate.a = 1.0
	mining_laser.get_node("PointLight2D2").energy = (0.5 + pow(cave_darkness, 2) * 6) / pow(light_strength_mult, 2) * 1.0
	var depth_modulate = Color.WHITE
	if cave_floor >= 16:
		depth_modulate = Color.PURPLE
	elif cave_floor >= 8:
		depth_modulate = Color.BLUE
	cave_wall.modulate = star_mod * depth_modulate * (1.0 - cave_darkness) * (Color(0.5, 0.5, 1.0) if cave_floor >= 8 else Color.WHITE)
	var BG_mod = star_mod * (1.0 - cave_darkness)
	BG_mod.a = 1.0
	if p_i.has("lake"):
		BG_mod = Data.lake_colors[p_i.lake.element][p_i.lake.state]
		cave_wall.modulate *= Data.lake_colors[p_i.lake.element][p_i.lake.state]
		cave_BG.material.set_shader_parameter("brightness", 1.1)
		cave_BG.material.set_shader_parameter("contrast", 1.1)
	cave_BG.material.set_shader_parameter("modulate_color", BG_mod)
	hole.modulate = star_mod * (1.0 - cave_darkness)
	hole.modulate.a = 1.0
	$WorldEnvironment.environment.adjustment_saturation = (1.0 - cave_darkness)
	if Settings.enable_shaders:
		$Floor.material.set_shader_parameter("star_mod", lerp(star_mod, Color.WHITE, clamp(cave_floor * 0.125, 0, 1)))
		$Floor.material.set_shader_parameter("strength", max(1.0, brightness_mult - 0.1 * (cave_floor - 1)))
	rover_light.energy = cave_darkness * 0.3
	$UI2/CaveInfo/Difficulty.text = "%s: %s" % [tr("DIFFICULTY"), Helper.format_num(difficulty, true)]
	var rng = RandomNumberGenerator.new()
	$UI2/CaveInfo/Floor.text = "B%sF" % [cave_floor]
	var noise = FastNoiseLite.new()
	var lava_noise = FastNoiseLite.new()
	var first_time:bool = cave_floor > len(seeds)
	if first_time:
		var sd = randi()
		rng.set_seed(sd)
		noise.seed = sd
		lava_noise.seed = sd * 2
		seeds.append(sd)
		tiles_mined.append([])
		enemies_rekt.append([])
		debris_rekt.append([])
		chests_looted.append([])
		partially_looted_chests.append({})
		hole_exits.append({"hole":-1, "exit":-1})
	else:
		if len(debris_rekt) < cave_floor:
			debris_rekt.append([])
		rng.set_seed(seeds[cave_floor - 1])
		noise.seed = seeds[cave_floor - 1]
		lava_noise.seed = seeds[cave_floor - 1] * 2
	noise.fractal_octaves = 1
	noise.frequency = 1.0 / tile.cave.period
	lava_noise.fractal_octaves = 1
	lava_noise.frequency = 1.0 / rng.randi_range(30, 120)
	camera.zoom = Vector2.ONE * rover_size / 2.5
	$Rover.scale = Vector2.ONE * rover_size
	var seeking_proj = enhancements.has("laser_3")
	var debris_height:int = -1020
	var ash_tiles = []
	var lava_tiles = []
	var walls = []
	#Generate cave
	for i in cave_size:
		for j in cave_size:
			var level = noise.get_noise_2d(i * 10.0, j * 10.0)
			var tile_id:int = get_tile_index(Vector2(i, j))
			if p_i.has("lake"):
				cave_BG.set_cell(Vector2i(i, j), 9, Vector2i.ZERO)
			else:
				cave_BG.set_cell(Vector2i(i, j), tile_type, Vector2i.ZERO)
				# Decorative pebbles
	#			for k in rng.randi_range(0, 2):
	#				var debris = Sprite2D.new()
	#				debris.texture = preload("res://Graphics/Cave/DebrisCave.png")
	#				debris.hframes = 6
	#				debris.frame = rng.randi_range(0, 5)
	#				add_sibling($Ash, debris)
	#				debris.modulate = tile_mod
	#				debris.rotation_degrees = rng.randf_range(0, 360)
	#				debris.position = Vector2(i, j) * 200 + Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
	#				debris.scale = Vector2.ONE * (pow(rng.randf(), 4) / 2.0 + 0.2)
				if rng.randf() < debris_amount / 2.0:
					var debris = Sprite2D.new()
					debris.texture = load("res://Graphics/Cave/DebrisCaveDecoration%s.png" % rng.randi_range(1, 3))
					add_child(debris)
					debris.z_index = -1021
					debris.modulate = (star_mod * tile_avg_mod + Color(0.2, 0.2, 0.2, 1.0) * rng.randf_range(0.9, 1.1)) * (1.0 - cave_darkness)
					debris.modulate.a = 1.0
					debris.rotation_degrees = rng.randf_range(0, 360)
					debris.position = Vector2(i, j) * 200 + Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))
					debris.scale = Vector2.ONE * rng.randf_range(1.0, 1.4)
					debris.add_to_group("debris")
			if level > 0:
				# Big boi rocks with collision detection
				if not p_i.has("lake") and rng.randf() < debris_amount / 12.0:
					var debris = preload("res://Scenes/Debris.tscn").instantiate()
					debris.sprite_frame = rng.randi_range(0, 5)
					debris.time_speed = time_speed
					var debris_mod = (star_mod * tile_avg_mod + Color(0.2, 0.2, 0.2, 1.0) * rng.randf_range(0.9, 1.1)) * (1.0 - cave_darkness)
					debris_mod.a = 1.0
					debris.rotation_degrees = rng.randf_range(0, 360)
					var rand_scale_x:float
					if volcano_mult > 1 and not artificial_volcano and rng.randf() < remap(cave_floor, 1, 16, 0.05, 1.0):
						rand_scale_x = -log(rng.randf()) + 0.5
						debris.lava_intensity = 1.0 + log(rng.randf_range(1.0, volcano_mult))
						debris_mod = Color.WHITE * (0.9 + debris.lava_intensity / 10.0)
						debris.get_node("Lava").range_z_min = debris_height
						debris.get_node("Lava").range_z_max = debris_height
					else:
						rand_scale_x = -log(rng.randf()) / 1.2 + 0.5
					debris.get_node("Sprite2D").z_index = debris_height
					debris_height += 1
					debris.scale = Vector2.ONE * rand_scale_x
					debris.position = Vector2(i, j) * 200 + Vector2(100, 100) + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80)) / debris.scale / 2.0
					if is_aurora_cave and rng.randf() < 0.05:
						debris_mod = Color.WHITE
						debris.aurora_intensity = 1.0 + log(rng.randf_range(1.0, au_int + 1.0))
					if debris_rekt[cave_floor - 1].has(tile_id):
						debris.free()
					else:
						debris.add_to_group("debris")
						debris.id = tile_id
						add_child(debris)
						big_debris[tile_id] = debris
						debris.get_node("Sprite2D").material.set_shader_parameter("modulate_color", debris_mod)
				if volcano_mult > 1.0:
					if cave_floor <= 8 and level < remap(cave_floor, 1, 8, 0.6, 0.0):
						ash_tiles.append(Vector2(i, j))
				minimap_cave.set_cell(Vector2i(i, j), tile_type, Vector2i.ZERO)
				tiles.append(Vector2(i, j))
				astar_node.add_point(tile_id, Vector2(i, j))
				if rng.randf() < 0.006 * min(5, cave_floor) * (modifiers.enemy_number if modifiers.has("enemy_number") else 1.0):
					var HX_node = HX1_scene.instantiate()
					var type:int = rng.randi_range(1, 4)
					HX_node.set_script(load("res://Scripts/Cave/HX%s.gd" % [type]))
					var _class:int = 1
					if rng.randf() < log(difficulty) / log(100) - 1.0:
						_class += 1
					if rng.randf() < log(difficulty / 100.0) / log(100) - 1.0:
						_class += 1
					if rng.randf() < log(difficulty / 10000.0) / log(100) - 1.0:
						_class += 1
					HX_node._class = _class
					if modifiers.has("enemy_size"):
						HX_node.scale *= modifiers.enemy_size
					HX_node.get_node("SeekingProjSeekArea").monitorable = seeking_proj
					HX_node.get_node("SeekingProjSeekArea").monitoring = seeking_proj
					if seeking_proj:
						HX_node.get_node("SeekingProjSeekArea").connect("body_entered",Callable(HX_node,"on_proj_enter"))
						HX_node.get_node("SeekingProjSeekArea").connect("body_exited",Callable(HX_node,"on_proj_exit"))
					HX_node.HP = round(15 * difficulty * rng.randf_range(0.8, 1.2) * (modifiers.enemy_HP if modifiers.has("enemy_HP") else 1.0))
					HX_node.def = rng.randi_range(3, 6)
					HX_node.atk = round((10 - HX_node.def) * difficulty * rng.randf_range(0.9, 1.1))
					if enemies_rekt[cave_floor - 1].has(tile_id):
						HX_node.free()
						continue
					HX_node.get_node("Sprite2D").texture = load("res://Graphics/HX/%s_%s.png" % [_class, type])
					HX_node.get_node("Sprite2D").material.set_shader_parameter("aurora", is_aurora_cave)
					if volcano_mult == 1:
						HX_node.get_node("Sprite2D").material.set_shader_parameter("light", 1.0 - cave_darkness)
					HX_node.total_HP = HX_node.HP
					HX_node.cave_ref = self
					HX_node.a_n = astar_node
					HX_node.cave_tm = cave_BG
					HX_node.spawn_tile = tile_id
					HX_node.add_to_group("enemies")
					HX_node.position = Vector2(i, j) * 200 + Vector2(100, 100)
					add_child(HX_node)
					HX_tiles.append(tile_id)
					var enemy_icon = Sprite2D.new()
					enemy_icon.scale *= 0.08
					enemy_icon.texture = enemy_icon_scene
					MM.add_child(enemy_icon)
					HX_node.MM_icon = enemy_icon
					enemy_icon.add_to_group("enemy_icons")
			else:
				walls.append(Vector2i(i, j))
				var rand:float = rng.randf()
				var rand2:float = rng.randf()
				var ch = 0.02 * pow(pow(2, min(12, cave_floor) - 1) / 3.0, 0.4)
				if rand < ch:
					var met_spawned:String = "lead"
					var base_rarity:float = 1.0
					for met in game.met_info:
						var rarity:float = game.met_info[met].rarity
						if cave_floor >= 8:
							rarity = pow(rarity, remap(cave_floor, 8, 32, 0.9, 0.6))
						if is_aurora_cave:
							rarity = pow(rarity, 0.9)
						if volcano_mult > 1 and not artificial_volcano:
							rarity = pow(rarity, 0.9)
						if rand2 < 1 / (rarity + 1):
							base_rarity = game.met_info[met].rarity
							met_spawned = met
					if met_spawned != "":
						var deposit = deposit_scene.instantiate()
						deposit.rsrc_texture = game.metal_textures[met_spawned]
						deposit.rsrc_name = met_spawned
						deposit.amount = int(20 * rng.randf_range(0.1, 0.15) * min(5, pow(difficulty, 0.3)))
						add_child(deposit)
						deposit.position = cave_wall.map_to_local(Vector2(i, j)) - Vector2(100, 100)
						deposit.modulate *= log(base_rarity) / 6.5 + 1.0
						deposits[str(tile_id)] = deposit
			if volcano_mult > 1.0:
				var lava_level = lava_noise.get_noise_2d(i * 10.0, j * 10.0)
				if lava_level > max(remap(cave_floor, 1, 16, 0.8, 0.0), 0.0) * clamp(remap(volcano_mult, 8, 14, 1.0, 0.3), 0.0, 1.0):
					lava_tiles.append(Vector2i(i, j))
			elif cave_floor >= 12:
				var lava_level = lava_noise.get_noise_2d(i * 10.0, j * 10.0)
				if lava_level > max(remap(cave_floor, 12, 24, 0.8, 0.0), 0.0):
					lava_tiles.append(Vector2i(i, j))
	
	$Ash.set_cells_terrain_connect(ash_tiles, 0, 0)
	$Lava.set_cells_terrain_connect(lava_tiles, 0, 0)
	$Ash.modulate = Color.WHITE
	#$Lava.set_layer_modulate(0, star_mod * (1.0 - cave_darkness))
	#Add unpassable tiles at the cave borders
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(Vector2i(i, -1), 1, Vector2i.ZERO)
		cave_wall.set_cell(Vector2i(i, -2), 1, Vector2i.ZERO)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(Vector2i(i, cave_size), 1, Vector2i.ZERO)
		cave_wall.set_cell(Vector2i(i, cave_size + 1), 1, Vector2i.ZERO)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(Vector2i(-1, i), 1, Vector2i.ZERO)
		cave_wall.set_cell(Vector2i(-2, i), 1, Vector2i.ZERO)
	for i in range(-1, cave_size + 1):
		cave_wall.set_cell(Vector2i(cave_size, i), 1, Vector2i.ZERO)
		cave_wall.set_cell(Vector2i(cave_size + 1, i), 1, Vector2i.ZERO)
	#tiles = cave_wall.get_used_cells(-1)
	for tile in tiles:#tile is a Vector2D
		connect_points(tile)
	var tiles_remaining = astar_node.get_point_ids()
	#Create rooms for logic that uses the size of rooms
	while not tiles_remaining.is_empty():
		var room = get_connected_tiles(tiles_remaining[0])
		for tile_index in room:
			tiles_remaining.remove_at(tiles_remaining.find(tile_index))
		rooms.append({"tiles":room, "size":len(room)})
	rooms.sort_custom(Callable(self,"sort_size"))
	#Generate treasure chests
	for room in rooms:
		var n = room.size
		for tile in room.tiles:
			var rand = rng.randf()
			var formula = 0.1 / pow(n, 0.9) * pow(cave_floor, 0.8) * (modifiers.chest_number if modifiers.has("chest_number") else 1.0)
			if rand < formula:
				var tier:int = min(-log(rand/formula) / 2.5 + 1, 5)
				var contents:Dictionary = generate_treasure(tier, rng)
				if contents.is_empty() or chests_looted[cave_floor - 1].has(int(tile)):
					continue
				if partially_looted_chests[cave_floor - 1].has(str(tile)):
					contents = partially_looted_chests[cave_floor - 1][str(tile)].duplicate(true)
				var chest = object_scene.instantiate()
				if tier == 1:
					chest.modulate = Color(0.83, 0.4, 0.27, 1.0)
				elif tier == 2:
					chest.modulate = Color(0, 0.79, 0.0, 1.0)
				elif tier == 3:
					chest.modulate = Color(0, 0.5, 0.79, 1.0)
				elif tier == 4:
					chest.modulate = Color(0.7, 0, 0.79, 1.0)
				elif tier == 5:
					chest.modulate = Color(0.85, 1.0, 0, 1.0)
				chest.modulate *= (1.0 - cave_darkness)
				chest.modulate.a = 1
				chest.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Objects/Chest.png")
				chest.get_node("Area2D").connect("area_entered",Callable(self,"on_chest_entered").bind(str(tile)))
				chest.get_node("Area2D").connect("area_exited",Callable(self,"on_chest_exited"))
				chest.scale *= 0.8
				chest.position = cave_BG.map_to_local(get_tile_pos(tile))
				chests[str(tile)] = {"node":chest, "contents":contents, "tier":tier}
				add_child(chest)
	#Remove already-mined tiles
	for i in cave_size:
		for j in cave_size:
			var tile_id:int = get_tile_index(Vector2(i, j))
			if tiles_mined[cave_floor - 1].has(tile_id):
				minimap_cave.set_cell(Vector2i(i, j), tile_type, Vector2i.ZERO)
				astar_node.add_point(tile_id, Vector2(i, j))
				connect_points(Vector2(i, j), true)
				walls.erase(Vector2i(i, j))
				if deposits.has(str(tile_id)):
					deposits[str(tile_id)].queue_free()
					deposits.erase(str(tile_id))
	cave_wall.set_cells_terrain_connect(walls, 0, 0)
	#Assigns each enemy the room number they're in
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var _id = get_tile_index(cave_BG.local_to_map(enemy.position))
		var i = 0
		for room in rooms:
			if _id in room.tiles:
				enemy.room = i
			i += 1
	var pos:Vector2
	var rand_hole:int = rooms[0].tiles[rng.randi_range(0, len(rooms[0].tiles) - 1)]
	var rand_spawn:int
	if first_time:
		rand_spawn = rand_hole
		hole_exits[cave_floor - 1].hole = rand_hole
	else:
		rand_hole = hole_exits[cave_floor - 1].hole
		rand_spawn = hole_exits[cave_floor - 1].exit
	if first_floor:
		#Determines the tile where the entrance will be. It has to be adjacent to an unpassable tile
		var spawn_edge_tiles = []
		var j = 0
		while len(spawn_edge_tiles) == 0:
			for tile_id in rooms[j].tiles:
				if first_time or tile_id == rand_spawn:
					var top = tile_id / cave_size == 0
					var left = tile_id % cave_size == 0
					var bottom = tile_id / cave_size == cave_size - 1
					var right = tile_id % cave_size == cave_size - 1
					if left:
						spawn_edge_tiles.append({"id":tile_id, "dir":-PI/2})
					elif right:
						spawn_edge_tiles.append({"id":tile_id, "dir":PI/2})
					elif top:
						spawn_edge_tiles.append({"id":tile_id, "dir":0})
					elif bottom:
						spawn_edge_tiles.append({"id":tile_id, "dir":PI})
			j += 1
		$Exit/Sprite2D.texture = preload("res://Graphics/Cave/Objects/exit.png")
		$Exit/Sprite2D.modulate = star_mod * 1.5
		$Exit/GPUParticles2D.emitting = false
		$Exit/ExitColl.disabled = false
		var rot = spawn_edge_tiles[0].dir
		$Exit/GoUpColl.disabled = true
		var breaker:int = 0
		while rand_hole == rand_spawn and breaker < 10:
			breaker += 1
			var rand_id = rng.randi_range(0, len(spawn_edge_tiles) - 1)
			rand_spawn = spawn_edge_tiles[rand_id].id
			rot = spawn_edge_tiles[rand_id].dir
		pos = get_tile_pos(rand_spawn) * 200 + Vector2(100, 100)
		exit.rotation = rot
		MM_exit.rotation = rot
	else:
		exit.rotation = 0
		MM_exit.rotation_degrees = 0
		$Exit/Sprite2D.texture = preload("res://Graphics/Cave/Objects/go_up.png")
		$Exit/Sprite2D.modulate = Color(1, 1, 3, 1)
		$Exit/GPUParticles2D.emitting = true
		$Exit/ExitColl.disabled = true
		$Exit/GoUpColl.disabled = false
		while rand_hole == rand_spawn:
			rand_spawn = get_tile_index(tiles[rng.randi_range(0, len(tiles) - 1)])
		pos = get_tile_pos(rand_spawn) * 200 + Vector2(100, 100)
	if cave_floor == num_floors:
		hole.get_node("CollisionShape2D").disabled = true
		hole.visible = false
		MM_hole.visible = false
	else:
		hole.get_node("CollisionShape2D").disabled = false
		hole.visible = true
		MM_hole.visible = true
	#No treasure chests or rocks at spawn/hole
	if big_debris.has(rand_hole):
		big_debris[rand_hole].queue_free()
	if big_debris.has(rand_spawn):
		big_debris[rand_spawn].queue_free()
	if chests.has(str(rand_hole)):
		chests[str(rand_hole)].node.queue_free()
		chests.erase(str(rand_hole))
	if chests.has(str(rand_spawn)):
		chests[str(rand_spawn)].node.queue_free()
		chests.erase(str(rand_spawn))
	#A way to check whether cave has the relic for 2nd ship
	if tile.cave.has("special_cave") and tile.cave.special_cave == 5 and cave_floor == 3:
		var relic = object_scene.instantiate()
		relic.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Objects/Relic.png")
		relic.get_node("Area2D").connect("body_entered",Callable(self,"on_relic_entered"))
		relic.get_node("Area2D").connect("body_exited",Callable(self,"on_relic_exited"))
		var relic_tile = rooms[0].tiles[-1]
		relic.position = cave_BG.map_to_local(get_tile_pos(relic_tile))
		add_child(relic)
		relic.add_to_group("misc_objects")
	
	#Wormhole
	if cave_floor == num_floors:
		wormhole = object_scene.instantiate()
		wormhole.get_node("Sprite2D").texture = null
		var wormhole_texture = preload("res://Scenes/Wormhole.tscn").instantiate()
		wormhole.add_child(wormhole_texture)
		wormhole.get_node("Area2D").connect("area_entered",Callable(self,"on_WH_entered"))
		wormhole.get_node("Area2D").connect("area_exited",Callable(self,"_on_area_exited"))
		var wormhole_tile = rooms[0].tiles[1]
		wormhole.position = cave_BG.map_to_local(get_tile_pos(wormhole_tile))
		add_child(wormhole)
		enable_light(wormhole)
	else:
		if is_instance_valid(wormhole):
			wormhole.free()
	
#	if not boss_cave:
#		#A map is hidden on the first 8th floor of the cave you reach in a galaxy outside Milky Way
#		if len(game.ship_data) == 2 and game.c_g_g != 0 and game.c_c == 0:
#			if tile.cave.has("special_cave") and not game.third_ship_hints.parts[tile.cave.special_cave] and cave_floor == num_floors:
#				var part = object_scene.instantiate()
#				part.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Objects/ShipPart.png")
#				part.get_node("Area2D").connect("body_entered",Callable(self,"on_ShipPart_entered"))
#				var part_tile = rooms[0].tiles[0]
#				part.position = cave_BG.map_to_local(get_tile_pos(part_tile)) + Vector2(100, 100)
#				part.add_to_group("misc_objects")
#				add_child(part)
#				enable_light(part)
#			if game.third_ship_hints.has("map_found_at") and cave_floor == 8 and (game.third_ship_hints.map_found_at in [-1, id]) and game.third_ship_hints.spawn_galaxy == game.c_g:
#				var map = object_scene.instantiate()
#				map.get_node("Sprite2D").texture = preload("res://Graphics/Cave/Objects/Map.png")
#				map.get_node("Area2D").connect("body_entered",Callable(self,"on_map_entered"))
#				map.get_node("Area2D").connect("body_exited",Callable(self,"on_map_exited"))
#				var map_tile:Vector2
#				if game.third_ship_hints.map_found_at == -1:
#					map_tile = pos
#					if map_tile.x < 400:
#						map_tile.x += 400
#					elif map_tile.x > cave_size * 200 - 400:
#						map_tile.x -= 400
#					else:
#						map_tile.x += sign(randf_range(-1, 1)) * 400
#					if map_tile.y < 400:
#						map_tile.y += 400
#					elif map_tile.y > cave_size * 200 - 400:
#						map_tile.y -= 400
#					else:
#						map_tile.y += sign(randf_range(-1, 1)) * 400
#					game.third_ship_hints.map_found_at = id
#					game.third_ship_hints.map_pos = map_tile
#				else:
#					map_tile = game.third_ship_hints.map_pos
#				$UI2/Ship2Map.refresh()
#				map.position = map_tile
#				add_child(map)
#				enable_light(map)
#				map.add_to_group("misc_objects")
#				cave_BG.set_cellv(cave_BG.local_to_map(map_tile), tile_type)
#				cave_wall.set_cellv(cave_wall.local_to_map(map_tile), -1)
#				minimap_cave.set_cellv(minimap_cave.local_to_map(map_tile), tile_type)
#				cave_wall.update_bitmask_region()
#				var st = str(get_tile_index(cave_BG.local_to_map(map_tile)))
#				if deposits.has(st):
#					var deposit = deposits[st]
#					remove_child(deposit)
#					deposits.erase(st)
#					deposit.free()
#		elif game.c_p_g == game.fourth_ship_hints.op_grill_planet:
#			if cave_floor == 3 and (game.fourth_ship_hints.op_grill_cave_spawn == -1 or game.fourth_ship_hints.op_grill_cave_spawn == id) and not game.fourth_ship_hints.emma_joined:
#				var op_grill:NPC = preload("res://Scenes/NPC.tscn").instantiate()
#				op_grill.NPC_id = 3
#				if game.fourth_ship_hints.op_grill_cave_spawn == -1:
#					op_grill.connect_events(1, $UI2/Dialogue)
#				elif not (game.fourth_ship_hints.manipulators[0] and game.fourth_ship_hints.manipulators[1] and game.fourth_ship_hints.manipulators[2] and game.fourth_ship_hints.manipulators[3] and game.fourth_ship_hints.manipulators[4] and game.fourth_ship_hints.manipulators[5]):
#					op_grill.connect_events(2, $UI2/Dialogue)
#				elif (game.mets.amethyst < 1000000 or game.mets.sapphire < 1000000 or game.mets.topaz < 1000000 or game.mets.quartz < 1000000 or game.mets.ruby < 1000000 or game.mets.emerald < 1000000) and not game.fourth_ship_hints.boss_rekt:
#					op_grill.connect_events(3, $UI2/Dialogue)
#				elif not game.fourth_ship_hints.boss_rekt:
#					op_grill.connect_events(4, $UI2/Dialogue)
#				elif not game.fourth_ship_hints.emma_free or not game.fourth_ship_hints.artifact_found:
#					op_grill.connect_events(5, $UI2/Dialogue)
#				else:
#					op_grill.connect_events(6, $UI2/Dialogue)
#				var part_tile = rooms[0].tiles[5]
#				op_grill.position = cave_BG.map_to_local(get_tile_pos(part_tile)) + Vector2(100, 100)
#				add_child(op_grill)
#				op_grill.name = "OPGrill"
#				op_grill.add_to_group("misc_objects")
#			elif game.fourth_ship_hints.op_grill_cave_spawn != -1 and game.fourth_ship_hints.op_grill_cave_spawn != id:
#				var gems = ["Amethyst", "Emerald", "Quartz", "Topaz", "Ruby", "Sapphire"]
#				for i in 6:
#					if cave_floor == i + 2 and not game.fourth_ship_hints.manipulators[i]:
#						var manip = object_scene.instantiate()
#						manip.get_node("Sprite2D").texture = load("res://Graphics/Cave/Objects/%sManipulator.png" % gems[i])
#						manip.get_node("Area2D").connect("body_entered",Callable(self,"on_Manipulator_entered").bind(i, gems[i]))
#						var manip_tile
#						if len(rooms) > 1:
#							manip_tile = rooms[1].tiles[0]
#						else:
#							manip_tile = rooms[0].tiles[5]
#						manip.position = cave_BG.map_to_local(get_tile_pos(manip_tile)) + Vector2(100, 100)
#						manip.add_to_group("misc_objects")
#						add_child(manip)
#						enable_light(manip)
#						break
		
	var hole_pos = get_tile_pos(rand_hole) * 200 + Vector2(100, 100)
	if first_time:
		hole_exits[cave_floor - 1].exit = rand_spawn
	if hole_exits[cave_floor - 1].has("drilled_holes"):
		for id in hole_exits[cave_floor - 1].drilled_holes:
			add_hole(id)
	hole.position = hole_pos
	if going_up:
		rover.position = hole_pos
		camera.position = hole_pos
	else:
		rover.position = pos
		camera.position = pos
	exit.position = pos
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_rand()
	var cave_adjective = ""
	if num_floors >= 12:
		cave_adjective = " large"
	if num_floors >= 24:
		cave_adjective = " huge"
	var format_dict = {"adjective":cave_adjective, "volcanic":" volcanic" if volcano_mult > 1.0 else "", "aurora":"" if not is_aurora_cave else (" illuminated by%s auroras" % [" powerful" if aurora_mult > 10.0 else ""])}
	var details = ""
	if cave_floor < 8:
		details = "Exploring a{adjective}{volcanic} cave{aurora}".format(format_dict)
	elif cave_floor < 16:
		details = "Traversing the depths of a{adjective}{volcanic} cave{aurora}".format(format_dict)
	else:
		details = "Scouting the dark chasms of a{adjective}{volcanic} cave{aurora}".format(format_dict)
	var state = "Floor %s / %s" % [cave_floor, num_floors]
	var small_image_text = "Rover HP: %s / %s" % [Helper.format_num(HP), Helper.format_num(total_HP)]
	Helper.refresh_discord(details, state, "rover", small_image_text)

func add_hole(id:int):
	var drilled_hole = preload("res://Scenes/CaveHole.tscn").instantiate()
	drilled_hole.position = get_tile_pos(id) * 200 + Vector2(100, 100)
	drilled_hole.add_to_group("drilled_holes")
	add_child(drilled_hole)
	drilled_hole.connect("area_entered",Callable(self,"_on_Hole_area_entered"))
	drilled_hole.connect("area_exited",Callable(self,"_on_area_exited"))

func enable_light(node):
	node.get_node("PointLight2D").enabled = true
	node.get_node("Shadow").visible = false

func on_chest_entered(_area, tile:String):
	var chest_rsrc = chests[tile].contents
	active_chest = tile
	active_type = "chest"
	var vbox = $UI2/Panel/VBoxContainer
	reset_panel_anim()
	for child in vbox.get_children():
		child.free()
	var tier_txt = Label.new()
	tier_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_txt.text = tr("TIER_X_CHEST") % [chests[tile].tier]
	vbox.add_child(tier_txt)
	Helper.put_rsrc(vbox, 32, chest_rsrc, false)
	var take_all = Label.new()
	take_all.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	take_all.text = tr("TAKE_ALL")
	vbox.add_child(take_all)
	$UI2/Panel.visible = true
	$UI2/Panel.modulate.a = 1

func on_chest_exited(area:Area2D):
	call_deferred("hide_panel", true)

func hide_panel(hiding_chest:bool = false):
	if len($Rover/InteractArea.get_overlapping_areas()) == 0:
		active_type = ""
		if hiding_chest:
			active_chest = "-1"
		$UI2/Panel.visible = false
	
func on_relic_exited(_body):
	$UI2/Relic.visible = false

func on_map_exited(_body):
	$UI2/Ship2Map.visible = false
	$UI2/Panel.visible = false
	active_type = ""

func generate_treasure(tier:int, rng:RandomNumberGenerator):
	var contents = {	"money":round(rng.randf_range(1500, 1800) * pow(tier, 3.0) * difficulty * exp(cave_floor / 6.0)),
						"minerals":round(rng.randf_range(100, 150) * pow(tier, 3.0) * difficulty * exp(cave_floor / 9.0)),
						Item.HELIX_CORE1:int(rng.randf_range(0.2, 0.6) * pow(tier, 1.8) * pow(difficulty, 0.7))}
	if contents[Item.HELIX_CORE1] > 128:
		contents[Item.HELIX_CORE2] = int(contents.hx_core / 128.0)
		contents[Item.HELIX_CORE1] %= 128
		if contents[Item.HELIX_CORE1] == 0:
			contents.erase(Item.HELIX_CORE1)
		if contents[Item.HELIX_CORE2] > 128:
			contents[Item.HELIX_CORE3] = int(contents[Item.HELIX_CORE2] / 128.0)
			contents[Item.HELIX_CORE2] %= 128
			if contents[Item.HELIX_CORE2] == 0:
				contents.erase("hx_core2")
			if contents[Item.HELIX_CORE3] > 128:
				contents[Item.HELIX_CORE4] = int(contents[Item.HELIX_CORE3] / 128.0)
				contents[Item.HELIX_CORE3] %= 128
				if contents[Item.HELIX_CORE3] == 0:
					contents.erase("hx_core3")
	if contents.has(Item.HELIX_CORE1) and contents[Item.HELIX_CORE1] == 0:
		contents.erase(Item.HELIX_CORE1)
	for met in game.met_info:
		var met_value = game.met_info[met]
		var rarity = met_value.rarity
		if cave_floor >= 8:
			rarity = pow(rarity, remap(cave_floor, 8, 32, 0.9, 0.6))
		if is_aurora_cave:
			rarity = pow(rarity, 0.9)
		if volcano_mult > 1 and not artificial_volcano:
			rarity = pow(rarity, 0.9)
		if rng.randf() < 1 / (rarity + 1):
			contents[met] = Helper.clever_round(10 * rng.randf_range(0.5, 1.0) / rarity * pow(tier, 2.0) * difficulty * exp(cave_floor / 10.0) * treasure_mult * game.u_i.planck)
	return contents

func connect_points(tile:Vector2, bidir:bool = false):
	var tile_index = get_tile_index(tile)
	var neighbor_tiles = PackedVector2Array([
		tile + Vector2.RIGHT,
		tile + Vector2.LEFT,
		tile + Vector2.DOWN,
		tile + Vector2.UP,
		tile + Vector2.UP + Vector2.RIGHT,
		tile + Vector2.RIGHT + Vector2.DOWN,
		tile + Vector2.DOWN + Vector2.LEFT,
		tile + Vector2.LEFT + Vector2.UP,
	])
	for neighbor_tile in neighbor_tiles:
		var neighbor_tile_index = get_tile_index(neighbor_tile)
		if not astar_node.has_point(neighbor_tile_index):
			continue
		if cave_wall.get_cell_tile_data(neighbor_tile) == null:
			astar_node.connect_points(tile_index, neighbor_tile_index, bidir)

var HP_tween

func update_health_bar(_HP):
	HP = _HP
	var gradient:Gradient = preload("res://Resources/HPGradient.tres")
	var bar_color:Color = gradient.sample(inverse_lerp(0.0, 1.0, HP / total_HP)).to_html(false)
	$UI2/HP/Bar.tint_progress = bar_color
	$UI2/HP/Bar.tint_over = bar_color
	$UI2/HP/Bar.tint_under = bar_color
	$Rover/Bar.value = HP

var mouse_pos = Vector2.ZERO
var tile_highlighted_for_mining:int = -1
var mining_debris:int = -1

func update_ray():
	var _inv:Dictionary
	var _tile_highlight
	var left_type:String = inventory[curr_slot].type if not inventory[curr_slot].is_empty() else ""
	var right_type:String = right_inventory[0].type if not right_inventory[0].is_empty() else ""
	ray.enabled = "rover_mining" in [left_type, right_type]
	var holding_click:bool
	if left_type == "rover_mining":
		_inv = inventory[curr_slot]
		_tile_highlight = tile_highlight_left
		holding_click = use_item_node.button_pressed
	elif right_type == "rover_mining":
		_inv = right_inventory[0]
		_tile_highlight = tile_highlight_right
		holding_click = Input.is_action_pressed("right_click")
	if RoDray.enabled:
		var laser_reach = 9001.0
		RoD.rotation = atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x)
		RoDray.target_position.x = laser_reach
		if RoDray.is_colliding():
			var pos = RoDray.get_collision_point()# + RoDray.target_position / 200.0
			laser_reach = rover.position.distance_to(pos) / rover_size
			RoD_effects.get_node("Sprite2D").visible = true
			RoD_effects.get_node("Particles").emitting = true
			RoD_effects.position = pos
		else:
			RoD_effects.get_node("Sprite2D").visible = false
			RoD_effects.get_node("Particles").emitting = false
		RoD_sprite.scale.x = laser_reach / 16.0
		RoD_sprite.scale.y = 16.0
		RoD.visible = true
		RoD.monitoring = true
		var l:float = (RoDray.get_collision_point() - rover.position).length()
		RoD_coll.shape.b.x = l
		RoD_coll2.shape.b.x = l
	if ray.enabled:
		var laser_reach = Data.rover_mining[_inv.id].rnge
		ray.target_position = (mouse_pos - rover.position).normalized() * laser_reach
		var coll = ray.get_collider()
		mining_p.emitting = holding_click if coll else false
		if coll:
			var pos = ray.get_collision_point() + ray.target_position / 200.0
			laser_reach = rover.position.distance_to(pos) / rover_size
			tile_highlighted_for_mining = get_tile_index(cave_wall.local_to_map(pos))
			var is_wall = coll is TileMapLayer and cave_wall.get_cell_source_id(cave_wall.local_to_map(pos)) == 0
			mining_p.position = pos
			if tile_highlighted_for_mining != -1 and is_wall:
				_tile_highlight.visible = true
				_tile_highlight.position.x = floor(pos.x / 200) * 200 + 100
				_tile_highlight.position.y = floor(pos.y / 200) * 200 + 100
			else:
				tile_highlighted_for_mining = -1
				_tile_highlight.visible = false
			if coll.get_parent() is Debris and holding_click:
				mining_debris = coll.get_parent().id
				if not debris_touched_by_laser.has(mining_debris):
					var circ_bar = preload("res://Scenes/CircleBar.tscn").instantiate()
					add_child(circ_bar)
					circ_bar.light_mask = 0
					circ_bar.scale *= big_debris[mining_debris].scale.x
					circ_bar.position = big_debris[mining_debris].position
					debris_touched_by_laser[mining_debris] = {"bar":circ_bar, "progress":0}
				crack_detector.monitorable = true
				crack_detector.position = pos - rover.position
			else:
				crack_detector.monitorable = false
				mining_debris = -1
		else:
			tile_highlighted_for_mining = -1
			mining_debris = -1
			_tile_highlight.visible = false
		if holding_click:
			mining_laser.get_node("PointLight2D").enabled = Settings.enable_shaders
			mining_laser.get_node("PointLight2D2").enabled = Settings.enable_shaders
			mining_laser.scale.x = laser_reach / 16.0
			mining_laser.scale.y = 16.0
			mining_laser.rotation = atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x)
		mining_laser.visible = holding_click
	else:
		mining_laser.visible = false
		mining_p.emitting = false

var global_mouse_pos = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		global_mouse_pos = event.position
		mouse_pos = global_mouse_pos + camera.position - Vector2(640, 360)
		update_ray()
		var alpha:float = clamp(remap((global_mouse_pos - Vector2(1280, 0)).length(), 0.0, 500.0, -1.0, 1.0), 0.0, 1.0)
		if (inventory[curr_slot].is_empty() or inventory[curr_slot].type != "rover_weapons") and (right_inventory[0].is_empty() or right_inventory[0].type != "rover_weapons"):
			alpha = 1.0
		for MM in $UI.get_children():
			MM.modulate.a = alpha
	else:
		if Input.is_action_just_pressed("spacebar") and dashes_remaining > 0:
			$Rover/DashTimer.start(0.6 / time_speed)
			dashes_remaining -= 1
			var speed_mult2 = min(2.5, rover_size) * time_speed * speed_penalty
			var rot_vec:Vector2 = Vector2.ZERO
			if input_vector != Vector2.ZERO:
				rot_vec = input_vector
			else:
				var sprite = $Rover/Sprite2D
				rot_vec = Vector2(cos(sprite.rotation), sin(sprite.rotation)).normalized() 
			var base_vel:Vector2 = rot_vec * max_speed * speed_mult2
			if enhancements.has("wheels_4"):
				velocity = base_vel * 5.0
			else:
				velocity = base_vel * 3.0
			status_effects.invincible = 0.3
			if enhancements.has("wheels_3"):
				rover.collision_mask = 32
			else:
				rover.collision_mask = 33
		if event.is_action_released("scroll_up"):
			curr_slot -= 1
			if curr_slot < 0:
				curr_slot = len(inventory) - 1
			set_border(curr_slot)
		if event.is_action_released("scroll_down"):
			curr_slot += 1
			if curr_slot >= len(inventory):
				curr_slot = 0
			set_border(curr_slot)
		if ability_timer.is_stopped() and ability_num > 0:
			if Input.is_action_just_pressed("Q") and ability != "":
				if ability == "armor_3":
					ability_timer.start(15.0 / time_speed)
				elif ability == "laser_2":
					RoDray.enabled = true
					if Settings.screen_shake:
						$Camera2D/Screenshake.start(10.0 / time_speed, 15, 4)
					$Rover/RayOfDoom/Sprite2D.material.set_shader_parameter("outline_color", get_color(laser_name))
					$Rover/RayOfDoom/AnimationPlayer.play("RayFade", -1, time_speed)
					ability_timer.start(10.0 / time_speed)
				elif ability == "laser_8":
					ability_timer.start(11.0 / time_speed)
				$UI2/Ability/TextureProgressBar.visible = true
				$UI2/Ability/TextureRect.modulate.a = 0.2
				ability_num -= 1
				$UI2/Ability/Panel/Num.text = str(ability_num)
		if Input.is_action_just_released("M"):
			if not $UI/Error.visible:
				MM.visible = not MM.visible
			minimap_rover.visible = not minimap_rover.visible
		elif Input.is_action_just_released("1") and curr_slot != 0:
			curr_slot = 0
			set_border(curr_slot)
		elif Input.is_action_just_released("2") and curr_slot != 1:
			curr_slot = 1
			set_border(curr_slot)
		elif Input.is_action_just_released("3") and curr_slot != 2:
			curr_slot = 2
			set_border(curr_slot)
		elif Input.is_action_just_released("4") and curr_slot != 3:
			curr_slot = 3
			set_border(curr_slot)
		elif Input.is_action_just_released("5") and curr_slot != 4:
			curr_slot = 4
			set_border(curr_slot)
		elif Input.is_action_just_released("6") and curr_slot != 5 and len(inventory) > 5:
			curr_slot = 5
			set_border(curr_slot)
		elif Input.is_action_just_released("7") and curr_slot != 6 and len(inventory) > 6:
			curr_slot = 6
			set_border(curr_slot)
		elif Input.is_action_just_released("8") and curr_slot != 7 and len(inventory) > 7:
			curr_slot = 7
			set_border(curr_slot)
		elif Input.is_action_just_released("9") and curr_slot != 8 and len(inventory) > 8:
			curr_slot = 8
			set_border(curr_slot)
		elif Input.is_action_just_released("0") and curr_slot != 9 and len(inventory) > 9:
			curr_slot = 9
			set_border(curr_slot)
		if Input.is_action_just_released("E"):
			moving_fast = not moving_fast
			if moving_fast:
				$AnimationPlayer.play("RoverSprint")
			else:
				$AnimationPlayer.play_backwards("RoverSprint")
		if Input.is_action_just_released("F"):
			if active_type == "chest" and chests.has(active_chest):
				var remainders = {}
				var show_notif = false
				var contents = chests[active_chest].contents
				for rsrc in contents:
					if game.cave_filters.has(rsrc):
						if game.cave_filters[rsrc]:
							remainders[rsrc] = contents[rsrc]
							continue
					else:
						game.cave_filters[rsrc] = false
						game.show[rsrc] = true
						add_filter(rsrc)
					var has_weight = true
					if rsrc is int or rsrc == "money" or rsrc == "minerals":
						has_weight = false
					if has_weight:
						var remainder:float = round(add_weight_rsrc(rsrc, contents[rsrc]) * 100) / 100.0
						if remainder != 0:
							show_notif = true
							remainders[rsrc] = remainder
					else:
						add_to_inventory(rsrc, contents[rsrc], remainders)
				if not remainders.is_empty():
					chests[active_chest].contents = remainders.duplicate(true)
					partially_looted_chests[cave_floor - 1][str(active_chest)] = remainders.duplicate(true)
					Helper.put_rsrc($UI2/Panel/VBoxContainer, 32, remainders)
					$UI2/Panel.visible = true
					if show_notif:
						game.popup(tr("WEIGHT_INV_FULL_CHEST"), 1.7)
				else:
					var temp = active_chest
					remove_child(chests[active_chest].node)
					chests[temp].node.queue_free()
					chests.erase(temp)
					chests_looted[cave_floor - 1].append(int(temp))
					game.stats_univ.chests_looted += 1
					game.stats_dim.chests_looted += 1
					game.stats_global.chests_looted += 1
			elif active_type == "exit":
				exit_cave()
			elif active_type == "go_down":
				go_down_cave()
			elif active_type == "go_up":
				remove_cave()
				cave_floor -= 1
				if not tile.has("ash"):
					if cave_floor == 7:
						game.switch_music(preload("res://Audio/cave1.ogg"), time_speed, 0.95 if tile.has("aurora") else 1.0)
					if cave_floor == 15:
						game.switch_music(preload("res://Audio/cave2.ogg"), time_speed, 0.95 if tile.has("aurora") else 1.0)
				if volcano_mult > 1 and not artificial_volcano and is_aurora_cave:
					difficulty /= 2.5
				elif volcano_mult > 1 and not artificial_volcano or is_aurora_cave:
					difficulty /= 2.25
				else:
					difficulty /= 2.0
				generate_cave(true if cave_floor == 1 else false, true)
			$UI2/Panel.visible = false
		if Input.is_action_just_released("minus"):
			minimap_zoom /= 1.5
			minimap_cave.scale = Vector2.ONE * minimap_zoom
			MM_hole.position /= 1.5
			MM_exit.position /= 1.5
		elif Input.is_action_just_released("plus"):
			minimap_zoom *= 1.5
			minimap_cave.scale = Vector2.ONE * minimap_zoom
			MM_hole.position *= 1.5
			MM_exit.position *= 1.5
		if Input.is_action_just_released("J"):
			$UI2/Controls.visible = false
			$UI2/Controls.remove_key("J")
			$UI2/Controls.refresh()
			$UI2/CaveInfo/Ctrls.visible = true
		update_ray()

func go_down_cave():
	remove_cave()
	cave_floor += 1
	if not tile.has("ash"):
		if cave_floor == 8:
			game.switch_music(preload("res://Audio/cave2.ogg"), time_speed, 0.95 if tile.has("aurora") else 1.0)
		elif cave_floor == 16:
			game.switch_music(preload("res://Audio/cave3.ogg"), time_speed, 0.95 if tile.has("aurora") else 1.0)
	if volcano_mult > 1 and not artificial_volcano and is_aurora_cave:
		difficulty *= 2.5
	elif volcano_mult > 1 and not artificial_volcano or is_aurora_cave:
		difficulty *= 2.25
	else:
		difficulty *= 2.0
	generate_cave(false, false)
	if not game.achievement_data.exploration.has("reach_floor_8") and cave_floor == 8:
		game.earn_achievement("exploration", "reach_floor_8")
	if not game.achievement_data.exploration.has("reach_floor_16") and cave_floor == 16:
		game.earn_achievement("exploration", "reach_floor_16")
	if not game.achievement_data.exploration.has("reach_floor_24") and cave_floor == 24:
		game.earn_achievement("exploration", "reach_floor_24")
	if not game.achievement_data.exploration.has("reach_floor_32") and cave_floor == 32:
		game.earn_achievement("exploration", "reach_floor_32")

func add_to_inventory(rsrc, content:float, remainders:Dictionary):
	for i in len(inventory):
		var slot = slots[i]
		if inventory[i].is_empty():
			inventory[i].type = "item"
			inventory[i].id = rsrc
			if rsrc is int:
				slot.get_node("TextureRect").texture = load("res://Graphics/Items/%s/%s.png" % [Item.icon_directory(Item.data[rsrc].type), Item.data[rsrc].icon_name])
			elif rsrc == "money":
				slot.get_node("TextureRect").texture = Data.money_icon
			elif rsrc == "minerals":
				slot.get_node("TextureRect").texture = Data.minerals_icon
			slot.get_node("Label").text = Helper.format_num(content, false, 3)
			inventory[i].num = content
			game.show[rsrc] = true
			break
		if inventory[i].has("id") and str(rsrc) == str(inventory[i].id):
			inventory[i].num += content
			slot.get_node("Label").text = Helper.format_num(inventory[i].num, false, 3)
			break
		elif i == len(inventory) - 1:
			remainders[rsrc] = content

func save_cave_data():
	var cave_data_file = FileAccess.open("user://%s/Univ%s/Caves/%s.hx3~" % [game.c_sv, game.c_u, id], FileAccess.WRITE)
	var cave_data_dict = {
		"seeds":seeds,
		"tiles_mined":tiles_mined,
		"enemies_rekt":enemies_rekt,
		"debris_rekt":debris_rekt,
		"chests_looted":chests_looted,
		"partially_looted_chests":partially_looted_chests,
		"hole_exits":hole_exits,
	}
	cave_data_file.store_var(cave_data_dict)
	cave_data_file.close()
	DirAccess.copy_absolute("user://%s/Univ%s/Caves/%s.hx3~" % [game.c_sv, game.c_u, id], "user://%s/Univ%s/Caves/%s.hx3" % [game.c_sv, game.c_u, id])
	
func exit_cave():
	Helper.save_obj("Planets", game.c_p_g, game.tile_data)
	save_cave_data()
	for i in len(inventory):
		if inventory[i].is_empty() or inventory[i].type == "consumable":
			continue
		if inventory[i].id is int:
			var remaining:int = game.add_items(inventory[i].id, inventory[i].num)
			if remaining > 0:
				inventory[i].num = remaining
			else:
				inventory[i].clear()
		elif inventory[i].id == "money":
			game.add_resources({"money":inventory[i].num}) 
			inventory[i].clear()
		elif inventory[i].id == "minerals":
			inventory[i].num = Helper.add_minerals(inventory[i].num).remainder
			if inventory[i].num <= 0:
				inventory[i].clear()
	var i_w_w2 = i_w_w.duplicate(true)
	if i_w_w.has("stone"):
		i_w_w2.stone = Helper.get_stone_comp_from_amount(p_i.crust, i_w_w.stone)
	i_w_w.clear()
	game.switch_view("planet")
	game.add_resources(i_w_w2)
	queue_free()

func cooldown(duration:float):
	var slot:int = curr_slot
	inventory_ready[slot] = false
	var timer = Timer.new()
	add_child(timer)
	timer.start(duration)
	timer.connect("timeout",Callable(self,"on_cooldown_timeout").bind(timer, slot))

func on_cooldown_timeout(timer:Timer, slot:int):
	inventory_ready[slot] = true
	timer.queue_free()
	
func remove_item(item:Dictionary, num:int = 1):
	item.num -= num
	if item.num <= 0:
		inventory[curr_slot].clear()
		active_item.text = ""
		slots[curr_slot].get_node("TextureRect").texture = null
		slots[curr_slot].get_node("Label").text = ""
	else:
		slots[curr_slot].get_node("Label").text = str(item.num)
	
func _process(delta):
	$UI2/Inventory/Label.text = "%s / %s kg" % [Helper.format_num(round($UI2/Inventory/Bar.value)), Helper.format_num(weight_cap)]
	$UI2/HP/Label.text = "%s / %s" % [Helper.format_num(ceil($UI2/HP/Bar.value)), Helper.format_num(total_HP)]
	if not ability_timer.is_stopped():
		$UI2/Ability/TextureProgressBar.value = ability_timer.time_left / ability_timer.wait_time
	for effect in status_effects.keys():
		status_effects[effect] -= delta * time_speed
		if status_effects[effect] < 0:
			status_effects.erase(effect)
			if effect == "stun":
				rover.get_node("Stun").visible = false
			elif effect == "burn":
				rover.get_node("Burn").visible = false
				$Rover/BurnTimer.stop()
				$Rover/Sprite2D.modulate = star_mod
			elif effect == "invincible":
				rover.collision_mask = 37
				$Rover/AnimationPlayer.stop()
	if inventory[curr_slot].has("id") and inventory[curr_slot].id is int and Item.data[inventory[curr_slot].id].type == Item.Type.DRILL:
		tile_highlight_left.position.x = floor(rover.position.x / 200) * 200 + 100
		tile_highlight_left.position.y = floor(rover.position.y / 200) * 200 + 100
	elif right_inventory[0].has("id") and right_inventory[0].id is int and Item.data[right_inventory[0].id].type == Item.Type.DRILL:
		tile_highlight_right.position.x = floor(rover.position.x / 200) * 200 + 100
		tile_highlight_right.position.y = floor(rover.position.y / 200) * 200 + 100
	if not status_effects.has("stun") and use_item_node.button_pressed and inventory_ready[curr_slot] and not inventory[curr_slot].is_empty():
		use_item(inventory[curr_slot], tile_highlight_left, delta)
	if not status_effects.has("stun") and Input.is_action_pressed("right_click") and right_inventory_ready[0] and not right_inventory[0].is_empty():
		use_item(right_inventory[0], tile_highlight_right, delta)
	if is_aurora_cave:
		canvas_mod.color = aurora_mod.modulate
		canvas_mod.color.a = 1
	if MM.visible:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.MM_icon.position = enemy.position * minimap_zoom + minimap_center - rover.position * minimap_zoom
		MM_hole.position = hole.position * minimap_zoom + minimap_center - rover.position * minimap_zoom
		MM_exit.position = exit.position * minimap_zoom + minimap_center - rover.position * minimap_zoom

func use_item(item:Dictionary, _tile_highlight, delta):
	var firing_RoD:bool = not ability_timer.is_stopped() and ability == "laser_2"
	if item.type == "rover_weapons":
		var base_angle:float = atan2(mouse_pos.y - rover.position.y, mouse_pos.x - rover.position.x)
		attack(base_angle)
		if not ability_timer.is_stopped() and ability == "laser_8":
			attack(base_angle - 3.0 * PI/32.0)
			attack(base_angle + 3.0 * PI/32.0)
			attack(base_angle - 4.0 * PI/32.0)
			attack(base_angle + 4.0 * PI/32.0)
			attack(base_angle - 5.0 * PI/32.0)
			attack(base_angle + 5.0 * PI/32.0)
		if enhancements.has("laser_6"):
			attack(base_angle - PI/32.0)
			attack(base_angle + PI/32.0)
		if enhancements.has("laser_7"):
			attack(base_angle - PI/16.0)
			attack(base_angle + PI/16.0)
		var cooldown:float = Data.rover_weapons[laser_name + "_laser"].cooldown / time_speed
		if status_effects.has("invincible") and enhancements.has("armor_6") and not firing_RoD:
			cooldown /= 3.0
		cooldown(cooldown)
	elif item.type == "rover_mining":
		if tile_highlighted_for_mining != -1:
			mine_wall(item, _tile_highlight, delta)
		elif mining_debris != -1:
			mine_debris(item, delta)
		update_ray()
	elif item.type == "consumable":
		if item.name.substr(0, 17) == "portable_wormhole":
			if cave_floor <= game.craft_cave_info[item.name].limit:
				remove_item(item, 1)
				exit_cave()
			else:
				game.popup(tr("WH_ERROR"), 2.0)
		elif item.name.substr(0, 5) == "drill":
			if tile.cave.has("special_cave"):
				game.popup(tr("DRILL_ERROR"), 2.0)
				return
			if cave_floor >= game.craft_cave_info[item.name].limit:
				game.popup(tr("DRILL_ERROR3"), 1.5)
				return
			if cave_floor == num_floors:
				game.popup(tr("DRILL_ERROR2"), 1.5)
				return
			var tile_id:int = get_tile_index(Vector2(int(rover.position.x / 200), int(rover.position.y / 200)))
			var holes:Dictionary = hole_exits[cave_floor - 1]
			var ok:bool = false
			if tile_id != holes.hole and tile_id != holes.exit:
				if holes.has("drilled_holes"):
					if not tile_id in holes.drilled_holes:
						holes.drilled_holes.append(tile_id)
						ok = true
				else:
					holes.drilled_holes = [tile_id]
					ok = true
			if ok:
				remove_item(item, 1)
				if not item.has("id"):
					_tile_highlight.visible = false
				add_hole(tile_id)
			cooldown(0.5)

func attack(angle:float):
	if laser_name == "":
		return
	var laser_color:Color = get_color(laser_name)
	if $WorldEnvironment.environment.glow_enabled:
		laser_color *= 4.0
	var proj_scale:float = 1.5
	if laser_name in ["yellow", "green"]:
		proj_scale *= 1.2
	elif laser_name in ["blue", "purple"]:
		proj_scale *= 1.4
	elif laser_name in ["UV", "xray"]:
		proj_scale *= 1.7
	elif laser_name == "gammaray":
		proj_scale *= 2.2
	elif laser_name == "ultragammaray":
		proj_scale *= 3.0
	add_proj(false, rover.position, 70.0, angle, laser_texture, laser_damage, {"mod":laser_color, "type":Data.ProjType.LASER, "size": proj_scale})

func add_enemy_proj(_class:int, rot:float, base_dmg:float, pos:Vector2, proj_speed_mult:float = 1.0):
	var _status_effects = {}
	var glow:float = 1.0
	if volcano_mult > 1:
		_status_effects.burn = volcano_mult / 1.5
		glow = 1.2
	if _class == 1:
		add_proj(true, pos, 12.0 * proj_speed_mult, rot, bullet_texture, base_dmg, {"mod":Color.WHITE * 1.2 * glow, "status_effects":_status_effects})
	elif _class == 2:
		_status_effects.stun = 0.7
		add_proj(true, pos, 15.0 * proj_speed_mult, rot, laser_texture, base_dmg * 0.8, {"mod":Color(1.5, 1.5, 0.75) * glow, "type":Data.ProjType.LASER, "status_effects":_status_effects})
	elif _class == 3:
		add_proj(true, pos, 13.0 * proj_speed_mult, rot, bubble_texture, base_dmg * 1.2, {"mod":Color.WHITE * 1.2 * glow, "type":Data.ProjType.BUBBLE, "status_effects":_status_effects})
	elif _class == 4:
		add_proj(true, pos, 0.0, rot, purple_texture, base_dmg * 1.1, {"size":2.0, "mod":Color.WHITE * 1.2 * glow, "type":Data.ProjType.PURPLE, "status_effects":_status_effects})

#mod:Color = Color.WHITE, type:int = Data.ProjType.STANDARD, proj_scale:float = 1.0, status_effects:Dictionary = {}
func add_proj(enemy:bool, pos:Vector2, spd:float, rot:float, texture, damage:float, other_data:Dictionary):
	var proj:Projectile = bullet_scene.instantiate()
	proj.texture = texture
	proj.rotation = rot
	proj.speed = spd
	proj.direction = Vector2.from_angle(rot)
	proj.position = pos
	var size:float = other_data.get("size", 1.0)
	if enemy:
		proj.scale *= size * enemy_projectile_size
	else:
		proj.get_node("Sprite2D").material = ShaderMaterial.new()
		proj.get_node("Sprite2D").material.shader = preload("res://Shaders/RoverAttackLaser.gdshader")
		var laser_color = other_data.get("mod", Color.WHITE)
		proj.get_node("Sprite2D").material.set_shader_parameter("laser_color", laser_color)
		if Settings.enable_shaders:
			proj.get_node("PointLight2D").enabled = true
			proj.get_node("PointLight2D").color = laser_color
			proj.get_node("PointLight2D").energy = (0.6 + cave_darkness * 1) / pow(light_strength_mult, 2)
			proj.get_node("PointLight2D2").enabled = true
			proj.get_node("PointLight2D2").energy = (0.3 + cave_darkness * 1) / pow(light_strength_mult, 2)
		proj.scale *= size
		proj.get_node("Sprite2D").light_mask = 2
	proj.damage = damage
	proj.enemy = enemy
	proj.type = other_data.get("type", Data.ProjType.STANDARD)
	proj.time_speed = time_speed
	proj.status_effects = other_data.get("status_effects", {})
	#proj.get_node("Sprite2D").modulate = other_data.get("mod", Color.WHITE)
	if enemy:
		proj.collision_layer = 16
		proj.collision_mask = 1 + 2
		proj.add_to_group("enemy_projectiles")
	else:
		proj.scale *= rover_size
		proj.collision_layer = 8
		proj.collision_mask = 1 + 4
		proj.add_to_group("player_projectiles")
	proj.cave_ref = self
	if other_data.has("energy_ball"):
		var targ_mod:Color = proj.modulate
		proj.modulate.a = 0.0
		var tween = create_tween()
		add_child(proj)
		proj.seek_speed = 15.0
		tween.tween_property(proj, "modulate", targ_mod, 0.2)
	else:
		if not enemy:
			if enhancements.has("laser_1"):
				proj.pierce = 3
			elif enhancements.has("laser_0"):
				proj.pierce = 2
		add_child(proj)

func get_color(color:String):
	match color:
		"red":
			return Color(1.0, 0.0, 0.0, 1.0)
		"orange":
			return Color(0.8, 0.4, 0.0, 1.0)
		"yellow":
			return Color(0.6, 0.6, 0.0, 1.0)
		"green":
			return Color(0.0, 1.0, 0.0, 1.0)
		"blue":
			return Color(0.0, 0.0, 1.0, 1.0)
		"purple":
			return Color.PURPLE
		"UV":
			return Color(1.0, 0.15, 1.0, 1.0)
		"xray":
			return Color.LIGHT_GRAY
		"gammaray":
			return Color.LIGHT_SEA_GREEN
		"ultragammaray":
			return Color.WHITE

func mine_wall(item:Dictionary, _tile_highlight, delta):
	var st = str(tile_highlighted_for_mining)
	if not tiles_touched_by_laser.has(st):
		tiles_touched_by_laser[st] = {}
		var tile = tiles_touched_by_laser[st]
		tile.progress = 0
		var sq_bar = sq_bar_scene.instantiate()
		add_child(sq_bar)
		sq_bar.position = cave_BG.map_to_local(get_tile_pos(tile_highlighted_for_mining)) - Vector2(100, 100)
		tile.bar = sq_bar
	if st != "-1":
		var sq_bar = tiles_touched_by_laser[st].bar
		tiles_touched_by_laser[st].progress += Data.rover_mining[item.id].speed * delta * 60 * pow(rover_size, 2) * time_speed * game.u_i.charge
		sq_bar.set_progress(tiles_touched_by_laser[st].progress)
		if tiles_touched_by_laser[st].progress >= 100:
			mine_wall_complete(_tile_highlight.position, tile_highlighted_for_mining)
			tile_highlighted_for_mining = -1

func mine_debris(item:Dictionary, delta):
	var debris = big_debris[mining_debris]
	if mining_debris != -1:
		var circ_bar = debris_touched_by_laser[mining_debris].bar
		if circ_bar == null:
			return
		var aurora_factor:float = 1.0/debris.aurora_intensity if debris.aurora_intensity > 0.0 else 1.0
		var volcano_factor:float = 1.0/debris.lava_intensity if debris.lava_intensity > 0.0 else 1.0
		var add_progress = Data.rover_mining[item.id].speed * 90 * pow(rover_size, 2) * time_speed / pow(debris.scale.x * 2.0, 3) * aurora_factor * volcano_factor * game.u_i.charge
		debris_touched_by_laser[mining_debris].progress += add_progress * debris.cracked_mining_factor * delta
		circ_bar.color = Color(1.0, 0.6, 1.0) if debris.cracked_mining_factor > 1.0 else Color.GREEN
		circ_bar.progress = debris_touched_by_laser[mining_debris].progress
		circ_bar.queue_redraw()
		var prog = debris_touched_by_laser[mining_debris].progress
		if prog >= 100:
			mine_debris_complete(mining_debris)
			mining_debris = -1
		elif debris.scale.x > 1.0:
			if prog >= debris.crack_threshold and not debris.get_node("Crack").monitoring:
				debris.set_crack()
				debris.crack_threshold = prog + add_progress * 8.0

func mine_debris_complete(tile_id:int):
	var debris = big_debris[tile_id]
	if debris.scale.x > 1.5:
		if Settings.screen_shake:
			$Camera2D/Screenshake.start(remap(debris.scale.x, 1.5, 7.5, 1.0, 7.0),10, remap(debris.scale.x, 1.5, 7.5, 5, 65))
		if not game.achievement_data.random.has("destroy_BBB") and debris.scale.x > 6.0:
			game.earn_achievement("random", "destroy_BBB")
	var debris_aurora_mult = debris.aurora_intensity if debris.aurora_intensity > 0.0 else 1.0
	var debris_volcano_mult = debris.lava_intensity if debris.lava_intensity > 0.0 else 1.0
	var rsrc:Dictionary = {"stone":randf_range(800, 900),
							"minerals":randf_range(42, 46) * difficulty * exp(cave_floor / 10.0) * debris_aurora_mult * debris_volcano_mult}
	for mat in p_i.surface.keys():
		if randf() < p_i.surface[mat].chance / 2.5:
			var amount = Helper.clever_round(p_i.surface[mat].amount * randf_range(0.2, 0.24) * difficulty * debris_aurora_mult * debris_volcano_mult)
			rsrc[mat] = amount
	var debris_exp = 3.5
	if debris_volcano_mult > 1.0:
		debris_exp += 0.2
	if debris_aurora_mult > 1.0:
		debris_exp += 0.2
		if randf() < 0.3 + debris.aurora_intensity / 10.0:
			rsrc.quillite = Helper.clever_round(randf_range(0.1, 0.12) * difficulty * debris.aurora_intensity)
	for met in game.met_info:
		var met_value = game.met_info[met]
		var rarity = met_value.rarity
		if cave_floor >= 8:
			rarity = pow(rarity, remap(cave_floor, 8, 32, 0.9, 0.6))
		if debris.aurora_intensity > 0.0:
			rarity = pow(rarity, remap(debris.aurora_intensity, 1.0, 8.0, 0.95, 0.6))
		if rarity < difficulty * 2.0 and randf() < 1 / (rarity + 1):
			rsrc[met] = Helper.clever_round(5 * randf_range(0.2, 1.0) / rarity * difficulty * exp(cave_floor / 10.0) * debris_volcano_mult)
	for r in rsrc.keys():
		if r in ["stone", "minerals"]:
			rsrc[r] = round(rsrc[r] * pow(debris.scale.x, debris_exp))
		else:
			rsrc[r] = Helper.clever_round(rsrc[r] * pow(debris.scale.x, debris_exp))
		if rsrc[r] == 0:
			rsrc.erase(r)
	var remainder:float = filter_and_add(rsrc)
	if remainder != 0:
		game.popup(tr("WEIGHT_INV_FULL_MINING"), 1.7)
	if debris_touched_by_laser.has(mining_debris):
		debris_touched_by_laser[mining_debris].bar.queue_free()
	debris_rekt[cave_floor - 1].append(mining_debris)
	debris.destroy_rock()

func filter_and_add(rsrc:Dictionary):
	var remainder:float = 0.0
	for r in rsrc.keys():
		if game.cave_filters.has(r):
			if game.cave_filters[r]:
				rsrc.erase(r)
				continue
		else:
			game.cave_filters[r] = false
			add_filter(r)
		game.show[r] = true
		if r == "minerals":
			add_to_inventory(r, rsrc[r], {})
		else:
			rsrc[r] *= game.u_i.planck
			remainder += add_weight_rsrc(r, rsrc[r])
	if not rsrc.is_empty():
		var vbox = $UI2/Panel/VBoxContainer
		var you_mined = Label.new()
		you_mined.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		you_mined.text = tr("YOU_MINED")
		reset_panel_anim()
		Helper.put_rsrc(vbox, 32, rsrc)
		vbox.add_child(you_mined)
		vbox.move_child(you_mined, 0)
		$UI2/Panel.visible = true
		$UI2/Panel.modulate.a = 1
		var timer = $UI2/Panel/Timer
		timer.wait_time = 0.5 + 0.5 * vbox.get_child_count()
		timer.start()
	return remainder

func mine_wall_complete(tile_pos:Vector2, tile_id:int):
	var st = str(tile_id)
	game.stats_univ.tiles_mined_caves += 1
	game.stats_dim.tiles_mined_caves += 1
	game.stats_global.tiles_mined_caves += 1
	var map_pos = cave_wall.local_to_map(tile_pos)
	var rsrc:Dictionary = {"stone":randi_range(150, 200)}
	if volcano_mult > 1.0:
		rsrc.minerals = round(randf_range(2, 3) * difficulty * exp(cave_floor / 9.0))
	#var wall_type = cave_wall.get_cellv(map_pos)
	for mat in p_i.surface.keys():
		if randf() < p_i.surface[mat].chance / 2.5:
			var amount = Helper.clever_round(p_i.surface[mat].amount * randf_range(0.1, 0.12) * difficulty)
			rsrc[mat] = amount
	if deposits.has(st):
		var deposit = deposits[st]
		rsrc[deposit.rsrc_name] = Helper.clever_round(deposit.amount * randf_range(0.95, 1.05) * difficulty / game.met_info[deposit.rsrc_name].rarity)
		deposit.queue_free()
		deposits.erase(st)
	var remainder:float = filter_and_add(rsrc)
	if remainder != 0:
		game.popup(tr("WEIGHT_INV_FULL_MINING"), 1.7)
	var walls = cave_wall.get_used_cells()
	walls.erase(map_pos)
	
	cave_wall.set_cell(map_pos)
	#cave_wall.set_cells_terrain_connect(0, walls, 0, 0)
	minimap_cave.set_cell(map_pos, tile_type, Vector2i.ZERO)
	astar_node.add_point(tile_id, Vector2(map_pos.x, map_pos.y))
	connect_points(map_pos, true)
	if tiles_touched_by_laser.has(st):
		tiles_touched_by_laser[st].bar.queue_free()
		tiles_touched_by_laser.erase(st)
	tiles_mined[cave_floor - 1].append(tile_id)

var inv_bar_tween

func add_weight_rsrc(r, rsrc_amount):
	weight += rsrc_amount
	if i_w_w.has(r):
		i_w_w[r] += rsrc_amount
	else:
		i_w_w[r] = rsrc_amount
	var diff:float = floor((weight - weight_cap) * 100) / 100.0
	if enhancements.has("CC_0") or enhancements.has("CC_1") or enhancements.has("CC_2"):
		diff = floor((weight - weight_cap * 8.0) * 100) / 100.0
		if weight > weight_cap * 8.0:
			weight -= diff
			i_w_w[r] -= diff
			var float_error:float = weight - weight_cap * 8.0
			weight -= float_error
			i_w_w[r] -= float_error
		if weight > weight_cap:
			if enhancements.has("CC_1"):
				speed_penalty = clamp(remap(weight / weight_cap, 1.0, 8.0, 1.0, 0.7), 0.7, 1.0)
			elif enhancements.has("CC_0"):
				speed_penalty = clamp(remap(weight / weight_cap, 1.0, 8.0, 1.0, 0.3), 0.3, 1.0)
			$UI2/Inventory/Label["theme_override_colors/font_color"] = Color.RED
		else:
			$UI2/Inventory/Label["theme_override_colors/font_color"] = Color(1.0, 0.8, 0.67)
	else:
		if weight > weight_cap:
			weight -= diff
			i_w_w[r] -= diff
			var float_error:float = weight - weight_cap
			weight -= float_error
			i_w_w[r] -= float_error
	#$UI2/Inventory/Bar.value = weight
	$Rover/InvBar.value = weight
	if is_instance_valid(inv_bar_tween):
		inv_bar_tween.kill()
	inv_bar_tween = create_tween()
	inv_bar_tween.set_parallel(true)
	$UI2/Inventory/Bar.tint_progress = Color(1.0, 0.7, 0.4)
	inv_bar_tween.tween_property($UI2/Inventory/Bar, "value", weight, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	inv_bar_tween.tween_property($UI2/Inventory/Bar, "tint_progress", Color(0.67, 0.37, 0.0), 1.0)
	$UI2/Inventory/Bar
	return max(diff, 0.0)

func _on_Timer_timeout():
	var tween = create_tween()
	tween.tween_property($UI2/Panel, "modulate", Color(1, 1, 1, 0), 0.5)
	$UI2/Panel/Timer.stop()

func hit_player(damage:float, _status_effects:Dictionary = {}, passive:bool = false):
	var firing_RoD:bool = not ability_timer.is_stopped() and ability == "laser_2"
	if not status_effects.has("invincible") and not firing_RoD:
		if not passive:
			if $Rover/InvincibilityCooldown.is_stopped():
				if enhancements.has("armor_5"):
					status_effects.invincible = 1.5
					$Rover/AnimationPlayer.play("Invincible")
					$Rover/InvincibilityCooldown.start(2.0 / time_speed)
				elif enhancements.has("armor_4"):
					status_effects.invincible = 0.5
					$Rover/AnimationPlayer.play("Invincible")
					$Rover/InvincibilityCooldown.start(2.0 / time_speed)
			if enhancements.has("armor_8"):
				for angle in 32:
					attack(angle * 11.25 * PI / 180)
			elif enhancements.has("armor_7"):
				for angle in 16:
					attack(angle * 22.5 * PI / 180)
	else:
		return
	damage *= armor_damage_mult
	update_health_bar(HP - round(damage))
	if enhancements.has("armor_11"):
		if HP <= total_HP * 0.2:
			armor_damage_mult = 0.2
		elif HP <= total_HP * 0.6:
			armor_damage_mult = 0.6
		else:
			armor_damage_mult = 1.0
	elif enhancements.has("armor_10"):
		if HP <= total_HP * 0.6:
			armor_damage_mult = 0.6
		else:
			armor_damage_mult = 1.0
	elif enhancements.has("armor_9"):
		if HP <= total_HP * 0.5:
			armor_damage_mult = 0.75
		else:
			armor_damage_mult = 1.0
	if HP <= 0:
		for inv in inventory:
			if inv.has("num"):
				inv.num /= 2
		for w in i_w_w:
			i_w_w[w] /= 2
		var st:String = tr("ROVER_DEATH_MESSAGE_NORMAL")
		var st2:String = ""
		if not $Rover/SuffocationTimer.is_stopped():
			st = tr("ROVER_DEATH_MESSAGE_SUFFOCATE")
		elif not $Rover/LavaTimer.is_stopped():
			st = tr("ROVER_DEATH_MESSAGE_LAVA")
		elif not $Rover/BurnTimer.is_stopped():
			st = tr("ROVER_DEATH_MESSAGE_BURN")
		elif travel_distance < 2000.0 and cave_floor == 1:
			st = tr("ROVER_DEATH_MESSAGE_ENTRANCE")
			st2 = tr("ROVER_DEATH_MESSAGE_ENTRANCE2")
		elif HP == total_HP and damage >= total_HP:
			st = tr("ROVER_DEATH_MESSAGE_OHKO")
		elif len(get_tree().get_nodes_in_group("enemy_projectiles")) > 70:
			st = tr("ROVER_DEATH_MESSAGE_BULLET_HELL")
		elif status_effects.has("stun"):
			st = tr("ROVER_DEATH_MESSAGE_STUN")
		elif weight > 2.0 * weight_cap:
			st = tr("ROVER_DEATH_MESSAGE_OVERLOAD")
		elif cave_darkness > 0.9:
			st = tr("ROVER_DEATH_MESSAGE_DARK")
		if Settings.op_cursor:
			st = st.replace("wrecked", "rekt")
		call_deferred("exit_cave")
		game.popup_window(st + " " + tr("LOST_RESOURCES") + " " + st2, tr("ROVER_REKT_TITLE"))
	else:
		set_avg_dmg()
		if is_instance_valid(HP_tween):
			HP_tween.kill()
		HP_tween = create_tween()
		HP_tween.tween_property($UI2/HP/Bar, "value", HP, 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	for effect in _status_effects:
		if not status_effects.has(effect):
			status_effects[effect] = _status_effects[effect]
			if effect == "stun":
				rover.get_node("Stun").visible = true
			elif effect == "burn":
				rover.get_node("Burn").visible = true
				$Rover/BurnTimer.start(1.0 / time_speed)
				$Rover/Sprite2D.modulate = Color.ORANGE_RED
	var tween = create_tween()
	
	var strength:float = min($UI2/HurtTexture.modulate.a + remap(damage / total_HP, 0.0, 0.5, 0.05, 0.5), 0.5)
	$UI2/HurtTexture.modulate.a = strength
	tween.tween_property($UI2/HurtTexture, "modulate", Color(1, 1, 1, 0), 1.0)
	if HP > 0:
		Helper.show_dmg(round(damage), rover.position, self, 80)

var slots = []
func set_border(i:int):
	for j in range(0, len(slots)):
		var slot = slots[j]
		if i == j and not slot.get_node("Border").visible:
			slot.get_node("Border").visible = true
		elif slot.get_node("Border").visible:
			slot.get_node("Border").visible = false
	if inventory[i].is_empty():
		active_item.text = ""
		return
	if inventory[i].type == "rover_mining":
		active_item.text = Helper.get_rover_mining_name(inventory[i].id)
	elif inventory[i].type == "rover_weapons":
		active_item.text = Helper.get_rover_weapon_name(inventory[i].id)
	elif inventory[i].has("id") and inventory[i].id is int:
		active_item.text = Item.name(inventory[i].id)
	else:
		active_item.text = ""
	if inventory[i].has("id") and inventory[i].id is int and Item.data[inventory[i].id].type == Item.Type.DRILL:
		tile_highlight_left.visible = true
	elif inventory[i].type != "rover_mining":
		tile_highlight_left.visible = false

func sort_size(a, b):
	if a.size > b.size:
		return true
	return false

func get_connected_tiles(_id:int):#Returns the list of all tiles connected to tile with index id, useful to get size of enclosed rooms for example
	var unique_c_tiles = [_id]
	var c_tiles = [_id]
	while len(c_tiles) != 0:
		var new_c_tiles = []
		for c_tile in c_tiles:
			for i in astar_node.get_point_connections(c_tile):
				if unique_c_tiles.find(i) == -1:
					new_c_tiles.append(i)
					unique_c_tiles.append(i)
		c_tiles = new_c_tiles
	return unique_c_tiles
		
func get_tile_index(pt:Vector2):
	return pt.x + cave_size * pt.y

#returns unit positions
func get_tile_pos(_id:int):
	return Vector2(_id % cave_size, _id / cave_size)

func _physics_process(delta):
	var speed_mult2 = min(2.5, (speed_mult if moving_fast else 1.0) * rover_size) * time_speed * speed_penalty
	mouse_pos = global_mouse_pos + camera.position - Vector2(640, 360)
	update_ray()
	input_vector = Vector2.ZERO
	var acc_penalty = remap(speed_penalty, 0.3, 1.0, 0.1, 1.0)
	if not status_effects.has("stun"):
		input_vector.x = int(Input.is_action_pressed("D")) - int(Input.is_action_pressed("A"))
		input_vector.y = int(Input.is_action_pressed("S")) - int(Input.is_action_pressed("W"))
		input_vector = input_vector.normalized()
	var rover_sprite:Sprite2D = $Rover/Sprite2D
	if input_vector != Vector2.ZERO:
		if input_vector.x > 0:
			if input_vector.y > 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees - 45, 360) + 45, delta * 60.0 * 15.0)
			elif input_vector.y < 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees + 45, 360) - 45, delta * 60.0 * 15.0)
			else:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees, 360), delta * 60.0 * 15.0)
		elif input_vector.x < 0:
			if input_vector.y > 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees - 135, 360) + 135, delta * 60.0 * 15.0)
			elif input_vector.y < 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees + 135, 360) - 135, delta * 60.0 * 15.0)
			else:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees - 180, 360) + 180, delta * 60.0 * 15.0)
		else:
			if input_vector.y > 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees - 90, 360) + 90, delta * 60.0 * 15.0)
			elif input_vector.y < 0:
				rover_sprite.rotation_degrees = move_toward(rover_sprite.rotation_degrees, snapped(rover_sprite.rotation_degrees + 90, 360) - 90, delta * 60.0 * 15.0)
		$Rover/CollisionShape2D.rotation_degrees = rover_sprite.rotation_degrees
		$Rover/AshParticles.emitting = on_ash
		velocity = velocity.move_toward(input_vector * max_speed * speed_mult2, acceleration * speed_mult2 * acc_penalty)
	else:
		$Rover/AshParticles.emitting = false
		velocity = velocity.move_toward(Vector2.ZERO, friction * speed_mult2 * acc_penalty)
	rover.set_velocity(velocity)
	rover.move_and_slide()
	travel_distance += velocity.length() * delta
	if rover.collision_mask == 32:
		if rover.position.x < 64 * rover_size:
			rover.position.x = 64 * rover_size
		elif rover.position.x > cave_size * 200 - 64 * rover_size:
			rover.position.x = cave_size * 200 - 64 * rover_size
		if rover.position.y < 64 * rover_size:
			rover.position.y = 64 * rover_size
		elif rover.position.y > cave_size * 200 - 64 * rover_size:
			rover.position.y = cave_size * 200 - 64 * rover_size
	for i in rover.get_slide_collision_count():
		var collision = rover.get_slide_collision(i)
		if not collision:
			continue
		elif collision.get_collider() is Projectile:
			collision.get_collider().collide(collision)
	camera.position = rover.position + shaking
	minimap_cave.position = minimap_center - rover.position * minimap_zoom

func reset_panel_anim():
	var timer = $UI2/Panel/Timer
	timer.stop()
	$UI2/Panel.visible = false
	$UI2/Panel.modulate.a = 1

func _on_Exit_area_entered(_body):
	active_chest = "-1"
	if cave_floor == 1:
		show_right_info(tr("F_TO_EXIT"))
		active_type = "exit"
	else:
		show_right_info(tr("F_TO_GO_UP"))
		active_type = "go_up"

func on_WH_entered(_body):
	show_right_info(tr("F_TO_EXIT"))
	active_type = "exit"

func _on_Hole_area_entered(_body):
	active_chest = "-1"
	show_right_info(tr("F_TO_GO_DOWN"))
	active_type = "go_down"

func show_right_info(txt:String):
	var vbox = $UI2/Panel/VBoxContainer
	reset_panel_anim()
	Helper.put_rsrc(vbox, 32, {})
	var info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.text = txt
	vbox.add_child(info)
	$UI2/Panel.visible = true

func _on_area_exited(_body):
	call_deferred("hide_panel")

func _on_Floor_mouse_entered():
	game.show_tooltip(tr("CAVE_FLOOR") % [cave_floor])

func _on_mouse_exited():
	game.hide_tooltip()

func _on_Difficulty_mouse_entered():
	var floor_mult = pow(2, cave_floor - 1)
	if volcano_mult > 1 and not artificial_volcano and is_aurora_cave:
		floor_mult = pow(2.5, cave_floor - 1)
	elif volcano_mult > 1 and not artificial_volcano or is_aurora_cave:
		floor_mult = pow(2.25, cave_floor - 1)
	var tooltip:String = "%s: %s\n%s: %s" % [
		tr("STAR_SYSTEM_DIFFICULTY"),
		Helper.format_num(game.system_data[game.c_s].diff),
		tr("FLOOR_MULTIPLIER"),
		Helper.format_num(floor_mult, true),
	]
	if aurora_mult > 1:
		tooltip += "\n%s: %s" % [tr("AURORA_MULTIPLIER"), Helper.format_num(aurora_mult)]
	if volcano_mult > 1 and not artificial_volcano:
		tooltip += "\n%s: %s" % [tr("PROXIMITY_TO_VOLCANO_MULT"), Helper.clever_round(pow(volcano_mult, 2.5))]
	game.show_tooltip(tooltip, {"additional_text": tr("CAVE_DIFF_INFO"), "additional_text_delay": 1.5})

func _on_Filter_pressed():
	if $UI2/Filters.visible:
		var rect_x:int = $UI2/Filters.position.x
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property($UI2/Filters, "modulate", Color(1, 1, 1, 0), 0.1)
		tween.tween_property($UI2/Filters, "position", Vector2(rect_x, 662 - $UI2/Filters/Grid.size.y), 0.1)
		tween.tween_callback($UI2/Filters.set_visible.bind(false)).set_delay(0.1)
		tween.tween_callback(game.hide_tooltip).set_delay(0.1)
	else:
		var tween = create_tween()
		var rect_x:int = $UI2/BottomLeft/Filter.position.x
		$UI2/Filters.position.x = rect_x
		$UI2/Filters.position.y = 662 - $UI2/Filters/Grid.size.y
		tween.tween_property($UI2/Filters, "modulate", Color.WHITE, 0.1)
		tween.tween_property($UI2/Filters, "position", Vector2(rect_x, 658 - $UI2/Filters/Grid.size.y), 0.1)
		$UI2/Filters.visible = true

func _on_CheckAchievements_timeout():
	if cave_wall.get_used_cells().is_empty() and chests.is_empty() and big_debris.is_empty() and get_tree().get_nodes_in_group("enemies").is_empty():
		game.earn_achievement("random", "clear_out_cave_floor")
		$CheckAchievements.stop()
		$CheckAchievements.disconnect("timeout",Callable(self,"_on_CheckAchievements_timeout"))


func _on_BurnTimer_timeout():
	hit_player(total_HP / 50.0, {}, true)


func _on_Modifiers_mouse_entered():
	var icons:Array = []
	var tooltip:String = Helper.get_modifier_string(modifiers, "", icons)
	tooltip = tooltip.substr(1)
	tooltip += "\n%s: %s" % [tr("TOTAL_TREASURE_MULT"), Helper.clever_round(treasure_mult)]
	game.show_tooltip(tooltip, {"imgs": icons})

func _on_FloorCollisionDetector_body_entered(body):
	if body.name == "Ash":
		if not enhancements.has("wheels_8"):
			max_speed = 500
		on_ash = true
		if $UI2/Burning.visible:
			$UI2/Burning/BurningAnim.play("Fade", -1, -time_speed, not $UI2/Burning/BurningAnim.is_playing() and $UI2/Burning.material["shader_parameter/alpha"] == 1.0)
			if not $Rover/LavaTimer.is_stopped():
				if enhancements.has("wheels_6"):
					status_effects.burn = 5.0
					$Rover/BurnTimer.start(2.0 / time_speed)
				else:
					status_effects.burn = 8.0
					$Rover/BurnTimer.start(1.0 / time_speed)
				$Rover/Sprite2D.modulate = Color.ORANGE_RED
				$Rover/LavaTimer.stop()
	elif body.name == "Lava" and not enhancements.has("wheels_7"):
		on_lava = true
		if not on_ash:
			if not enhancements.has("wheels_8"):
				max_speed = 700
			$UI2/Burning.visible = true
			$UI2/Burning/BurningAnim.play("Fade", -1, time_speed)

func _on_FloorCollisionDetector_body_exited(body):
	if body.name == "Ash":
		if not on_lava:
			max_speed = 1000
		else:
			if not enhancements.has("wheels_8"):
				max_speed = 700
		on_ash = false
		if on_lava:
			$UI2/Burning.visible = true
			$UI2/Burning/BurningAnim.play("Fade", -1, time_speed)
	elif body.name == "Lava":
		on_lava = false
		if not on_ash:
			max_speed = 1000
		else:
			if not enhancements.has("wheels_8"):
				max_speed = 500
		if $UI2/Burning.visible:
			$UI2/Burning/BurningAnim.play("Fade", -1, -time_speed, not $UI2/Burning/BurningAnim.is_playing() and $UI2/Burning.material["shader_parameter/alpha"] == 1.0)
			if not $Rover/LavaTimer.is_stopped():
				if enhancements.has("wheels_6"):
					status_effects.burn = 5.0
					$Rover/BurnTimer.start(2.0 / time_speed)
				else:
					status_effects.burn = 8.0
					$Rover/BurnTimer.start(1.0 / time_speed)
				$Rover/Sprite2D.modulate = Color.ORANGE_RED
				$Rover/LavaTimer.stop()


func _on_Ability_mouse_entered():
	game.show_tooltip(tr("USE_ABILITY") % [OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_Q)), ability_num])


func _on_AbilityTimer_timeout():
	if ability == "laser_2":
		RoDray.enabled = false
		RoD.monitoring = false
		RoD_effects.get_node("Sprite2D").visible = false
		RoD_effects.get_node("Particles").emitting = false
		$Rover/RayOfDoom/AnimationPlayer.play("RayDisappear", -1, time_speed)
	$UI2/Ability/TextureProgressBar.visible = false
	$UI2/Ability/TextureRect.modulate = Color.WHITE


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "RayDisappear":
		RoD.visible = false


func _on_RayOfDoom_body_entered(body):
	if body is Projectile:
		body.queue_free()
	else:
		body.status_effects.RoD = INF
		body.RoD_damage()
		if body.HP > 0:
			body.get_node("RoDTimer").start(0.2 / time_speed)
			body.get_node("RoDTimer").connect("timeout",Callable(body,"on_RoD_timeout"))


func _on_RayOfDoom_body_exited(body):
	if "HP" in body and body.HP > 0:
		body.get_node("RoDTimer").disconnect("timeout",Callable(body,"on_RoD_timeout"))
		body.status_effects.erase("RoD")


func _on_DashTimer_timeout():
	if enhancements.has("wheels_2"):
		dashes_remaining = 3
	elif enhancements.has("wheels_1"):
		dashes_remaining = 2
	elif enhancements.has("wheels_0"):
		dashes_remaining = 1
	rover.collision_mask = 37


func _on_EnergyBallTimer_timeout():
	if enhancements.has("laser_5"):
		add_proj(
			false, rover.position, 30.0, rover.get_node("Sprite2D").rotation,
			preload("res://Graphics/Cave/Projectiles/energy_ball2.png"),
			laser_damage * 8.0, {"mod":Color(2.0, 2.0, 2.0, 1.0), "size":0.5, "status_effects":{"stun":1.0}, "energy_ball":true})
	else:
		add_proj(
			false, rover.position, 20.0, rover.get_node("Sprite2D").rotation,
			preload("res://Graphics/Cave/Projectiles/energy_ball.png"),
			laser_damage * 3.0, {"mod":Color(2.0, 2.0, 2.0, 1.0), "size":0.4, "status_effects":{"stun":0.8}, "energy_ball":true})


func _on_BreakRocksWithDash_body_entered(body):
	if body is TileMapLayer:
		if enhancements.has("wheels_5"):
			var pos:Vector2 = Vector2(snapped(rover.position.x - 100, 200), snapped(rover.position.y - 100, 200))
			mine_wall_complete(pos, get_tile_index(pos / 200))
		else:
			$Rover/SuffocationTimer.start()
	elif body.get_parent() is Debris:
		if enhancements.has("wheels_5"):
			if body.get_parent().scale.x < 2.0:
				mine_debris_complete(body.get_parent().id)
		else:
			$Rover/SuffocationTimer.start()

func _on_BreakRocksWithDash_body_exited(body):
	if body is TileMapLayer or body.get_parent() is Debris:
		if not enhancements.has("wheels_5"):
			$Rover/SuffocationTimer.stop()


func _on_SuffocationTimer_timeout():
	hit_player(total_HP / 20.0, {}, true)


func _on_LavaTimer_timeout():
	if enhancements.has("wheels_6"):
		hit_player(total_HP / 20.0, {}, true)
	else:
		hit_player(total_HP / 10.0, {}, true)


func _on_BurningAnim_animation_finished(anim_name):
	if $UI2/Burning.material["shader_parameter/alpha"] == 1.0:
		rover.get_node("Burn").visible = true
		hit_player(total_HP / 10.0, {}, true)
		$Rover/BurnTimer.stop()
		if not enhancements.has("wheels_7"):
			if enhancements.has("wheels_6"):
				$Rover/LavaTimer.start(1.0)
			else:
				$Rover/LavaTimer.start(0.5)
	else:
		$UI2/Burning.visible = false


func _on_ctrls_mouse_entered():
	$UI2/Controls.visible = true


func _on_ctrls_mouse_exited():
	$UI2/Controls.visible = false
