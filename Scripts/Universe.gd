extends Node2D

@onready var game = self.get_parent().get_parent()
@onready var view = self.get_parent()

var dimensions:float = 1000.0

var clusters_info = []
var btns = []

func _ready():
	btns.resize(len(game.u_i.cluster_data))
	var cluster_tween
	if Settings.enable_shaders:
		cluster_tween = create_tween()
		cluster_tween.set_parallel(true)
	for i in len(game.u_i.cluster_data):
		var c_i:Dictionary = game.u_i.cluster_data[i]
		if not c_i.visible:
			continue
		var cluster_btn = TextureButton.new()
		cluster_btn.texture_normal = preload("res://Graphics/Clusters/0.png")
		var r:float = (c_i.pos + c_i.pos).length()
		var th:float = atan2(c_i.pos.y, c_i.pos.x)
		var hue:float = fmod(r + 300, 1000.0) / 1000.0
		var sat:float = pow(fmod(th + PI, 10.0) / 10.0, 0.2)
		if Settings.enable_shaders:
			cluster_btn.material = ShaderMaterial.new()
			cluster_btn.material.shader = preload("res://Shaders/Cluster.gdshader")
			cluster_btn.material.set_shader_parameter("seed", int(c_i.diff))
			cluster_btn.material.set_shader_parameter("alpha", 0.0)
			cluster_btn.material.set_shader_parameter("color", Color.from_hsv(hue, sat, 1.0))
			cluster_tween.tween_property(cluster_btn.material, "shader_parameter/alpha", 1.0, 0.15)
		else:
			cluster_btn.modulate = Color.from_hsv(hue, sat, 1.0)
		add_child(cluster_btn)
		cluster_btn.connect("mouse_entered",Callable(self,"on_cluster_over").bind(c_i.id))
		cluster_btn.connect("mouse_exited",Callable(self,"on_cluster_out"))
		cluster_btn.connect("pressed",Callable(self,"on_cluster_click").bind(c_i.id))
		cluster_btn.position = c_i.pos + Vector2(-512 / 2, -512 / 2)
		cluster_btn.pivot_offset = Vector2(512 / 2, 512 / 2)
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.3)
		if game.universe_data[game.c_u].view.zoom > 1.0:
			radius *= 0.1
		cluster_btn.scale.x = radius
		cluster_btn.scale.y = radius
		dimensions = max(dimensions, c_i.pos.length())
		btns[i] = cluster_btn

func on_cluster_over (id:int):
	var c_i = game.u_i.cluster_data[id]
	var _name:String
	if c_i.has("name"):
		_name = c_i.name
	else:
		if c_i["class"] == game.ClusterType.GROUP:
			_name = tr("GALAXY_GROUP") + " %s" % id
		else:
			_name = tr("GALAXY_CLUSTER") + " %s" % id
	var tooltip:String = "%s\n%s: %s\n%s: %s\n%s: %s" % [_name, tr("GALAXIES"), c_i.galaxy_num, tr("DIFFICULTY"), c_i.diff, tr("FERROMAGNETIC_MATERIALS"), c_i.FM]
	var icons:Array = []
	for el in c_i.rich_elements.keys():
		tooltip += "\n" + tr("RICH_IN_X").format({"rsrc":tr(el.to_upper() + "_NAME"), "mult":Helper.clever_round(c_i.rich_elements[el])})
		icons.append(load("res://Graphics/Atoms/%s.png" % el))
	#print("Distance from local group: ", c_i.pos.length())
	game.show_adv_tooltip(tooltip, icons)

func on_cluster_out ():
	game.hide_tooltip()

func on_cluster_click (id:int):
	if not view.dragged:
		game.switch_view("cluster", {"fn":"set_custom_coords", "fn_args":[["c_c"], [id]]})

func change_scale(sc:float):
	for i in range(0, btns.size()):
		var c_i:Dictionary = game.u_i.cluster_data[i]
		if not c_i.visible or not btns[i]:
			continue
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.3) * sc
		btns[i].scale.x = radius
		btns[i].scale.y = radius


func _on_Cluster_tree_exited():
	queue_free()
