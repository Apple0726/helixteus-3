extends Node2D

func _ready():
	place(161.4, 1, $MeltPoint)#T in K, P in bars
	place(165.051, 1, $BoilPoint)
	place(161.405, 0.8177, $TriplePoint)
	place(289.733, 58.42, $SuperPoint)

var colors = {	"S":Color(0.8, 0.68, 1.00, 0.7),
				"L":Color(0.67, 0.49, 1.0, 1.0),
				"SC":Color(0.8, 0.68, 1.00, 0.4)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
