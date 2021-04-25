class_name CaveBoss
extends KinematicBody2D

func _ready():
	$AnimationTree.active = true
	$AnimationPlayer.play("IdleArms")

func hit(dmg:int):
	print(dmg)
