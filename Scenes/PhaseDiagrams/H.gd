extends Node2D

func _ready():
	place(14, 1, $MeltPoint)
	place(21, 1, $BoilPoint)
	place(14, 0.07, $TriplePoint)
	place(33, 12.9, $SuperPoint)

var colors = {	"S":Color(0.85, 1, 0.85, 0.6),
				"L":Color(0.7, 1, 0.7, 1.0),
				"SC":Color(0.85, 1, 0.85, 0.3)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
