extends Node2D

@onready var game = get_node("/root/Game")
@onready var BG_material = $GlowLayer/Background.material
@onready var accelerated_time_label = $Control/AccTime

var bullet_lv:int
var laser_lv:int
var bomb_lv:int
var light_lv:int
var secs_elapsed:float = 0
var penalty_time:float = 0
var minigame_time_speed:float
var universe_time_speed:float
var laser_range

func _ready():
	if game.STM_lv == 0:
		game.STM_lv = 1
	$GlowLayer/Background.material.set_shader_parameter("volsteps", Settings.dynamic_space_LOD)
	$GlowLayer/Background.material.set_shader_parameter("iterations", 14 + Settings.dynamic_space_LOD / 2)
	Helper.set_back_btn($Control/Back)
	$Control/BombActivateLabel.modulate.a = 0.0
	$Control/LightActivateLabel.modulate.a = 0.0
	BG_material.set_shader_parameter("position", Vector2.ZERO)
	bullet_lv = game.ship_data[0].bullet[0]
	laser_lv = game.ship_data[0].laser[0]
	bomb_lv = game.ship_data[0].bomb[0]
	light_lv = game.ship_data[0].light[0]
	universe_time_speed = game.u_i.time_speed
	laser_range = 200.0 * (1.0 + laser_lv / 5.0)
	$Ship/LaserArea/CollisionShape2D.shape.radius = laser_range
	minigame_time_speed = Helper.set_logarithmic_time_speed(game.subject_levels.dimensional_power, universe_time_speed)
	$EnemySpawnTimer.wait_time = 1.4 / minigame_time_speed
	$Ship/BulletTimer.wait_time = (0.17 - bullet_lv / 50.0) / minigame_time_speed
	$Ship/LaserTimer.wait_time = (1.1 - laser_lv / 10.0) / minigame_time_speed
	$Ship/BombTimer.wait_time = (3.0 - bomb_lv / 8.0) / minigame_time_speed
	$Ship/LightTimer.wait_time = (8.0 - light_lv / 2.0) / minigame_time_speed
	$Ship/BulletTimer.start()
	$Ship/LaserTimer.start()
	$Ship/BombTimer.start()
	$Ship/LightTimer.start()
	$Ship/StunTimer.wait_time = 1.0 / minigame_time_speed
	$Ship/Bomb.texture = load("res://Graphics/Weapons/bomb%s.png" % bomb_lv)
	$GlowLayer/Laser.material["shader_parameter/beams"] = laser_lv + 1
	$GlowLayer/Laser.material["shader_parameter/outline_thickness"] = (laser_lv + 1) * 0.01
	if laser_lv == 2:
		$GlowLayer/Laser.material["shader_parameter/outline_color"] = Color.ORANGE
	elif laser_lv == 3:
		$GlowLayer/Laser.material["shader_parameter/outline_color"] = Color.YELLOW
	elif laser_lv == 4:
		$GlowLayer/Laser.material["shader_parameter/outline_color"] = Color.GREEN
	elif laser_lv == 5:
		$GlowLayer/Laser.material["shader_parameter/outline_color"] = Color.BLUE

var mouse_pos:Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		$GlowLayer/Laser.position = mouse_pos - Vector2(0, 332)

func _process(delta):
	if $Ship.get_node("StunTimer").is_stopped():
		$Ship.position = mouse_pos
		$LaserTimerBar/TextureProgressBar.value = 1.0 - $Ship/LaserTimer.time_left / $Ship/LaserTimer.wait_time
		$BombTimerBar/TextureProgressBar.value = 1.0 - $Ship/BombTimer.time_left / $Ship/BombTimer.wait_time
		$LightTimerBar/TextureProgressBar.value = 1.0 - $Ship/LightTimer.time_left / $Ship/LightTimer.wait_time
		secs_elapsed += delta * universe_time_speed * (1 + (game.MUs.STMB - 1) * 0.15)
	BG_material.set_shader_parameter("position", Vector2(BG_material.get_shader_parameter("position").x + 0.1 * delta * minigame_time_speed, 0.0))
	accelerated_time_label.text = tr("TRAVEL_ACCELERATED_BY") % [Helper.time_to_str(max(0.0, secs_elapsed - penalty_time))]

func _on_enemy_spawn_timer_timeout():
	var HX:STMHX = preload("res://Scenes/STM/STMHX.tscn").instantiate()
	HX.scale = Vector2.ONE * randf_range(0.35, 0.45)
	HX.get_node("Sprite2D").material.set_shader_parameter("frequency", remap(HX.scale.x, 0.35, 0.45, 6.2, 5.8))
	HX.STM_node = self
	HX.color = randi() % 4 + 1
	HX.type = randi() % 4
	add_child(HX)


func _on_laser_animation_player_animation_finished(anim_name):
	$GlowLayer/Laser.visible = false


func _on_back_pressed():
	game.ships_travel_data.travel_start_date -= max(0, secs_elapsed - penalty_time)
	game.switch_view(game.l_v)
