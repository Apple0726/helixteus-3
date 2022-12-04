extends "PhaseDiagram.gd"

func _ready():
	place(195, 1, $MeltPoint)
	place(240, 1, $BoilPoint)
	place(195, 0.06, $TriplePoint)
	place(406, 111, $SuperPoint)
