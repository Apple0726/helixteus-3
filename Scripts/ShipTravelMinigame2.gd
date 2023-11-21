extends Node2D

func _ready():
	Helper.set_back_btn($Control/Back)
	$Control/BombActivateLabel.modulate.a = 0.0
	$Control/LightActivateLabel.modulate.a = 0.0

var mouse_pos:Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		$GlowLayer/Laser.position = mouse_pos - Vector2(0, 332)

@onready var BG_material = $GlowLayer/Background.material
func _process(delta):
	$Ship.position = mouse_pos
	$LaserTimerBar/TextureProgressBar.value = 1.0 - $Ship/LaserTimer.time_left / $Ship/LaserTimer.wait_time
	$BombTimerBar/TextureProgressBar.value = 1.0 - $Ship/BombTimer.time_left / $Ship/BombTimer.wait_time
	$LightTimerBar/TextureProgressBar.value = 1.0 - $Ship/LightTimer.time_left / $Ship/LightTimer.wait_time
	BG_material.set_shader_parameter("mouse", Vector2(BG_material.get_shader_parameter("mouse").x + 0.1 * delta, 0.0))

func _on_enemy_spawn_timer_timeout():
	var HX:STMHX = preload("res://Scenes/STM/STMHX.tscn").instantiate()
	HX.scale = Vector2.ONE * randf_range(0.35, 0.45)
	HX.get_node("Sprite2D").material.set_shader_parameter("frequency", remap(HX.scale.x, 0.35, 0.45, 6.2, 5.8))
	HX.STM_node = self
	add_child(HX)


func _on_laser_animation_player_animation_finished(anim_name):
	$GlowLayer/Laser.visible = false
