extends "PhaseDiagram.gd"

func _ready():
	place(1, 1, $MeltPoint)
	place(4.222, 1, $BoilPoint)
	place(2.177, 0.05, $TriplePoint)
	place(5.1953, 2.27, $SuperPoint)
