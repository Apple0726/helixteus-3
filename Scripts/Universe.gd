extends Node2D

@onready var game = self.get_parent().get_parent()
@onready var view = self.get_parent()

const CLUSTER_AUTOSCALE_MIN_THRESHOLD = 0.2
const CLUSTER_AUTOSCALE_MAX_THRESHOLD = 0.8
var dimensions:float = 500.0

var clusters_info = []
var btns = []
var visible_clusters = []

func _ready():
	for i in len(game.u_i.cluster_data):
		var c_i:Dictionary = game.u_i.cluster_data[i]
		if c_i.visible:
			visible_clusters.append(c_i)
	btns.resize(len(visible_clusters))
	for i in len(visible_clusters):
		var c_i:Dictionary = visible_clusters[i]
		var cluster_btn = TextureButton.new()
		cluster_btn.texture_normal = preload("res://Graphics/Clusters/0.png")
		var r:float = c_i.pos.length()
		var th:float = atan2(c_i.pos.y, c_i.pos.x)
		var hue:float = fmod(r + 300, 1000.0) / 1000.0
		var sat:float = 0.8
		if Settings.enable_shaders:
			cluster_btn.material = ShaderMaterial.new()
			cluster_btn.material.shader = preload("res://Shaders/Cluster.gdshader")
			cluster_btn.material.set_shader_parameter("fog_size", 30.0 + (c_i.redshift + 1.0) * 0.1)
			cluster_btn.material.set_shader_parameter("seed", int(c_i.redshift * 1000.0))
			cluster_btn.material.set_shader_parameter("color", Color.from_hsv(hue, sat, 1.0))
		else:
			cluster_btn.modulate = Color.from_hsv(hue, sat, 1.0).lightened(0.8)
		cluster_btn.mouse_entered.connect(game.show_tooltip.bind(Helper.get_cluster_tooltip(c_i.id)))
		cluster_btn.mouse_exited.connect(game.hide_tooltip)
		cluster_btn.pressed.connect(on_cluster_click.bind(c_i.id))
		cluster_btn.position = c_i.pos - cluster_btn.texture_normal.get_size() / 2.0
		cluster_btn.pivot_offset_ratio = Vector2.ONE * 0.5
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.3)
		cluster_btn.scale = Vector2.ONE * radius
		cluster_btn.scale /= clamp(get_parent().scale.x, CLUSTER_AUTOSCALE_MIN_THRESHOLD, CLUSTER_AUTOSCALE_MAX_THRESHOLD) / CLUSTER_AUTOSCALE_MIN_THRESHOLD
		dimensions = max(dimensions, c_i.pos.length() * 2.0)
		btns[i] = {"btn": cluster_btn, "original_scale": radius}
		add_child(cluster_btn)

func on_cluster_click (id:int):
	if not view.dragged:
		game.switch_view("cluster", {"fn":"set_custom_coords", "fn_args":[["c_c"], [id]]})

func scale_objects(new_scale:float):
	if new_scale > CLUSTER_AUTOSCALE_MIN_THRESHOLD and new_scale < CLUSTER_AUTOSCALE_MAX_THRESHOLD:
		for i in len(btns):
			btns[i].btn.scale = Vector2.ONE / new_scale * CLUSTER_AUTOSCALE_MIN_THRESHOLD * btns[i].original_scale
