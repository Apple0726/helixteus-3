extends Node2D

func _ready():
	place(91, 1, $MeltPoint)
	place(112, 1, $BoilPoint)
	place(91, 0.117, $TriplePoint)
	place(191, 46, $SuperPoint)

var colors = {	"S":Color(0.63, 0.39, 0.13, 0.7),
				"L":Color(0.63, 0.39, 0.13, 1.0),
				"SC":Color(0.63, 0.39, 0.13, 0.4)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
