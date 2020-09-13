extends Node2D

func _ready():
	place(195, 1, $MeltPoint)
	place(240, 1, $BoilPoint)
	place(195, 0.06, $TriplePoint)
	place(406, 111, $SuperPoint)

var colors = {	"S":Color(1.0, 1.0, 1.0, 0.3),
				"L":Color(1.0, 1.0, 1.0, 1.0),
				"SF":Color(1.0, 1.0, 1.0, 0.2)}

func place(T:float, P:float, node):
	var v = Vector2(T / 1000.0 * 1109, -floor(log(P) / log(10)) * 576 / 12.0 + 290)
	node.position = v
