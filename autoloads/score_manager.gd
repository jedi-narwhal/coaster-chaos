extends Node

var high_score: int = 0
var score: int = 0

signal score_changed(score)

func mod_score(diff: int) -> void:
	score += diff
	score_changed.emit(score)

func reset_score() -> void:
	score = 0
