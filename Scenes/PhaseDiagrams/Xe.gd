extends "PhaseDiagram.gd"

func _ready():
	place(161.4, 1, $MeltPoint)#T in K, P in bars
	place(165.051, 1, $BoilPoint)
	place(161.405, 0.8177, $TriplePoint)
	place(289.733, 58.42, $SuperPoint)
