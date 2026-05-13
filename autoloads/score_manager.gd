extends Node

signal score_changed(score)

var high_score: int = 0
var score: int = 0


func mod_score(diff: int) -> void:
	score += diff
	score_changed.emit(score)


func reset_score() -> void:
	score = 0


func update_high_score() -> void:
	high_score = max(high_score, score)
