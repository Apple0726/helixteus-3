extends Node2D

func _ready():
	place(24.56, 1, $MeltPoint)#T in K, P in bars
	place(27.1, 1, $BoilPoint)
	place(24.556, 0.4337, $TriplePoint)
	place(44.4918, 27.686, $SuperPoint)

var colors = {	"S":Color(1.0, 0.55, 0.45, 0.8),
				"L":Color(1.0, 0.48, 0.38, 1.0),
				"SC":Color(1.0, 0.43, 0.35, 0.4)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
