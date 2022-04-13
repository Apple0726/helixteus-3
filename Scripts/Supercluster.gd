extends Node2D

onready var game = self.get_parent().get_parent()
onready var view = self.get_parent()

var dimensions:float = 100
var btns = []

func _ready():
	btns.resize(len(game.cluster_data))
	for i in len(game.cluster_data):
		var c_i:Dictionary = game.cluster_data[i]
		if not c_i.visible:
			continue
		var cluster_btn = TextureButton.new()
		var cluster = Sprite.new()
		cluster_btn.texture_normal = preload("res://Graphics/Clusters/0.png")
		cluster_btn.texture_click_mask = preload("res://Graphics/Misc/StarCM.png")
		if game.enable_shaders:
			cluster_btn.material = ShaderMaterial.new()
			cluster_btn.material.shader = preload("res://Shaders/Cluster.shader")
			cluster_btn.material.set_shader_param("seed", int(c_i.diff))
			var dist:Vector2 = cartesian2polar(c_i.pos.x, c_i.pos.y)
			var hue:float = fmod(dist.x + 300, 1000.0) / 1000.0
			var sat:float = pow(fmod(dist.y + PI, 10.0) / 10.0, 0.2)
			cluster_btn.material.set_shader_param("color", Color.from_hsv(hue, sat, 1.0))
		self.add_child(cluster)
		cluster.add_child(cluster_btn)
		cluster_btn.connect("mouse_entered", self, "on_cluster_over", [c_i.l_id])
		cluster_btn.connect("mouse_exited", self, "on_cluster_out")
		cluster_btn.connect("pressed", self, "on_cluster_click", [c_i.id, c_i.l_id])
		cluster_btn.rect_position = Vector2(-640 / 2, -640 / 2)
		cluster_btn.rect_pivot_offset = Vector2(640 / 2, 640 / 2)
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.3)
		if game.supercluster_data[game.c_sc].view.zoom > 1.5:
			radius *= 0.1
		cluster_btn.rect_scale.x = radius
		cluster_btn.rect_scale.y = radius
		cluster.position = c_i["pos"]
		dimensions = max(dimensions, c_i.pos.length())
		btns[i] = cluster_btn

func on_cluster_over (id:int):
	var c_i = game.cluster_data[id]
	var _name:String
	if c_i.has("name"):
		_name = c_i.name
	else:
		if c_i.class == game.ClusterType.GROUP:
			_name = tr("GALAXY_GROUP") + " %s" % id
		else:
			_name = tr("GALAXY_CLUSTER") + " %s" % id
	game.show_tooltip("%s\n%s: %s\n%s: %s\n%s: %s" % [_name, tr("GALAXIES"), c_i.galaxy_num, tr("DIFFICULTY"), c_i.diff, tr("FERROMAGNETIC_MATERIALS"), c_i.FM])

func on_cluster_out ():
	game.hide_tooltip()

func on_cluster_click (id:int, l_id:int):
	if not view.dragged:
		game.switch_view("cluster", {"fn":"set_custom_coords", "fn_args":[["c_c", "c_c_g"], [l_id, id]]})

func change_scale(sc:float):
	for i in range(0, btns.size()):
		var c_i:Dictionary = game.cluster_data[i]
		if not c_i.visible:
			continue
		var radius = pow(c_i["galaxy_num"] / game.CLUSTER_SCALE_DIV, 0.3) * sc
		btns[i].rect_scale.x = radius
		btns[i].rect_scale.y = radius


func _on_Cluster_tree_exited():
	queue_free()
