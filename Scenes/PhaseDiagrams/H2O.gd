extends "PhaseDiagram.gd"

func _ready():
	place(273, 1, $MeltPoint)
	place(373, 1, $BoilPoint)
	place(273, 0.00612, $TriplePoint)
	place(647, 221, $SuperPoint)
