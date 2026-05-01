extends Control

@export var score: int = 0

func mod_score(diff: int):
	score += diff
	$CanvasLayer/Label.text = "Score: " + str(score)
