extends Node2D

func _ready():
	place(1, 1, $MeltPoint)
	place(4.222, 1, $BoilPoint)
	place(2.177, 0.05, $TriplePoint)
	place(5.1953, 2.27, $SuperPoint)

var colors = {	"S":Color(0.87, 0.66, 1.0, 0.6),
				"L":Color(0.78, 0.43, 1.0, 0.9),
				"SC":Color(0.87, 0.66, 1.0, 0.3)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
