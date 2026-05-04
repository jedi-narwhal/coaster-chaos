extends Node

var score: int = 0

signal score_changed(score)

func mod_score(diff: int):
	score += diff
	score_changed.emit(score)
